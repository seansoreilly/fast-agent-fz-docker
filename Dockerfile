FROM debian:bookworm

# Install Python3, Node.js, npm, curl (for download), and dependencies
RUN apt-get update && \
    apt-get install -y python3 python3-pip curl unzip ca-certificates git nodejs npm && \
    apt-get clean

# Download prebuilt ttyd binary (static Linux build)
RUN curl -L https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64 -o /usr/local/bin/ttyd && \
    chmod +x /usr/local/bin/ttyd

# Create a working directory
WORKDIR /app

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

# Copy our wrapper script
COPY fast-agent-fz-docker/run_agent.sh /app/run_agent.sh

RUN chmod +x /app/run_agent.sh

# Expose ttyd's default port
EXPOSE 7681

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Launch ttyd to run the agent
CMD ["ttyd", "-p", "7681", "/app/run_agent.sh"]