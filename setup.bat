@echo off
echo Setting up fast-agent-fz-docker...

REM Clean existing directories
echo Cleaning existing directories...
if exist src\fast-agent-fz rmdir /S /Q src\fast-agent-fz
if exist src\mcp-fat-zebra rmdir /S /Q src\mcp-fat-zebra

REM Create necessary directories
mkdir src\fast-agent-fz 2>nul
mkdir src\mcp-fat-zebra\dist 2>nul

REM Copy files from fast-agent-fz
echo Copying files from fast-agent-fz...
copy C:\projects\fast-agent-fz\requirements.txt src\fast-agent-fz\
copy C:\projects\fast-agent-fz\agent.py src\fast-agent-fz\
copy C:\projects\fast-agent-fz\fastagent.config.yaml src\fast-agent-fz\
copy C:\projects\fast-agent-fz\fastagent.secrets.yaml src\fast-agent-fz\

REM Copy files from mcp-fat-zebra
echo Copying files from mcp-fat-zebra...
xcopy /E /I /Y C:\projects\mcp-fat-zebra\dist src\mcp-fat-zebra\dist
copy C:\projects\mcp-fat-zebra\*.json src\mcp-fat-zebra\

echo Setup completed successfully!