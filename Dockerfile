FROM debian:bookworm

# Install basic dependencies first
RUN apt-get update && \
    apt-get install -y python3 python3-pip curl unzip ca-certificates git apt-transport-https software-properties-common && \
    apt-get clean

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip

# Add Docker's official GPG key and repository
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli && \
    apt-get clean

# Set empty default values for AWS credentials
ENV AWS_ACCESS_KEY_ID=""
ENV AWS_SECRET_ACCESS_KEY=""
ENV AWS_DEFAULT_REGION="us-east-1"

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
COPY src/mcp-fat-zebra/package*.json /app/mcp-fat-zebra/
# Also copy package.json to /app for MCP server
COPY src/mcp-fat-zebra/package.json /app/

# Install Node.js dependencies
RUN cd /app/mcp-fat-zebra && npm ci

# Copy requirements from fast-agent-fz
COPY src/fast-agent-fz/requirements.txt /app/requirements.txt

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
COPY src/fast-agent-fz/agent.py /app/
COPY src/fast-agent-fz/fastagent.config.yaml /app/
COPY src/fast-agent-fz/fastagent.secrets.yaml /app/

# Copy mcp-fat-zebra files
COPY src/mcp-fat-zebra/dist /app/mcp-fat-zebra/dist

# Copy our wrapper script
COPY run_agent.sh /app/run_agent.sh

RUN chmod +x /app/run_agent.sh

# Expose ttyd's default port
EXPOSE 7681

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV NODE_ENV=production

# Launch ttyd to run the agent
CMD ["ttyd", "-p", "7681", \
    "-t", "fontFamily=JetBrains Mono", \
    "-t", "fontSize=15", \
    "-t", "fontWeight=500", \
    "-t", "disableLeaveAlert=true", \
    "-t", "cursorBlink=true", \
    "-t", "theme={\"foreground\": \"#333333\", \"background\": \"#ffffff\", \"cursor\": \"#0066cc\", \"blue\": \"#0052a3\", \"green\": \"#2d8500\", \"yellow\": \"#a66800\", \"brightBlue\": \"#0066cc\", \"brightGreen\": \"#39a814\", \"brightYellow\": \"#cc8400\"}", \
    "-t", "style=selection-background-color: #e6f0ff; selection-color: #333333; line-height: 1.5; padding: 12px; text-rendering: optimizeLegibility; -webkit-font-smoothing: antialiased; font-feature-settings: 'kern' 1, 'liga' 1;", \
    "-t", "scrollback=10000", \
    "-t", "allowTransparency=false", \
    "-t", "bellStyle=none", \
    "--writable", \
    "--terminal-type", "xterm-256color", \
    "--client-option", "fontSize=14", \
    "--client-option", "disableLeaveAlert=true", \
    "/app/run_agent.sh"]


