"""Fat Zebra AI agent implementation using Fast Agent MCP framework."""

import asyncio
from mcp_agent import FastAgent

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
        await agent()


if __name__ == "__main__":
    asyncio.run(main())
