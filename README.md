# Fast Agent FZ Docker

This project provides a browser-accessible console interface for the FastAgent, allowing you to interact with the agent through a web terminal.

## Overview

This repository combines two projects:
- `fast-agent-fz`: The core FastAgent implementation
- `mcp-fat-zebra`: The Fat Zebra MCP server for payment processing

The Docker container exposes a web-based terminal interface using `ttyd`, which allows you to interact with the FastAgent console directly from your browser.

## Features

- Browser-based terminal interface for FastAgent
- Direct interaction with the FastAgent functionality
- Containerized environment with all dependencies included
- Support for Fat Zebra payment processing

## Prerequisites

- Docker
- Docker Compose

## Installation

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/fast-agent-fz-docker.git
   cd fast-agent-fz-docker
   ```

2. Make sure you have the required repositories in the correct locations:
   - `C:\projects\fast-agent-fz`
   - `C:\projects\mcp-fat-zebra`

## Usage

### Running with Docker Compose

Build and run using Docker Compose:

```
docker-compose up --build
```

This will:
1. Build the Docker image with all required dependencies
2. Start the container with the web terminal interface
3. Expose the interface on port 7681

### Accessing the Web Terminal

Once the container is running, open your browser and navigate to:

```
http://localhost:7681
```

You'll see a terminal interface where you can interact with the FastAgent directly.

### Using the Agent

In the web terminal:

1. Type your queries or commands at the prompt
2. The agent will process your input and display the response
3. Type `exit`, `quit`, or `q` to exit the console

## Configuration

The agent configuration is controlled via the following files:

- `fast-agent-fz/fastagent.config.yaml` - General configuration
- `fast-agent-fz/fastagent.secrets.yaml` - Sensitive configuration (API keys, etc.)

These files are mounted as volumes in the Docker container, so you can modify them without rebuilding the image.

## Troubleshooting

If you encounter issues:

1. Check the Docker logs:
   ```
   docker-compose logs
   ```

2. Ensure all required repositories are in the correct locations
3. Verify that port 7681 is not in use by another application

## License

See the LICENSE file for details.