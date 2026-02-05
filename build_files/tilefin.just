# Tilefin custom recipes

# Install Claude Code CLI to user's home directory
setup-claude:
    #!/usr/bin/env bash
    if command -v claude &>/dev/null; then
        echo "Claude Code is already installed: $(claude --version)"
        echo "Run 'claude update' to check for updates"
    else
        echo "Installing Claude Code CLI..."
        curl -fsSL https://claude.ai/install.sh | bash
        echo "Claude Code installed. Restart your shell or run: source ~/.bashrc"
    fi
