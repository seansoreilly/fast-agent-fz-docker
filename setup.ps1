# Setup script for Fast Agent Fat Zebra Docker implementation
# This script creates the necessary directory structure and copies files from source repositories

# Create required directories
Write-Host "Creating directory structure..." -ForegroundColor Green
New-Item -ItemType Directory -Force -Path "app"
New-Item -ItemType Directory -Force -Path "app\static"
New-Item -ItemType Directory -Force -Path "mcp-server\src\tools"
New-Item -ItemType Directory -Force -Path "logs"

# Copy files from fast-agent-fz repository
Write-Host "Copying files from fast-agent-fz repository..." -ForegroundColor Green
Copy-Item -Path "C:\projects\fast-agent-fz\gradio_app.py" -Destination "app\"
Copy-Item -Path "C:\projects\fast-agent-fz\agent.py" -Destination "app\"
Copy-Item -Path "C:\projects\fast-agent-fz\fastagent.config.yaml" -Destination "app\"
Copy-Item -Path "C:\projects\fast-agent-fz\requirements.txt" -Destination "app\"
Copy-Item -Path "C:\projects\fast-agent-fz\static\*" -Destination "app\static\" -Recurse

# Copy files from mcp-fat-zebra repository
Write-Host "Copying files from mcp-fat-zebra repository..." -ForegroundColor Green
Copy-Item -Path "C:\projects\mcp-fat-zebra\src\index.ts" -Destination "mcp-server\src\"
Copy-Item -Path "C:\projects\mcp-fat-zebra\src\tools\*.ts" -Destination "mcp-server\src\tools\"
Copy-Item -Path "C:\projects\mcp-fat-zebra\package.json" -Destination "mcp-server\"
Copy-Item -Path "C:\projects\mcp-fat-zebra\package-lock.json" -Destination "mcp-server\"
Copy-Item -Path "C:\projects\mcp-fat-zebra\tsconfig.json" -Destination "mcp-server\"

# Update configuration file to use container paths
Write-Host "Updating configuration file..." -ForegroundColor Green
$configPath = "app\fastagent.config.yaml"
$configContent = Get-Content -Path $configPath -Raw
$updatedConfig = $configContent -replace 'args: \["../mcp-fat-zebra/dist/index.js"\]', 'args: ["/app/mcp-server/dist/index.js"]'
Set-Content -Path $configPath -Value $updatedConfig

Write-Host "Setup complete!" -ForegroundColor Green
Write-Host "You can now build and run the Docker container using:" -ForegroundColor Yellow
Write-Host "docker-compose up -d" -ForegroundColor Yellow