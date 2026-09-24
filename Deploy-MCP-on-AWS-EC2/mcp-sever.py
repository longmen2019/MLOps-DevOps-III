from mcp.server.fastmcp import FastMCP
from mcp.server.transport_security import TransportSecuritySettings

security = TransportSecuritySettings(enable_dns_rebinding_protection=False)

mcp = FastMCP(
    "Calculator Server",
    host="0.0.0.0",
    port=8081,
    transport_security=security,
)

@mcp.tool(description="Add two numbers together")
def add(x: int, y: int) -> int:
    return x + y

@mcp.tool(description="Multiply two numbers together")
def multiply(x: int, y: int) -> int:
    return x * y

@mcp.tool(description="Greet someone by name")
def greet(name: str) -> str:
    return f"Hello, {name}!"

if __name__ == "__main__":
    mcp.run(transport="streamable-http")