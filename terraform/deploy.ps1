# Integrated deployment script for Fast Agent FZ
# This script will:
# 1. Apply Terraform
# 2. Build and push Docker image to ECR
# 3. Update ECS service
# 4. Wait for service to be available
# 5. Display the load balancer URL

param(
    [Parameter(Mandatory = $false)]
    [string]$ECRPublicAlias = "",
    [string]$EnvironmentName = "dev",
    [string]$ImageTag = "latest",
    [string]$Region = "us-east-1",
    [string]$RepoName = "$EnvironmentName-fast-agent-fz",
    [string]$LocalImageName = "fast-agent-fz-docker-fast-agent-fz",
    [switch]$SkipTerraformApply,
    [switch]$SkipWaitStable
)

Set-Location 'C:\projects\fast-agent-fz-docker\terraform'

$ErrorActionPreference = "Stop"

function Test-CommandExists {
    param ($command)
    try { Get-Command $command -ErrorAction Stop | Out-Null; return $true } catch { return $false }
}

function Get-Or-CreateECRAlias {
    if (-not [string]::IsNullOrWhiteSpace($ECRPublicAlias)) { return $ECRPublicAlias }

    Write-Host "ECR Public Alias not provided. Attempting to fetch or create..." -ForegroundColor Cyan
    $repos = aws ecr-public describe-repositories --region $Region --no-paginate | ConvertFrom-Json

    if ($repos.repositories.Count -gt 0) {
        $repoUri = $repos.repositories[0].repositoryUri
    }
    else {
        Write-Host "No ECR repositories found. Creating new repository '$RepoName'..." -ForegroundColor Yellow
        $newRepo = aws ecr-public create-repository --repository-name $RepoName --region $Region --no-paginate | ConvertFrom-Json
        $repoUri = $newRepo.repository.repositoryUri
    }

    $uriParts = $repoUri -split "/"
    if ($uriParts.Length -ge 2) {
        $alias = $uriParts[1]
        Write-Host "Using ECR Public Alias: $alias" -ForegroundColor Green
        return $alias
    }
    else {
        throw "Invalid repository URI format: $repoUri"
    }
}

function Test-RequiredTools {
    foreach ($tool in @("aws", "docker")) {
        if (-not (Test-CommandExists $tool)) {
            throw "$tool is not installed. Please install it before running this script."
        }
    }
}

function Start-TerraformApply {
    Write-Host "==== APPLYING TERRAFORM ===="
    ./terraform.exe init
    
    # Read API keys from .env file if they exist
    $envPath = "../.env"
    if (Test-Path $envPath) {
        Get-Content $envPath | ForEach-Object {
            if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()
                if ($key -eq "ANTHROPIC_API_KEY" -or $key -eq "OPENAI_API_KEY") {
                    Write-Host "Found $key in .env file"
                    Set-Variable -Name $key -Value $value
                }
            }
        }
    }

    # If environment variables are not set in .env, try to get them from system environment
    if (-not $ANTHROPIC_API_KEY) { $ANTHROPIC_API_KEY = $env:ANTHROPIC_API_KEY }
    if (-not $OPENAI_API_KEY) { $OPENAI_API_KEY = $env:OPENAI_API_KEY }

    Write-Host "API Keys status - ANTHROPIC: $($ANTHROPIC_API_KEY.Length -gt 0) - OPENAI: $($OPENAI_API_KEY.Length -gt 0)"

    ./terraform.exe apply -auto-approve `
        -var="ecr_public_alias=$ECRPublicAlias" `
        -var="environment_name=$EnvironmentName" `
        -var="image_tag=$ImageTag" `
        -var="anthropic_api_key=$ANTHROPIC_API_KEY" `
        -var="openai_api_key=$OPENAI_API_KEY"
    
    Write-Host "Terraform apply successful." -ForegroundColor Green
}

function Get-TerraformOutputs {
    return [PSCustomObject]@{
        EcrUri       = ./terraform.exe output -raw ecr_public_repository_uri
        ClusterName  = ./terraform.exe output -raw ecs_cluster_name
        ServiceName  = ./terraform.exe output -raw ecs_service_name
        LoadBalancer = ./terraform.exe output -raw load_balancer_dns_name
    }
}

function New-DockerImage {
    param($ecrUri)
    Write-Host ""; Write-Host "==== TAGGING AND PUSHING LOCALLY BUILT DOCKER IMAGE ====" -ForegroundColor Cyan
    Push-Location ..  # moving to project root
    try {
        # Check if the local image exists
        $imageExists = docker images --format "{{.Repository}}" | Select-String -Pattern "^$LocalImageName$"
        
        if (-not $imageExists) {
            Write-Host "Local image '$LocalImageName' not found. Attempting to build it with docker-compose..." -ForegroundColor Yellow
            try {
                Write-Host "Running docker-compose up -d --build"
                docker-compose up -d --build
                Start-Sleep -Seconds 5  # Wait a bit for the image to be available
                $imageExists = docker images --format "{{.Repository}}" | Select-String -Pattern "^$LocalImageName$"
                
                if (-not $imageExists) {
                    throw "Failed to build local image with docker-compose."
                }
            }
            catch {
                Write-Host "Error building image with docker-compose: $_" -ForegroundColor Red
                throw "Local image not found and auto-build failed. Run docker-compose up first to build the local image."
            }
        }
        
        Write-Host "Using locally built image: $LocalImageName" -ForegroundColor Green
        docker tag "${LocalImageName}:latest" "${ecrUri}:${ImageTag}"
        aws ecr-public get-login-password --region $Region | docker login --username AWS --password-stdin public.ecr.aws
        docker push "${ecrUri}:${ImageTag}"
        Write-Host "Docker image pushed to ${ecrUri}:${ImageTag}" -ForegroundColor Green
    }
    finally {
        Pop-Location
    }
}

function Update-ECSService {
    param($clusterName, $serviceName)
    Write-Host ""; Write-Host "==== UPDATING ECS SERVICE ===="
    aws ecs update-service --cluster $clusterName --service $serviceName --force-new-deployment --region $Region | Out-Host
    Write-Host "ECS service update initiated." -ForegroundColor Green
}

function Test-ServiceStability {
    param($clusterName, $serviceName)
    Write-Host ""; Write-Host "==== WAITING FOR SERVICE TO STABILIZE ===="
    aws ecs wait services-stable --cluster $clusterName --services $serviceName --region $Region
    Write-Host "ECS service is now stable." -ForegroundColor Green
}

function Test-RunningTask {
    param($clusterName, $serviceName)
    Write-Host ""; Write-Host "==== ENSURING AT LEAST ONE TASK IS RUNNING ===="
    $details = aws ecs describe-services --cluster $clusterName --services $serviceName --region $Region | ConvertFrom-Json
    $running = $details.services[0].runningCount
    $desired = $details.services[0].desiredCount
    Write-Host "Current task status: $running running / $desired desired"

    if ($running -eq 0) {
        aws ecs update-service --cluster $clusterName --service $serviceName --desired-count 1 --region $Region | Out-Host
        aws ecs wait services-stable --cluster $clusterName --services $serviceName --region $Region
        $details = aws ecs describe-services --cluster $clusterName --services $serviceName --region $Region | ConvertFrom-Json
        $running = $details.services[0].runningCount
        if ($running -gt 0) {
            Write-Host "Successfully started task." -ForegroundColor Green
        }
        else {
            Write-Host "WARNING: Still no running tasks." -ForegroundColor Yellow
        }
    }
}

function Write-DeploymentSummary {
    param($loadBalancerDns, $clusterName, $serviceName)
    Write-Host ""; Write-Host "==== DEPLOYMENT COMPLETE ===="
    Write-Host "Your application is now running and should be accessible at:"
    Write-Host "http://$loadBalancerDns" -ForegroundColor Cyan
    Write-Host ""; Write-Host "Note: If you encounter a 502 Bad Gateway error, the health check has been configured to accept 307 redirects." -ForegroundColor Yellow
    $status = aws ecs describe-services --cluster $clusterName --services $serviceName --region $Region | ConvertFrom-Json
    $running = $status.services[0].runningCount
    $desired = $status.services[0].desiredCount
    Write-Host ""; Write-Host "Service status: Running tasks: $running / $desired"

    if ($running -eq 0) {
        Write-Host ""; Write-Host "WARNING: No running tasks detected. Check ECS task logs for errors." -ForegroundColor Yellow
        Write-Host "aws ecs describe-services --cluster $clusterName --services $serviceName --region $Region --no-paginate" -ForegroundColor Yellow
        Write-Host "aws logs get-log-events --log-group-name /ecs/$EnvironmentName-fast-agent-fz --region $Region" -ForegroundColor Yellow
    }

    Write-Host ""; Write-Host "To check the status of your service:" -ForegroundColor Gray
    Write-Host "aws ecs describe-services --cluster $clusterName --services $serviceName --region $Region --no-paginate" -ForegroundColor Gray
}

# Main Execution
& ../setup.ps1 # Run setup script first
Test-RequiredTools
$ECRPublicAlias = Get-Or-CreateECRAlias

if (-not $SkipTerraformApply) {
    Start-TerraformApply
}
else {
    Write-Host "==== SKIPPING TERRAFORM APPLY ====" -ForegroundColor Yellow
}

$outputs = Get-TerraformOutputs
New-DockerImage -ecrUri $outputs.EcrUri
Update-ECSService -clusterName $outputs.ClusterName -serviceName $outputs.ServiceName

if (-not $SkipWaitStable) {
    Test-ServiceStability -clusterName $outputs.ClusterName -serviceName $outputs.ServiceName
    Test-RunningTask -clusterName $outputs.ClusterName -serviceName $outputs.ServiceName
}
else {
    Write-Host "==== SKIPPING SERVICE STABILITY WAIT ====" -ForegroundColor Yellow
}

Write-DeploymentSummary -loadBalancerDns $outputs.LoadBalancer -clusterName $outputs.ClusterName -serviceName $outputs.ServiceName
