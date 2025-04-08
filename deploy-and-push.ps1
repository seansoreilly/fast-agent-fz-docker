# Script parameters
param(
    [string]$EnvironmentName = "dev",
    [string]$ImageTag = "latest",
    [string]$StackName = "fast-agent-fz-ecs-2",
    [string]$Region = "us-east-1", # ECR Public is only available in us-east-1
    [Parameter(Mandatory=$true)]
    [string]$ECRPublicAlias, # Your ECR Public registry alias (e.g., "a1b2c3d4")
    [string]$VpcId = "", # Optional: Specify VPC ID. Defaults to Default VPC in the template.
    [string[]]$SubnetIds = @(), # Optional: Specify Subnet IDs. Defaults to Default Subnets in the template.
    [switch]$ForceDelete = $true # Set to true to force deletion without prompt
)

# Set error action preference to stop on any error
$ErrorActionPreference = "Stop"

# Ensure VPC has Internet Gateway if VpcId is specified
if ($VpcId) {
    Write-Host "[CHECK] Checking Internet Gateway for VPC $VpcId..."
    $igws = aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values=$VpcId --query 'InternetGateways[*].InternetGatewayId' --output text
    if (-not $igws) {
        Write-Host "[CREATE] Creating Internet Gateway..."
        $newIgwId = aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text
        Write-Host "[ATTACH] Attaching Internet Gateway $newIgwId to VPC $VpcId..."
        aws ec2 attach-internet-gateway --internet-gateway-id $newIgwId --vpc-id $VpcId

        Write-Host "[ROUTE] Adding route to route tables in VPC $VpcId..."
        $routeTables = aws ec2 describe-route-tables --filters Name=vpc-id,Values=$VpcId --query 'RouteTables[*].RouteTableId' --output text
        foreach ($rtb in $routeTables) {
            aws ec2 create-route --route-table-id $rtb --destination-cidr-block 0.0.0.0/0 --gateway-id $newIgwId | Out-Null
        }
        Write-Host "[DONE] Internet access enabled for VPC $VpcId."
    } else {
        Write-Host "[INFO] VPC already has Internet Gateway(s): $igws"
    }
}

# Function to check if a stack exists
function Get-StackStatus {
    param($StackName, $Region)
    try {
        $stackInfo = aws cloudformation describe-stacks --stack-name $StackName --region $Region --output json | ConvertFrom-Json
        return $stackInfo.Stacks[0].StackStatus
    } catch {
        return $null
    }
}

# Function to delete a stack
function Remove-Stack {
    param($StackName, $Region)
    aws cloudformation delete-stack --stack-name $StackName --region $Region
    Write-Host "[WAIT] Waiting for stack deletion to complete..."
    aws cloudformation wait stack-delete-complete --stack-name $StackName --region $Region
}

# Check if stack exists and its status
Write-Host "[CHECK] Checking if stack '$StackName' exists..."
$stackStatus = Get-StackStatus -StackName $StackName -Region $Region

if ($stackStatus) {
    Write-Host "[INFO] Stack '$StackName' exists with status: $stackStatus"
    if ($stackStatus -in @("ROLLBACK_COMPLETE", "CREATE_FAILED", "UPDATE_ROLLBACK_COMPLETE")) {
        Write-Host "[WARN] Stack is in $stackStatus state and needs to be deleted before creating a new one."
        if ($ForceDelete) {
            Remove-Stack -StackName $StackName -Region $Region
            Write-Host "[INFO] Stack successfully deleted."
        } else {
            Write-Host "[EXIT] Operation cancelled."
            exit 0
        }
    }
} else {
    Write-Host "[INFO] Stack '$StackName' does not exist. It will be created."
}

# Deploy CloudFormation stack
Write-Host "[DEPLOY] Deploying CloudFormation stack..."
$ParameterOverrides = @(
    "EnvironmentName=$EnvironmentName",
    "ImageTag=$ImageTag",
    "ECRPublicAlias=$ECRPublicAlias"
)
if ($VpcId) { $ParameterOverrides += "VpcId=$VpcId" }
if ($SubnetIds) { $ParameterOverrides += "SubnetIds=$($SubnetIds -join ',')" }

aws cloudformation deploy `
    --template-file ecr-template.yaml `
    --stack-name $StackName `
    --parameter-overrides $ParameterOverrides `
    --capabilities CAPABILITY_IAM `
    --region $Region

# Get stack outputs
Write-Host "[INFO] Retrieving stack outputs..."
$stackOutput = aws cloudformation describe-stacks --stack-name $StackName --region $Region --output json | ConvertFrom-Json
$outputs = $stackOutput.Stacks[0].Outputs
$repoName = ($outputs | Where-Object { $_.OutputKey -eq "ECRPublicRepositoryName" }).OutputValue
$repoUri = ($outputs | Where-Object { $_.OutputKey -eq "ECRPublicRepositoryURI" }).OutputValue
$loadBalancerDnsName = ($outputs | Where-Object { $_.OutputKey -eq "LoadBalancerDNSName" }).OutputValue

if (-not $repoUri) {
    Write-Error "Failed to retrieve ECR repository URI from stack outputs."
    exit 1
}

Write-Host "[INFO] Repository URI: $repoUri"
Write-Host "[INFO] Repository Name: $repoName"
if ($loadBalancerDnsName) {
    Write-Host "[INFO] Load Balancer DNS Name: http://$loadBalancerDnsName"
} else {
    Write-Warning "Load Balancer DNS Name not available. It might still be provisioning."
}

# Build and push Docker image
Write-Host "[BUILD] Building Docker image..."
docker build -t "${repoUri}:${ImageTag}" .
if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker build failed."
    exit 1
}

Write-Host "[AUTH] Authenticating with Amazon ECR Public..."
aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws
if ($LASTEXITCODE -ne 0) {
    Write-Error "ECR authentication failed."
    exit 1
}

Write-Host "[PUSH] Pushing image to ECR Public..."
docker push "${repoUri}:${ImageTag}"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to push Docker image."
    exit 1
}

Write-Host "[DONE] Image successfully pushed: ${repoUri}:${ImageTag}"
if ($loadBalancerDnsName) {
    Write-Host "[DONE] Application URL: http://$loadBalancerDnsName"
}
