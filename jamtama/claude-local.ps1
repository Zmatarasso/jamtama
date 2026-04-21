# claude-local.ps1
# Launches Claude Code using your local Qwen3.5-35B-A3B model via LM Studio

Write-Host "Starting Claude Code with local model" -ForegroundColor Green

# Set the environment variables for LM Studio
$env:ANTHROPIC_BASE_URL = "http://localhost:1234"
$env:ANTHROPIC_AUTH_TOKEN = "lmstudio"

# Launch Claude Code with your exact model
# claude --model qwen/qwen3.5-35b-a3b
# claude --model qwen/qwen3.5-9b
claude --model google/gemma-4-e4b