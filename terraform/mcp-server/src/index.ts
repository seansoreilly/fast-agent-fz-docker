import { MCPServer } from "mcp-framework";

// Create the MCP server instance
const server = new MCPServer();

// The MCP Framework automatically discovers and loads tools and resources
// from the tools directory when the server starts

// Start the server
server.start()
  .catch((error) => {
    process.stderr.write(`[ERROR] Failed to start server: ${error}\n`);
  });