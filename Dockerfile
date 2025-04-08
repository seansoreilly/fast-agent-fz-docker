FROM debian:bookworm

# Install basic dependencies first
RUN apt-get update && \
    apt-get install -y python3 python3-pip curl unzip ca-certificates git && \
    apt-get clean

# Install Node.js 22.x from NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean

# Download prebuilt ttyd binary (static Linux build)
RUN curl -L https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64 -o /usr/local/bin/ttyd && \
    chmod +x /usr/local/bin/ttyd

# Create a working directory
WORKDIR /app

# Copy package files for Node.js dependencies
COPY mcp-fat-zebra/package*.json /app/mcp-fat-zebra/
# Also copy package.json to /app for MCP server
COPY mcp-fat-zebra/package.json /app/

# Install Node.js dependencies
RUN cd /app/mcp-fat-zebra && npm ci

# Copy requirements from fast-agent-fz
COPY fast-agent-fz/requirements.txt /app/requirements.txt

# Install uv package manager
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    mv ~/.local/bin/uv* /usr/local/bin/

# Create and activate virtual environment, then install dependencies
RUN uv venv /app/.venv && \
    . /app/.venv/bin/activate && \
    uv pip install --no-cache-dir -r requirements.txt

# Ensure we use the virtual environment's Python
ENV PATH="/app/.venv/bin:$PATH"

# Copy fast-agent-fz files
COPY fast-agent-fz/agent.py /app/
COPY fast-agent-fz/fastagent.config.yaml /app/
COPY fast-agent-fz/fastagent.secrets.yaml /app/

# Copy mcp-fat-zebra files
COPY mcp-fat-zebra/dist /app/mcp-fat-zebra/dist
COPY mcp-fat-zebra/src /app/mcp-fat-zebra/src

# Copy our wrapper script
COPY fast-agent-fz-docker/run_agent.sh /app/run_agent.sh

RUN chmod +x /app/run_agent.sh

# Expose ttyd's default port
EXPOSE 7681

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV NODE_ENV=production

# Launch ttyd to run the agent
CMD ["ttyd", "-p", "7681", \
    "-t", "fontFamily=JetBrains Mono", \
    "-t", "fontSize=14", \
    "-t", "disableLeaveAlert=true", \
    "-t", "cursorBlink=true", \
    "-t", "theme={\"foreground\": \"#333333\", \"background\": \"#ffffff\"}", \
    "-t", "style=selection-background-color: #add6ff;", \
    "-t", "style=selection-color: #000000;", \
    "--writable", \
    "--terminal-type", "xterm", \
    "/app/run_agent.sh"]


