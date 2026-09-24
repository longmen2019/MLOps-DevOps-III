import os
import sys

from mcp.client.streamable_http import streamablehttp_client
from strands import Agent
from strands.models.anthropic import AnthropicModel
from strands.tools.mcp.mcp_client import MCPClient

if not os.environ.get("ANTHROPIC_API_KEY"):
    sys.exit("ANTHROPIC_API_KEY is not set. Run: export ANTHROPIC_API_KEY='sk-ant-...'")


def create_streamable_http_transport():
    return streamablehttp_client("http://100.59.4.67:8081/mcp")


mcp_client = MCPClient(create_streamable_http_transport)

model = AnthropicModel(
    model_id="claude-sonnet-5",
    max_tokens=1024,
)

with mcp_client:
    tools = mcp_client.list_tools_sync()
    print("Tools discovered:", tools)

    agent = Agent(
        tools=tools,
        model=model,
    )

    response = agent("What is 125 plus 375?")
    print("Agent response:", response)