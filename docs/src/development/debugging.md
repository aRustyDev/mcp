# Debugging Tools

## Using MCP Inspector 

### For testing
npx @modelcontextprotocol/inspector uvx mcp-server ...

### For local development version
npx @modelcontextprotocol/inspector uv --directory /path/to/your/mcp-server run mcp-server ...

# View logs
# macOS
tail -n 20 -f ~/Library/Logs/Claude/mcp*.log
# Windows
type %APPDATA%\Claude\logs\mcp*.log | more
