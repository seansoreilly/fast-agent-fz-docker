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
    [string]$RepoName = "fast-agent-fz" # Default repository name
)

# Set error action preference to stop on any error
$ErrorActionPreference = "Stop"

# If ECRPublicAlias not provided, fetch it using AWS CLI
if ([string]::IsNullOrWhiteSpace($ECRPublicAlias)) {
    Write-Host "ECR Public Alias not provided. Attempting to fetch using AWS CLI..." -ForegroundColor Cyan
    try {
        # First, try to find any existing repositories
        $repos = aws ecr-public describe-repositories --region $Region --no-paginate | ConvertFrom-Json
        
        if ($repos.repositories.Count -gt 0) {
            # Get the repository URI from the first repository
            $repoUri = $repos.repositories[0].repositoryUri
            
            # Extract the alias from the URI in this format: public.ecr.aws/j8s1t0g8/dev-fast-agent-fz
            # We want the second part (index 1) after splitting by "/"
            $uriParts = $repoUri -split "/"
            if ($uriParts.Length -ge 2) {
                $ECRPublicAlias = $uriParts[1]
                Write-Host "Found ECR Public Alias: $ECRPublicAlias" -ForegroundColor Green
                Write-Host "Full repository URI: $repoUri" -ForegroundColor Cyan
            }
            else {
                Write-Error "Invalid repository URI format: $repoUri"
                exit 1
            }
        }
        else {
            # No repositories found, try to create one
            Write-Host "No ECR repositories found. Creating new repository '$RepoName'..." -ForegroundColor Yellow
            $newRepo = aws ecr-public create-repository --repository-name $RepoName --region $Region --no-paginate | ConvertFrom-Json
            $repoUri = $newRepo.repository.repositoryUri
            
            # Extract the alias from the URI in this format: public.ecr.aws/j8s1t0g8/dev-fast-agent-fz
            $uriParts = $repoUri -split "/"
            if ($uriParts.Length -ge 2) {
                $ECRPublicAlias = $uriParts[1]
                Write-Host "Created new ECR Public repository with URI: $repoUri" -ForegroundColor Green
                Write-Host "Extracted alias: $ECRPublicAlias" -ForegroundColor Green
            }
            else {
                Write-Error "Invalid repository URI format: $repoUri"
                exit 1
            }
        }
    }
    catch {
        Write-Error "Failed to get or create ECR Public repository: $_"
        Write-Host "Please provide the ECR Public Alias manually using the -ECRPublicAlias parameter." -ForegroundColor Yellow
        exit 1
    }
}

# Function to check if a command exists
function Test-CommandExists {
    param ($command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    try {
        if (Get-Command $command) { return $true }
    }
    catch { return $false }
    finally { $ErrorActionPreference = $oldPreference }
}

# Verify required tools
if (-not (Test-CommandExists "aws")) {
    Write-Error "AWS CLI is not installed. Please install it before running this script."
    exit 1
}

if (-not (Test-CommandExists "docker")) {
    Write-Error "Docker is not installed. Please install it before running this script."
    exit 1
}

# 1. Apply Terraform
Write-Host "==== APPLYING TERRAFORM ===="
Write-Host "Using ECR Public Alias: $ECRPublicAlias"

try {
    ./terraform.exe init
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Terraform init failed."
        exit 1
    }

    ./terraform.exe apply -auto-approve `
        -var="ecr_public_alias=$ECRPublicAlias" `
        -var="environment_name=$EnvironmentName" `
        -var="image_tag=$ImageTag"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Terraform apply failed."
        exit 1
    }

    Write-Host "Terraform apply successful." -ForegroundColor Green
}
catch {
    Write-Error "Error during Terraform operation: $_"
    exit 1
}

# 2. Get outputs from Terraform
try {
    $ecrUri = ./terraform.exe output -raw ecr_public_repository_uri
    $clusterName = ./terraform.exe output -raw ecs_cluster_name
    $serviceName = ./terraform.exe output -raw ecs_service_name
    $loadBalancerDns = ./terraform.exe output -raw load_balancer_dns_name

    Write-Host "ECR URI: $ecrUri"
    Write-Host "ECS Cluster: $clusterName"
    Write-Host "ECS Service: $serviceName"
    Write-Host "Load Balancer DNS: $loadBalancerDns"
}
catch {
    Write-Error "Error retrieving Terraform outputs: $_"
    exit 1
}

# 3. Build and push Docker image
Write-Host "`n==== BUILDING AND PUSHING DOCKER IMAGE ===="

# Move to the root directory where Dockerfile is located
Push-Location ..

try {
    # Authenticate with ECR Public
    Write-Host "Authenticating with ECR Public..."
    aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ECR authentication failed."
        exit 1
    }

    # Build Docker image
    Write-Host "Building Docker image..."
    docker build -t "${ecrUri}:${ImageTag}" .
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker build failed."
        exit 1
    }

    # Push Docker image
    Write-Host "Pushing Docker image to ECR..."
    docker push "${ecrUri}:${ImageTag}"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker push failed."
        exit 1
    }

    Write-Host "Docker image successfully built and pushed to ECR." -ForegroundColor Green
}
catch {
    Write-Error "Error during Docker operations: $_"
    exit 1
}
finally {
    # Return to the terraform directory
    Pop-Location
}

# 4. Update ECS service to force new deployment
Write-Host "`n==== UPDATING ECS SERVICE ===="

try {
    Write-Host "Forcing new deployment of ECS service..."
    aws ecs update-service --cluster $clusterName --service $serviceName --force-new-deployment --region $Region | Out-Host

    if ($LASTEXITCODE -ne 0) {
        Write-Error "ECS service update failed."
        exit 1
    }

    Write-Host "ECS service update initiated." -ForegroundColor Green
}
catch {
    Write-Error "Error updating ECS service: $_"
    exit 1
}

# 5. Wait for service to stabilize
Write-Host "`n==== WAITING FOR SERVICE TO STABILIZE ===="

try {
    Write-Host "Waiting for ECS service to reach steady state..."
    aws ecs wait services-stable --cluster $clusterName --services $serviceName --region $Region
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ECS service did not reach steady state."
        exit 1
    }

    Write-Host "ECS service is now stable." -ForegroundColor Green
}
catch {
    Write-Error "Error waiting for ECS service: $_"
    exit 1
}

# 5.1. Ensure at least one task is running
Write-Host "`n==== ENSURING AT LEAST ONE TASK IS RUNNING ===="

try {
    # Check current task count
    $serviceDetails = aws ecs describe-services --cluster $clusterName --services $serviceName --region $Region --no-paginate | ConvertFrom-Json
    $runningCount = $serviceDetails.services[0].runningCount
    $desiredCount = $serviceDetails.services[0].desiredCount
    
    Write-Host "Current task status: $runningCount running / $desiredCount desired"
    
    # If no tasks are running, set desired count to 1
    if ($runningCount -eq 0) {
        Write-Host "No running tasks detected. Setting desired count to 1..." -ForegroundColor Yellow
        
        # Update the desired count to 1
        aws ecs update-service --cluster $clusterName --service $serviceName --desired-count 1 --region $Region | Out-Host
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to update desired task count."
            exit 1
        }
        
        Write-Host "Waiting for the task to start..."
        
        # Wait for service to stabilize again
        aws ecs wait services-stable --cluster $clusterName --services $serviceName --region $Region
        if ($LASTEXITCODE -ne 0) {
            Write-Error "ECS service did not reach steady state after updating desired count."
            exit 1
        }
        
        # Verify that tasks are now running
        $serviceDetails = aws ecs describe-services --cluster $clusterName --services $serviceName --region $Region --no-paginate | ConvertFrom-Json
        $runningCount = $serviceDetails.services[0].runningCount
        
        if ($runningCount -gt 0) {
            Write-Host "Successfully started task. Current running tasks: $runningCount" -ForegroundColor Green
        }
        else {
            Write-Host "WARNING: Still no running tasks. Check the ECS task logs for errors." -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "Task already running ($runningCount tasks). No action needed." -ForegroundColor Green
    }
}
catch {
    Write-Error "Error ensuring minimum task count: $_"
    exit 1
}

# 6. Display service and application info
Write-Host "`n==== DEPLOYMENT COMPLETE ===="
Write-Host "Your application is now running and should be accessible at:"
Write-Host "http://$loadBalancerDns" -ForegroundColor Cyan

# Check if tasks are running
try {
    $serviceDetails = aws ecs describe-services --cluster $clusterName --services $serviceName --region $Region --no-paginate | ConvertFrom-Json
    $runningCount = $serviceDetails.services[0].runningCount
    $desiredCount = $serviceDetails.services[0].desiredCount
    
    Write-Host "`nService status:"
    Write-Host "Running tasks: $runningCount / $desiredCount"
    
    if ($runningCount -eq 0) {
        Write-Host "`nWARNING: No running tasks detected. Check ECS task logs for errors:" -ForegroundColor Yellow
        Write-Host "aws ecs describe-services --cluster $clusterName --services $serviceName --region $Region --no-paginate" -ForegroundColor Yellow
        Write-Host "aws logs get-log-events --log-group-name /ecs/$EnvironmentName-fast-agent-fz --region $Region" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Error checking service status: $_" -ForegroundColor Yellow
}

Write-Host "`nTo check the status of your service:"
Write-Host "aws ecs describe-services --cluster $clusterName --services $serviceName --region $Region --no-paginate" -ForegroundColor DarkGray