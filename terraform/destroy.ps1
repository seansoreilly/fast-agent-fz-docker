# Destruction script for Fast Agent FZ
# This script will:
# 1. Run Terraform destroy to remove all AWS resources
# 2. Optionally remove Docker images and other artifacts

param(
    [Parameter(Mandatory = $false)]
    [string]$ECRPublicAlias = "",
    [string]$EnvironmentName = "dev",
    [string]$Region = "us-east-1",
    [string]$RepoName = "fast-agent-fz",
    [switch]$Force = $false,
    [switch]$RemoveImages = $false
)

Set-Location 'C:\projects\fast-agent-fz-docker\terraform'

$ErrorActionPreference = "Stop"

function Test-CommandExists {
    param ($command)
    try { Get-Command $command -ErrorAction Stop | Out-Null; return $true } catch { return $false }
}

function Test-RequiredTools {
    if (-not (Test-CommandExists "terraform")) {
        throw "terraform is not installed. Please install it before running this script."
    }
    
    if ($RemoveImages -and -not (Test-CommandExists "aws")) {
        throw "aws CLI is not installed. Required when using -RemoveImages flag."
    }
}

function Get-Or-CreateECRAlias {
    if (-not [string]::IsNullOrWhiteSpace($ECRPublicAlias)) { return $ECRPublicAlias }

    Write-Host "ECR Public Alias not provided. Attempting to fetch..." -ForegroundColor Cyan
    $repos = aws ecr-public describe-repositories --region $Region --no-paginate | ConvertFrom-Json

    if ($repos.repositories.Count -gt 0) {
        $repoUri = $repos.repositories[0].repositoryUri
        $uriParts = $repoUri -split "/"
        if ($uriParts.Length -ge 2) {
            $alias = $uriParts[1]
            Write-Host "Using ECR Public Alias: $alias" -ForegroundColor Green
            return $alias
        }
    }
    
    Write-Host "No ECR repositories found. If you proceed, only Terraform resources will be destroyed." -ForegroundColor Yellow
    return ""
}

function Get-TerraformOutputs {
    $outputs = @{}
    
    try {
        $outputs["EcrUri"] = ./terraform.exe output -raw ecr_public_repository_uri 2>$null
        $outputs["ClusterName"] = ./terraform.exe output -raw ecs_cluster_name 2>$null
        $outputs["ServiceName"] = ./terraform.exe output -raw ecs_service_name 2>$null
        $outputs["LoadBalancer"] = ./terraform.exe output -raw load_balancer_dns_name 2>$null
    }
    catch {
        Write-Host "Could not retrieve all Terraform outputs. This is normal if Terraform hasn't been applied yet." -ForegroundColor Yellow
    }
    
    return $outputs
}

function Remove-DockerImages {
    param($ecrUri)
    
    if ([string]::IsNullOrWhiteSpace($ecrUri)) {
        Write-Host "No ECR URI available. Skipping image removal." -ForegroundColor Yellow
        return
    }
    
    Write-Host ""; Write-Host "==== REMOVING DOCKER IMAGES FROM ECR ===="
    try {
        # Use the correct repository name format with environment
        $fullRepoName = "$EnvironmentName-$RepoName"
        Write-Host "Looking for images in repository: $fullRepoName" -ForegroundColor Cyan
        
        $images = aws ecr-public describe-images --repository-name $fullRepoName --region $Region --no-paginate 2>$null | ConvertFrom-Json
        
        if ($null -eq $images -or $images.imageDetails.Count -eq 0) {
            Write-Host "No images found in the ECR repository." -ForegroundColor Yellow
            # Force remove all images as a fallback
            Write-Host "Attempting to force delete all images..." -ForegroundColor Yellow
            aws ecr-public batch-delete-image --repository-name $fullRepoName --image-ids imageTag=latest --region $Region 2>$null
            return
        }
        
        Write-Host "Found $($images.imageDetails.Count) images in the ECR repository."
        foreach ($image in $images.imageDetails) {
            $tag = if ($image.imageTags) { $image.imageTags[0] } else { "<untagged>" }
            $digest = $image.imageDigest
            Write-Host "Removing image: $tag ($digest)" -ForegroundColor Yellow
            aws ecr-public batch-delete-image --repository-name $fullRepoName --image-ids imageDigest=$digest --region $Region | Out-Null
        }
        
        Write-Host "All images removed successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "Error removing Docker images: $_" -ForegroundColor Red
        Write-Host "Attempting to force delete all images..." -ForegroundColor Yellow
        $fullRepoName = "$EnvironmentName-$RepoName"
        
        # Try with both imageTag=latest and imageTag=*
        try {
            aws ecr-public batch-delete-image --repository-name $fullRepoName --image-ids imageTag=latest --region $Region 2>$null
            aws ecr-public batch-delete-image --repository-name $fullRepoName --image-ids imageTag=* --region $Region 2>$null
        }
        catch {
            Write-Host "Force delete failed: $_" -ForegroundColor Red
        }
    }
}

function Start-TerraformDestroy {
    Write-Host ""; Write-Host "==== RUNNING TERRAFORM DESTROY ===="
    ./terraform.exe init
    
    if ($Force) {
        ./terraform.exe destroy -auto-approve `
            -var="ecr_public_alias=$ECRPublicAlias" `
            -var="environment_name=$EnvironmentName"
    }
    else {
        ./terraform.exe destroy `
            -var="ecr_public_alias=$ECRPublicAlias" `
            -var="environment_name=$EnvironmentName"
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Terraform destroy successful." -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "Terraform destroy failed with exit code $LASTEXITCODE." -ForegroundColor Red
        return $false
    }
}

function Confirm-Destruction {
    if ($Force) { return $true }
    
    Write-Host ""
    Write-Host "WARNING: This will destroy all resources managed by Terraform in the $EnvironmentName environment." -ForegroundColor Red
    Write-Host "This action cannot be undone and will result in service downtime." -ForegroundColor Red
    Write-Host ""
    
    $confirmation = Read-Host "Type 'destroy' to confirm destruction"
    return $confirmation -eq "destroy"
}

# Main Execution
Write-Host "Fast Agent FZ Destruction Script" -ForegroundColor Cyan
Test-RequiredTools

$ECRPublicAlias = Get-Or-CreateECRAlias
$outputs = Get-TerraformOutputs

if (Confirm-Destruction) {
    # Always remove images if ECR exists to prevent deletion errors
    if (-not [string]::IsNullOrWhiteSpace($outputs["EcrUri"])) {
        Write-Host "ECR repository contains images. Removing images first..." -ForegroundColor Yellow
        Remove-DockerImages -ecrUri $outputs["EcrUri"]
    }
    elseif ($RemoveImages) {
        # Fallback if we couldn't get the ECR URI from outputs but user requested image removal
        Remove-DockerImages -ecrUri ""
    }
    
    $destroyed = Start-TerraformDestroy
    
    if ($destroyed) {
        Write-Host ""; Write-Host "==== DESTRUCTION COMPLETE ===="
        Write-Host "All resources in the $EnvironmentName environment have been destroyed." -ForegroundColor Green
    }
    else {
        Write-Host ""; Write-Host "==== DESTRUCTION INCOMPLETE ===="
        Write-Host "There were errors during the destruction process. Some resources may still exist." -ForegroundColor Yellow
        Write-Host "Review the Terraform output above for details." -ForegroundColor Yellow
    }
}
else {
    Write-Host "Destruction cancelled by user." -ForegroundColor Yellow
} 