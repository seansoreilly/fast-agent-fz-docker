# Setup script for Fast Agent Fat Zebra Docker implementation
# This script creates the necessary directory structure and copies files from source repositories

# Create required directories if they don't already exist
Write-Host "Creating directory structure..." -ForegroundColor Green
$directories = @(
    "app",
    "app\static",
    "app\documentation",
    "mcp-server\src\tools",
    "logs"
)

foreach ($dir in $directories) {
    if (!(Test-Path -Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
        Write-Host "Created directory: $dir" -ForegroundColor Cyan
    }
    else {
        Write-Host "Directory already exists: $dir" -ForegroundColor Gray
    }
}

# Check if source directories exist
$fastAgentPath = "C:\projects\fast-agent-fz"
$mcpFatZebraPath = "C:\projects\mcp-fat-zebra"

if (!(Test-Path -Path $fastAgentPath)) {
    Write-Host "Error: Source directory not found: $fastAgentPath" -ForegroundColor Red
    exit 1
}

if (!(Test-Path -Path $mcpFatZebraPath)) {
    Write-Host "Error: Source directory not found: $mcpFatZebraPath" -ForegroundColor Red
    exit 1
}

# Copy files from fast-agent-fz repository
Write-Host "Copying files from fast-agent-fz repository..." -ForegroundColor Green
Copy-Item -Path "$fastAgentPath\gradio_app.py" -Destination "app\" -Force
Copy-Item -Path "$fastAgentPath\agent.py" -Destination "app\" -Force
Copy-Item -Path "$fastAgentPath\fastagent.config.yaml" -Destination "app\" -Force
Copy-Item -Path "$fastAgentPath\requirements.txt" -Destination "app\" -Force
Copy-Item -Path "$fastAgentPath\static\*" -Destination "app\static\" -Recurse -Force
Copy-Item -Path "$fastAgentPath\documentation\*" -Destination "app\documentation\" -Recurse -Force

# Copy files from mcp-fat-zebra repository
Write-Host "Copying files from mcp-fat-zebra repository..." -ForegroundColor Green
Copy-Item -Path "$mcpFatZebraPath\src\index.ts" -Destination "mcp-server\src\" -Force
Copy-Item -Path "$mcpFatZebraPath\src\tools\*.ts" -Destination "mcp-server\src\tools\" -Force
Copy-Item -Path "$mcpFatZebraPath\package.json" -Destination "mcp-server\" -Force
Copy-Item -Path "$mcpFatZebraPath\package-lock.json" -Destination "mcp-server\" -Force
Copy-Item -Path "$mcpFatZebraPath\tsconfig.json" -Destination "mcp-server\" -Force

# Update configuration file to use container paths
Write-Host "Updating configuration file..." -ForegroundColor Green
$configPath = "app\fastagent.config.yaml"
$configContent = Get-Content -Path $configPath -Raw
$updatedConfig = $configContent -replace 'args: \["../mcp-fat-zebra/dist/index.js"\]', 'args: ["/app/mcp-server/dist/index.js"]'
Set-Content -Path $configPath -Value $updatedConfig

Write-Host "Setup complete!" -ForegroundColor Green
Write-Host "You can now build and run the Docker container using:" -ForegroundColor Yellow
Write-Host "docker-compose up -d" -ForegroundColor Yellow