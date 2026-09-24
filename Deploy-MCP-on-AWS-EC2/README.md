```markdown
# MCP Server on AWS EC2

This project deploys a Model Context Protocol (MCP) server on an AWS EC2 instance and connects to it using a Strands Agent. The agent communicates with the MCP server over a streamable HTTP transport and uses an LLM backend (Anthropic or Bedrock) to execute tool calls.

## Features

- MCP server running on EC2  
- Streamable HTTP transport  
- Strands Agent integration  
- Automatic tool discovery  
- Support for Anthropic API or AWS Bedrock models  

## Requirements

- Python 3.10+  
- Virtual environment (`venv`)  
- MCP server running on EC2  
- Anthropic API key **or** AWS IAM credentials  

## Setup

```bash
git clone <repo>
cd Deploy-MCP-on-AWS-EC2
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Running the Agent

### Using Anthropic
```bash
export ANTHROPIC_API_KEY="sk-ant-..."
python connect-mcp-server.py
```

### Using Bedrock
```bash
export AWS_ACCESS_KEY_ID="AKIA..."
export AWS_SECRET_ACCESS_KEY="..."
python connect-mcp-server.py
```

## File Overview

- `connect-mcp-server.py` — connects to the MCP server and runs the Strands agent  
- `mcp_server/` — MCP server implementation  
- `tools/` — MCP tools exposed to the agent  

## License

MIT
```

