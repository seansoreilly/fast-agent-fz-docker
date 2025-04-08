import asyncio
from mcp_agent import FastAgent

# Create the application
fast = FastAgent("Fat Zebra AI")


# Define the agent
@fast.agent(instruction="You are a helpful AI Agent", servers=["fetch","filesystem","fatzebra"])
async def main():
    # use the --model command line switch or agent arguments to change model
    async with fast.run() as agent:
        await agent()


if __name__ == "__main__":
    asyncio.run(main())
