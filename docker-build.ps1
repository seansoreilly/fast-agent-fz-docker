# ECR Public Repository details
$REGION = "us-east-1"  # Public ECR is only available in us-east-1
$REPOSITORY = "dev-fast-agent-fz"
$IMAGE_TAG = "latest"
$ECR_URI = "public.ecr.aws"
$IMAGE_URI = "${ECR_URI}/${REPOSITORY}:${IMAGE_TAG}"

Write-Host "🔧 Building Docker image..."
docker build -t $IMAGE_URI .

Write-Host "🔑 Logging into Amazon ECR Public..."
aws ecr-public get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URI

Write-Host "⬆️ Pushing image to ECR Public..."
docker push $IMAGE_URI

Write-Host "✅ Done! Image URI: $IMAGE_URI" 