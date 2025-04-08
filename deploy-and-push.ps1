# Script parameters
param(
    [string]$EnvironmentName = "dev",
    [string]$ImageTag = "latest",
    [string]$StackName = "fast-agent-fz-ecr",
    [string]$Region = "us-east-1", # ECR Public is only available in us-east-1
    [Parameter(Mandatory=$true)]
    [string]$ECRPublicAlias = "j8s1t0g8", # This is your ECR Public registry alias (e.g., "a1b2c3d4")
    [switch]$ForceDelete = $false
)

# Set error action preference to stop on any error
$ErrorActionPreference = "Stop"

# Check if stack exists and needs to be deleted
Write-Host "[CHECK] Checking if stack exists and its status..."
$stackNeedsDelete = $false

try {
    $stackInfo = aws cloudformation describe-stacks --stack-name $StackName --region $Region --output json | ConvertFrom-Json
    $stackStatus = $stackInfo.Stacks[0].StackStatus
    
    Write-Host "[INFO] Stack '$StackName' exists with status: $stackStatus"
    
    if ($stackStatus -eq "ROLLBACK_COMPLETE" -or $stackStatus -eq "CREATE_FAILED" -or $stackStatus -eq "UPDATE_ROLLBACK_COMPLETE") {
        $stackNeedsDelete = $true
        Write-Host "[WARN] Stack is in $stackStatus state and needs to be deleted before creating a new one."
        
        if ($ForceDelete -or (Read-Host "Do you want to delete and recreate the stack? (y/n)") -eq 'y') {
            Write-Host "[DELETE] Deleting stack '$StackName'..."
            aws cloudformation delete-stack --stack-name $StackName --region $Region
            
            Write-Host "[WAIT] Waiting for stack deletion to complete..."
            aws cloudformation wait stack-delete-complete --stack-name $StackName --region $Region
            
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Failed to delete stack '$StackName'"
                exit 1
            }
            
            Write-Host "[INFO] Stack successfully deleted."
        } else {
            Write-Host "[EXIT] Operation cancelled by user."
            exit 0
        }
    }
} catch {
    # Stack doesn't exist, which is fine
    Write-Host "[INFO] Stack '$StackName' does not exist. It will be created."
}

# Deploy CloudFormation stack
Write-Host "[DEPLOY] Deploying CloudFormation stack..."
aws cloudformation deploy `
    --template-file ecr-template.yaml `
    --stack-name $StackName `
    --parameter-overrides `
        EnvironmentName=$EnvironmentName `
        ImageTag=$ImageTag `
        ECRPublicAlias=$ECRPublicAlias `
    --capabilities CAPABILITY_IAM `
    --region $Region

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to deploy CloudFormation stack"
    exit 1
}

# Get stack outputs
Write-Host "[INFO] Getting stack outputs..."
$stackOutput = aws cloudformation describe-stacks --stack-name $StackName --region $Region --output json
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to get stack outputs"
    exit 1
}

$outputs = $stackOutput | ConvertFrom-Json
$repoName = ($outputs.Stacks[0].Outputs | Where-Object { $_.OutputKey -eq "ECRPublicRepositoryName" }).OutputValue
$repoUri = ($outputs.Stacks[0].Outputs | Where-Object { $_.OutputKey -eq "ECRPublicRepositoryURI" }).OutputValue

if (-not $repoUri) {
    Write-Error "Failed to get ECR repository URI from stack outputs"
    exit 1
}

Write-Host "[INFO] Using repository URI: $repoUri"
Write-Host "[INFO] Using repository name: $repoName"

# Build and push Docker image
Write-Host "[BUILD] Building Docker image..."
docker build -t "${repoUri}:${ImageTag}" .
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to build Docker image"
    exit 1
}

Write-Host "[AUTH] Getting ECR Public login password..."
$ecrPassword = aws ecr-public get-login-password --region us-east-1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to get ECR Public password"
    exit 1
}

Write-Host "[AUTH] Logging into Amazon ECR Public..."
aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to authenticate with ECR"
    exit 1
}

Write-Host "[PUSH] Pushing image to ECR Public..."
docker push "${repoUri}:${ImageTag}"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to push Docker image"
    exit 1
}

Write-Host "[DONE] Complete! Image URI: ${repoUri}:${ImageTag}" 