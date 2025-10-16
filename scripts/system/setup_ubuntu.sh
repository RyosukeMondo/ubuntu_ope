#!/bin/bash

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo_error "Please do not run this script as root. It will request sudo when needed."
    exit 1
fi

echo_info "Starting Ubuntu setup..."

# ============================================================================
# System Update & Dependencies
# ============================================================================
echo_info "Updating system packages..."
sudo apt update && sudo apt upgrade -y

echo_info "Installing build essentials and dependencies..."
sudo apt install -y \
    build-essential \
    curl \
    wget \
    git \
    unzip \
    pkg-config \
    libssl-dev \
    libsqlite3-dev \
    cmake \
    gettext \
    ninja-build \
    fontconfig

# ============================================================================
# Install Rust
# ============================================================================
if ! command -v rustc &> /dev/null; then
    echo_info "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo_info "Rust is already installed, updating..."
    rustup update
fi

# Ensure cargo is in PATH
export PATH="$HOME/.cargo/bin:$PATH"

# ============================================================================
# Install Modern Rust-based CLI Tools
# ============================================================================
echo_info "Installing modern CLI tools written in Rust..."

# eza - modern ls replacement (actively maintained fork of exa)
echo_info "Installing eza (ls replacement)..."
cargo install eza

# bat - cat with syntax highlighting
echo_info "Installing bat (cat replacement)..."
cargo install bat

# ripgrep - fast grep alternative
echo_info "Installing ripgrep (grep replacement)..."
cargo install ripgrep

# fd - modern find alternative
echo_info "Installing fd-find (find replacement)..."
cargo install fd-find

# zoxide - smarter cd command
echo_info "Installing zoxide (smart cd)..."
cargo install zoxide

# dust - du replacement
echo_info "Installing dust (du replacement)..."
cargo install du-dust

# procs - modern ps replacement
echo_info "Installing procs (ps replacement)..."
cargo install procs

# bottom - htop/top replacement
echo_info "Installing bottom (htop replacement)..."
cargo install bottom

# delta - better git diff
echo_info "Installing delta (git diff pager)..."
cargo install git-delta

# tokei - code statistics
echo_info "Installing tokei (code counter)..."
cargo install tokei

# hyperfine - benchmarking tool
echo_info "Installing hyperfine (benchmarking)..."
cargo install hyperfine

# sd - modern sed alternative
echo_info "Installing sd (sed alternative)..."
cargo install sd

# ============================================================================
# Install Atuin (Shell History)
# ============================================================================
echo_info "Installing atuin (enhanced shell history with Ctrl+R)..."
cargo install atuin

# ============================================================================
# Install GitHub CLI
# ============================================================================
echo_info "Installing GitHub CLI (gh)..."
if ! command -v gh &> /dev/null; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install -y gh
else
    echo_info "GitHub CLI already installed"
fi

# ============================================================================
# Install gitui (from binary due to compilation issues with some Rust versions)
# ============================================================================
echo_info "Installing gitui (terminal UI for git)..."
if ! command -v gitui &> /dev/null; then
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        GITUI_ARCH="x86_64"
    elif [ "$ARCH" = "aarch64" ]; then
        GITUI_ARCH="aarch64"
    else
        echo_warn "Unsupported architecture for gitui: $ARCH, skipping..."
        GITUI_ARCH=""
    fi

    if [ -n "$GITUI_ARCH" ]; then
        GITUI_VERSION=$(curl -s "https://api.github.com/repos/gitui-org/gitui/releases/latest" | grep -Po '"tag_name": "v\K[^"]*' || echo "0.27.0")
        echo_info "Downloading gitui v${GITUI_VERSION} for $ARCH..."
        curl -Lo /tmp/gitui.tar.gz "https://github.com/gitui-org/gitui/releases/download/v${GITUI_VERSION}/gitui-linux-${GITUI_ARCH}.tar.gz"
        sudo tar xf /tmp/gitui.tar.gz -C /usr/local/bin
        sudo chmod +x /usr/local/bin/gitui
        rm /tmp/gitui.tar.gz
        echo_info "gitui installed from binary"
    fi
else
    echo_info "gitui already installed"
fi

# ============================================================================
# Install Starship Prompt
# ============================================================================
echo_info "Installing Starship prompt..."
if ! command -v starship &> /dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
else
    echo_info "Starship already installed"
fi

# ============================================================================
# Install Nerd Fonts
# ============================================================================
echo_info "Installing Nerd Fonts (JetBrainsMono)..."
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

if [ ! -f "$FONT_DIR/JetBrainsMonoNerdFont-Regular.ttf" ]; then
    cd /tmp
    wget https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
    unzip -o JetBrainsMono.zip -d JetBrainsMono
    cp JetBrainsMono/*.ttf "$FONT_DIR/"
    rm -rf JetBrainsMono JetBrainsMono.zip
    fc-cache -fv
    echo_info "JetBrainsMono Nerd Font installed"
else
    echo_info "JetBrainsMono Nerd Font already installed"
fi

# ============================================================================
# Install Neovim
# ============================================================================
echo_info "Installing Neovim (latest stable)..."
if ! command -v nvim &> /dev/null || [ "$(nvim --version | head -n1 | cut -d' ' -f2 | cut -d'.' -f2)" -lt "9" ]; then
    cd /tmp
    # Detect architecture
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
        NVIM_DIR="nvim-linux-x86_64"
    elif [ "$ARCH" = "aarch64" ]; then
        NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-arm64.tar.gz"
        NVIM_DIR="nvim-linux-arm64"
    else
        echo_error "Unsupported architecture: $ARCH"
        exit 1
    fi

    echo_info "Downloading Neovim for $ARCH..."
    wget "$NVIM_URL" -O nvim.tar.gz
    sudo rm -rf "/opt/$NVIM_DIR"
    sudo tar -xzf nvim.tar.gz -C /opt/
    sudo ln -sf "/opt/$NVIM_DIR/bin/nvim" /usr/local/bin/nvim
    rm nvim.tar.gz
    echo_info "Neovim installed successfully"
else
    echo_info "Neovim already installed"
fi

# ============================================================================
# Additional Recommended Tools
# ============================================================================

# fzf - fuzzy finder (still useful for many integrations)
echo_info "Installing fzf (fuzzy finder)..."
if [ ! -d "$HOME/.fzf" ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all --no-bash --no-zsh --no-fish
else
    echo_info "fzf already installed"
fi

# lazygit - terminal UI for git commands
echo_info "Installing lazygit..."
if ! command -v lazygit &> /dev/null; then
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        LAZYGIT_ARCH="x86_64"
    elif [ "$ARCH" = "aarch64" ]; then
        LAZYGIT_ARCH="arm64"
    else
        echo_warn "Unsupported architecture for lazygit: $ARCH, skipping..."
        LAZYGIT_ARCH=""
    fi

    if [ -n "$LAZYGIT_ARCH" ]; then
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        echo_info "Downloading lazygit v${LAZYGIT_VERSION} for $ARCH..."
        curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_${LAZYGIT_ARCH}.tar.gz"
        sudo tar xf /tmp/lazygit.tar.gz -C /usr/local/bin lazygit
        rm /tmp/lazygit.tar.gz
        echo_info "lazygit installed successfully"
    fi
else
    echo_info "lazygit already installed"
fi

# tldr - simplified man pages
echo_info "Installing tldr (simplified man pages)..."
cargo install tealdeer

# ============================================================================
# Setup Shell Configurations
# ============================================================================
echo_info "Setting up shell configurations..."

# Backup existing configs
[ -f "$HOME/.bashrc" ] && cp "$HOME/.bashrc" "$HOME/.bashrc.backup"
[ -f "$HOME/.zshrc" ] && cp "$HOME/.zshrc" "$HOME/.zshrc.backup"

# Create shell config snippet
cat > "$HOME/.shell_aliases" << 'EOF'
# Modern CLI tool aliases and configurations

# eza (ls replacement)
alias ls='eza --icons'
alias ll='eza -l --icons --git'
alias la='eza -la --icons --git'
alias lt='eza --tree --icons'
alias l='eza -lah --icons --git'

# bat (cat replacement)
alias cat='bat --style=auto'
alias catn='bat --style=plain'  # cat without line numbers

# Other useful aliases
alias top='btm'
alias htop='btm'
alias du='dust'
alias ps='procs'
alias find='fd'
alias grep='rg'

# Git aliases
alias g='git'
alias gs='git status'
alias gd='git diff'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias glog='git log --oneline --graph --decorate'
alias gg='gitui'
alias lg='lazygit'

# Directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'

# Safety
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Misc
alias reload='source ~/.bashrc'  # or source ~/.zshrc for zsh
alias update='sudo apt update && sudo apt upgrade -y'
EOF

# Add to bashrc
if ! grep -q ".shell_aliases" "$HOME/.bashrc"; then
    cat >> "$HOME/.bashrc" << 'EOF'

# Load modern CLI tools configuration
if [ -f ~/.shell_aliases ]; then
    . ~/.shell_aliases
fi

# Initialize starship prompt
eval "$(starship init bash)"

# Initialize zoxide
eval "$(zoxide init bash)"

# Initialize atuin
eval "$(atuin init bash)"

# fzf key bindings
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
EOF
fi

# If zsh is installed, configure it too
if command -v zsh &> /dev/null; then
    if [ ! -f "$HOME/.zshrc" ]; then
        touch "$HOME/.zshrc"
    fi

    if ! grep -q ".shell_aliases" "$HOME/.zshrc"; then
        cat >> "$HOME/.zshrc" << 'EOF'

# Load modern CLI tools configuration
if [ -f ~/.shell_aliases ]; then
    . ~/.shell_aliases
fi

# Initialize starship prompt
eval "$(starship init zsh)"

# Initialize zoxide
eval "$(zoxide init zsh)"

# Initialize atuin
eval "$(atuin init zsh)"

# fzf key bindings
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
EOF
    fi
fi

# ============================================================================
# Setup Starship with Gruvbox Rainbow Preset
# ============================================================================
echo_info "Configuring Starship with Gruvbox Rainbow preset..."
mkdir -p "$HOME/.config"
starship preset gruvbox-rainbow -o "$HOME/.config/starship.toml"

# ============================================================================
# Configure Git to use delta
# ============================================================================
echo_info "Configuring git to use delta as diff pager..."
git config --global core.pager "delta"
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.light false
git config --global delta.side-by-side true
git config --global merge.conflictstyle diff3
git config --global diff.colorMoved default

# ============================================================================
# Final Steps
# ============================================================================
echo_info "Updating tldr cache..."
tldr --update

echo_info ""
echo_info "============================================================================"
echo_info "Setup completed successfully!"
echo_info "============================================================================"
echo_info ""
echo_info "Next steps:"
echo_info "1. Restart your terminal or run: source ~/.bashrc"
echo_info "2. Set your terminal font to 'JetBrainsMono Nerd Font'"
echo_info "3. Run './neovim-setup.sh' to configure Neovim with modern plugins"
echo_info "4. Authenticate GitHub CLI: gh auth login"
echo_info "5. Initialize atuin sync (optional): atuin register"
echo_info ""
echo_info "New commands available:"
echo_info "  - ls, ll, la, lt (eza)"
echo_info "  - cat (bat)"
echo_info "  - find (fd)"
echo_info "  - grep (rg/ripgrep)"
echo_info "  - cd -> use 'z' for smart jumping (zoxide)"
echo_info "  - Ctrl+R for enhanced history search (atuin)"
echo_info "  - gitui or gg for git TUI"
echo_info "  - lazygit or lg for another git TUI"
echo_info "  - tldr for simplified man pages"
echo_info ""
echo_info "Enjoy your modern Ubuntu setup!"
