import gradio as gr
import asyncio
from agent import fast, generate_response
import os
import traceback
import sys
from fastapi import FastAPI, Response
import uvicorn

# Ensure the static directory exists
os.makedirs("static", exist_ok=True)

# Create FastAPI app instance
app = FastAPI()

# Add health check endpoint
@app.get("/health")
async def health_check():
    return Response(status_code=200, content="OK")

async def process_message(message, history):
    """Process a user message through the Fat Zebra agent."""
    try:
        print(f"Starting process_message with message: {message}", file=sys.stderr)
        print(f"MCP Configuration: {fast.config}", file=sys.stderr)
        print(f"Environment variables: ANTHROPIC_API_KEY={bool(os.environ.get('ANTHROPIC_API_KEY'))}, OPENAI_API_KEY={bool(os.environ.get('OPENAI_API_KEY'))}", file=sys.stderr)
        
        async with fast.run() as agent:
            # Pass the message to the agent and get the response
            print("Agent created successfully, generating response...", file=sys.stderr)
            response = await generate_response(agent, message)
            print("Response generated successfully", file=sys.stderr)
            return response
    except Exception as e:
        error_msg = f"Error in process_message: {str(e)}\n{traceback.format_exc()}"
        print(error_msg, file=sys.stderr)
        return f"Sorry, an error occurred: {str(e)}"

# Create the Gradio interface
demo = gr.ChatInterface(
    fn=process_message,
    title="Fat Zebra AI Assistant",
    description="Ask me anything about Fat Zebra payments, transactions, or API usage.",
    theme="soft",
    examples=[
        "Do a test payment and explain it?",
        "What's the process for issuing a refund?",
        "How do I tokenize a card?",
        "What are the parameters for a direct debit payment?"
    ]
)

# Mount the Gradio app onto the FastAPI app
app = gr.mount_gradio_app(app, demo, path="/")

if __name__ == "__main__":
    # Launch the FastAPI app using uvicorn instead of demo.launch()
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=7860,
        log_level="info"
    )
