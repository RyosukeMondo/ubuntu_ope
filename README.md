# Suspend Manager

Simple CLI tool to manage Ubuntu suspend/sleep settings.

## Features

- **Disable** suspend/sleep (useful for servers accessed via SSH)
- **Enable** suspend/sleep (restore default behavior)
- **Status** check (view current configuration)

## Installation

```bash
cd ~/repos/ubuntu_ope
cargo build --release
sudo cp target/release/suspend_manager /usr/local/bin/
```

## Usage

### Check current status
```bash
suspend_manager status
```

### Disable suspend/sleep
```bash
suspend_manager disable
```

This will:
- Mask systemd suspend targets (sleep, suspend, hibernate, hybrid-sleep)
- Configure systemd-logind to ignore idle actions and lid switch
- Restart systemd-logind service

### Enable suspend/sleep
```bash
suspend_manager enable
```

This will:
- Unmask systemd suspend targets
- Remove custom logind configuration
- Restart systemd-logind service

## Requirements

- Ubuntu/Debian-based Linux distribution
- systemd
- sudo privileges

## How It Works

The tool manages two aspects of suspend behavior:

1. **Systemd targets**: Masks/unmasks sleep, suspend, hibernate, and hybrid-sleep targets
2. **Logind configuration**: Creates/removes config file at `/etc/systemd/logind.conf.d/99-suspend-manager.conf`

All changes are reversible - running `suspend_manager enable` restores default system behavior.

## Build

```bash
cargo build --release
```

## License

MIT
