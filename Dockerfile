# Multi-stage build for Fast Agent Fat Zebra Gradio App

# Stage 1: Build the MCP Fat Zebra server
FROM node:22-alpine AS mcp-builder

WORKDIR /app/mcp-server

# Copy package files and install dependencies
COPY mcp-server/package*.json ./
RUN npm install

# Copy source code
COPY mcp-server/src ./src
COPY mcp-server/tsconfig.json ./

# Build the TypeScript code
RUN npm run build

# Stage 2: Python application with Node.js
FROM python:3.11-slim

# Install Node.js, git, and utilities in a single layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    nodejs \
    npm \
    git \
    bash \
    procps \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Python requirements and install dependencies
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the MCP server from the builder stage
COPY --from=mcp-builder /app/mcp-server/dist /app/mcp-server/dist
COPY --from=mcp-builder /app/mcp-server/package*.json /app/mcp-server/

# Install MCP server production dependencies
WORKDIR /app/mcp-server
RUN npm install --production
WORKDIR /app # Back to app directory

# Install uv from the official container image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
RUN chmod +x /usr/local/bin/uv

# Install mcp-server-fetch using uv pip
RUN /usr/local/bin/uv pip install --system mcp-server-fetch

# Copy application files
COPY app/gradio_app.py .
COPY app/agent.py .
COPY app/fastagent.config.yaml .
COPY app/static ./static

# Secrets will be read directly from environment variables
# (ANTHROPIC_API_KEY, OPENAI_API_KEY)

# Configuration file already has correct container paths

# Expose the Gradio port
EXPOSE 7860

# Set environment variables (API keys should be set during container run)
ENV PYTHONUNBUFFERED=1 \
    FAT_ZEBRA_API_URL="https://gateway.sandbox.fatzebra.com.au/v1.0" \
    FAT_ZEBRA_USERNAME="TEST" \
    FAT_ZEBRA_TOKEN="TEST"

# Start the Gradio application directly
CMD ["python", "gradio_app.py"]