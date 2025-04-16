"""Fat Zebra AI agent implementation using Fast Agent MCP framework."""

import asyncio
import os
import glob
import logging
from mcp_agent import FastAgent

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("fatzebra-agent")

# Create the application
fast = FastAgent("Fat Zebra AI")

# Function to generate responses (for Gradio integration)
async def generate_response(agent, message):
    """Generate a response to a user message."""
    # Process the message and return the response
    response = await agent.send(message)
    return response

# Define the agent
@fast.agent(instruction="Assist with any queries regarding the Fat Zebra API", servers=["fatzebra"])
async def main():
    """Run the Fat Zebra AI agent in an async context."""
    # use the --model command line switch or agent arguments to change model
    async with fast.run() as agent:
        # Add the generate_response method to the agent
        agent.generate_response = lambda message: generate_response(agent, message)
        
        # Load all markdown files from documentation directory
        doc_path = r"documentation"
        logger.info(f"Looking for documentation files in: {os.path.abspath(doc_path)}")
        markdown_files = glob.glob(os.path.join(doc_path, "**/*.md"), recursive=True)
        logger.info(f"Found {len(markdown_files)} documentation files")
        
        for md_file in markdown_files:
            relative_path = os.path.relpath(md_file, doc_path)
            try:
                with open(md_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                    logger.info(f"Loading documentation: {md_file}")
                    await agent.with_resource(
                        content,     # message (description)
                        content,     # content of the file
                    )
                    logger.debug(f"Successfully loaded: {md_file} ({len(content)} bytes)")
            except Exception as e:
                logger.error(f"Failed to load {md_file}: {str(e)}")
        
        logger.info("All documentation resources loaded")
        await agent()


if __name__ == "__main__":
    asyncio.run(main())
