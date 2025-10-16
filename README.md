# Ubuntu OPE (Operations & Environment)

Collection of setup scripts and tools for Ubuntu development environments.

## Repository Structure

```
ubuntu_ope/
├── scripts/
│   ├── system/           # System-level setup scripts
│   │   └── setup_ubuntu.sh
│   ├── editors/          # Editor configurations
│   │   └── setup_neovim.sh
│   ├── terminal/         # Terminal multiplexers and tools
│   │   └── setup_zellij.sh
│   └── utils/            # Utility scripts
│       └── clone_repos.py
├── src/                  # Rust source code (suspend manager)
├── Cargo.toml
└── README.md
```

## Setup Scripts

### System Setup
**Location:** `scripts/system/setup_ubuntu.sh`

Comprehensive Ubuntu system setup including:
- System updates and build essentials
- Rust toolchain installation
- Modern CLI tools (eza, bat, ripgrep, fd, zoxide, etc.)
- GitHub CLI, gitui, lazygit
- Starship prompt
- Nerd Fonts (JetBrainsMono)
- Neovim installation
- Shell configuration (bash/zsh)

**Usage:**
```bash
./scripts/system/setup_ubuntu.sh
```

### Neovim Setup
**Location:** `scripts/editors/setup_neovim.sh`

Modern Neovim configuration with lazy.nvim:
- Gruvbox colorscheme
- LSP support (Mason, multiple language servers)
- Treesitter for syntax highlighting
- Telescope fuzzy finder
- Auto-completion (nvim-cmp)
- File explorer (neo-tree)
- Git integration (gitsigns)
- Code formatting (conform.nvim)

**Usage:**
```bash
./scripts/editors/setup_neovim.sh
```

**Key bindings:** (Leader = Space)
- `Space+ff` - Find files
- `Space+fs` - Search in files
- `Space+e` - Toggle file explorer
- `gd` - Go to definition
- `gr` - Show references
- `K` - Show documentation

### Zellij Setup
**Location:** `scripts/terminal/setup_zellij.sh`

Installs Zellij terminal multiplexer (modern alternative to tmux).

**Usage:**
```bash
./scripts/terminal/setup_zellij.sh
```

### Clone Repositories
**Location:** `scripts/utils/clone_repos.py`

Python script to clone all repositories from a GitHub account.

**Requirements:** GitHub CLI (`gh`)

**Usage:**
```bash
./scripts/utils/clone_repos.py
```

## Suspend Manager (Rust Tool)

CLI tool to manage Ubuntu suspend/sleep settings.

### Features
- **Disable** suspend/sleep (useful for servers accessed via SSH)
- **Enable** suspend/sleep (restore default behavior)
- **Status** check (view current configuration)

### Installation
```bash
cargo build --release
sudo cp target/release/suspend_manager /usr/local/bin/
```

### Usage

**Check current status:**
```bash
suspend_manager status
```

**Disable suspend/sleep:**
```bash
suspend_manager disable
```

**Enable suspend/sleep:**
```bash
suspend_manager enable
```

## Quick Start

1. **Initial system setup:**
   ```bash
   ./scripts/system/setup_ubuntu.sh
   source ~/.bashrc
   ```

2. **Setup Neovim:**
   ```bash
   ./scripts/editors/setup_neovim.sh
   nvim  # Plugins will auto-install
   ```

3. **Setup Zellij (optional):**
   ```bash
   ./scripts/terminal/setup_zellij.sh
   ```

4. **Build suspend manager (optional):**
   ```bash
   cargo build --release
   sudo cp target/release/suspend_manager /usr/local/bin/
   ```

## Requirements

- Ubuntu/Debian-based Linux distribution
- sudo privileges
- Internet connection

## License

MIT
