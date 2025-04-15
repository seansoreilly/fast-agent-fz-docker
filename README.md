# Fast Agent Fat Zebra - Docker Implementation

This repository contains a Docker implementation of the Fast Agent Fat Zebra Gradio application. The application provides an AI assistant for Fat Zebra payment gateway interactions through a web interface.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

## Quick Start

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/fast-agent-fz-docker.git
   cd fast-agent-fz-docker
   ```

2. Set up environment variables:
   ```bash
   # Create a .env file
   touch .env

   # Add your API keys to the .env file
   echo "ANTHROPIC_API_KEY=your_anthropic_api_key" >> .env
   echo "OPENAI_API_KEY=your_openai_api_key" >> .env
   
   # Optional: Configure Fat Zebra credentials (defaults to TEST mode if not provided)
   echo "FAT_ZEBRA_USERNAME=your_username" >> .env
   echo "FAT_ZEBRA_TOKEN=your_token" >> .env
   echo "FAT_ZEBRA_API_URL=your_api_url" >> .env
   ```

3. Build and start the container:
   ```bash
   docker-compose up -d
   ```

4. Access the Gradio interface:
   Open your browser and navigate to [http://localhost:7860](http://localhost:7860)

## Directory Structure

```
fast-agent-fz-docker/
├── app/                  # Python application files
│   ├── gradio_app.py     # Main Gradio application
│   ├── agent.py          # Fat Zebra AI agent implementation
│   ├── fastagent.config.yaml  # Configuration file
│   └── static/           # Static assets
├── mcp-server/           # MCP server files
│   ├── src/              # TypeScript source code
│   │   ├── index.ts      # Main entry point
│   │   └── tools/        # Fat Zebra API tools
│   └── package.json      # Node.js dependencies
├── Dockerfile            # Multi-stage Docker build file
├── docker-compose.yml    # Docker Compose configuration
└── README.md             # This file
```

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `ANTHROPIC_API_KEY` | Anthropic API key for Claude model | Required |
| `OPENAI_API_KEY` | OpenAI API key (optional) | Optional |
| `FAT_ZEBRA_USERNAME` | Fat Zebra API username | TEST |
| `FAT_ZEBRA_TOKEN` | Fat Zebra API token | TEST |
| `FAT_ZEBRA_API_URL` | Fat Zebra API URL | https://gateway.sandbox.fatzebra.com.au/v1.0 |

### Customizing the Configuration

To modify the application configuration, edit the `app/fastagent.config.yaml` file before building the Docker image.

## Development

### Building the Image

```bash
docker build -t fast-agent-fz .
```

### Running in Development Mode

```bash
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up
```

## Troubleshooting

### Logs

View container logs:
```bash
docker-compose logs -f
```

### Common Issues

1. **Connection refused to port 7860**
   - Ensure no other service is using port 7860
   - Check if the container is running: `docker-compose ps`

2. **API Key Issues**
   - Verify your API keys are correctly set in the .env file
   - Check the container logs for authentication errors

3. **uvx Installation Issues**
   - If you encounter errors related to "No such file or directory: 'uvx'", the container is having issues with the uvx tool installation
   - The Dockerfile has been updated to properly install uv from the official Astral container image and create a symbolic link to uvx
   - The correct command syntax `uv pip install --system` is now used instead of `uvx install`
   - The `--system` flag is required because there's no virtual environment in the container
   - Rebuild the container with `docker-compose build --no-cache` followed by `docker-compose up -d`

## License

[MIT License](LICENSE)