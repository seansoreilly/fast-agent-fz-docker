import gradio as gr
import asyncio
from agent import fast, generate_response
import os

# Ensure the static directory exists
os.makedirs("static", exist_ok=True)

async def process_message(message, history):
    """Process a user message through the Fat Zebra agent."""
    async with fast.run() as agent:
        # Pass the message to the agent and get the response
        response = await generate_response(agent, message)
        return response

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

if __name__ == "__main__":
    demo.launch(
        server_name="0.0.0.0",
        server_port=7860,
        pwa=True,
        show_error=True,
        share=True,
        favicon_path="static/5f03e4e6c8c68511212f0c40_FZ_Favicon_32x32.png",
        app_kwargs={
            "head_html": """
                <link rel="manifest" href="/static/manifest.json">
                <meta name="theme-color" content="#ffffff">
                <link rel="apple-touch-icon" href="/static/5f03e4e6c8c68511212f0c40_FZ_Favicon_32x32.png">
            """
        })
