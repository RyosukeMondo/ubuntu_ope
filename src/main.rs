use clap::{Parser, Subcommand};
use std::process::{Command, exit};

#[derive(Parser)]
#[command(name = "suspend_manager")]
#[command(about = "Simple Ubuntu suspend/sleep manager", long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Disable suspend/sleep (mask systemd targets)
    Disable,
    /// Enable suspend/sleep (unmask systemd targets)
    Enable,
    /// Show current suspend status
    Status,
}

fn main() {
    let cli = Cli::parse();

    match &cli.command {
        Commands::Disable => disable_suspend(),
        Commands::Enable => enable_suspend(),
        Commands::Status => show_status(),
    }
}

fn disable_suspend() {
    println!("🔒 Disabling suspend/sleep...");

    let targets = ["sleep.target", "suspend.target", "hibernate.target", "hybrid-sleep.target"];

    // Mask systemd targets
    for target in targets {
        let output = Command::new("sudo")
            .args(["systemctl", "mask", target])
            .output();

        match output {
            Ok(result) => {
                if !result.status.success() {
                    eprintln!("❌ Failed to mask {}: {}", target, String::from_utf8_lossy(&result.stderr));
                    exit(1);
                }
            }
            Err(e) => {
                eprintln!("❌ Error running systemctl: {}", e);
                exit(1);
            }
        }
    }

    // Configure logind to ignore idle and lid switch
    println!("📝 Configuring systemd-logind...");

    let logind_config = r#"
# Suspend Manager Configuration
[Login]
IdleAction=ignore
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
"#;

    let config_path = "/etc/systemd/logind.conf.d/99-suspend-manager.conf";

    // Create config directory
    let _ = Command::new("sudo")
        .args(["mkdir", "-p", "/etc/systemd/logind.conf.d"])
        .output();

    // Write config file
    let write_result = Command::new("sudo")
        .args(["tee", config_path])
        .arg("/dev/null")
        .stdin(std::process::Stdio::piped())
        .spawn()
        .and_then(|mut child| {
            use std::io::Write;
            child.stdin.as_mut().unwrap().write_all(logind_config.as_bytes())?;
            child.wait()
        });

    match write_result {
        Ok(status) if status.success() => {
            println!("✅ Logind configuration created");
        }
        _ => {
            eprintln!("❌ Failed to create logind configuration");
            exit(1);
        }
    }

    // Restart logind
    let restart = Command::new("sudo")
        .args(["systemctl", "restart", "systemd-logind"])
        .status();

    match restart {
        Ok(status) if status.success() => {
            println!("✅ Suspend/sleep disabled successfully");
        }
        _ => {
            eprintln!("⚠️  Changes applied but logind restart may have failed");
            eprintln!("   Run: sudo systemctl restart systemd-logind");
        }
    }
}

fn enable_suspend() {
    println!("🔓 Enabling suspend/sleep...");

    let targets = ["sleep.target", "suspend.target", "hibernate.target", "hybrid-sleep.target"];

    // Unmask systemd targets
    for target in targets {
        let output = Command::new("sudo")
            .args(["systemctl", "unmask", target])
            .output();

        match output {
            Ok(result) => {
                if !result.status.success() {
                    eprintln!("❌ Failed to unmask {}: {}", target, String::from_utf8_lossy(&result.stderr));
                    exit(1);
                }
            }
            Err(e) => {
                eprintln!("❌ Error running systemctl: {}", e);
                exit(1);
            }
        }
    }

    // Remove logind config
    let config_path = "/etc/systemd/logind.conf.d/99-suspend-manager.conf";
    let _ = Command::new("sudo")
        .args(["rm", "-f", config_path])
        .output();

    // Restart logind
    let restart = Command::new("sudo")
        .args(["systemctl", "restart", "systemd-logind"])
        .status();

    match restart {
        Ok(status) if status.success() => {
            println!("✅ Suspend/sleep enabled successfully");
        }
        _ => {
            eprintln!("⚠️  Changes applied but logind restart may have failed");
            eprintln!("   Run: sudo systemctl restart systemd-logind");
        }
    }
}

fn show_status() {
    println!("📊 Suspend/Sleep Status\n");

    let targets = [
        "sleep.target",
        "suspend.target",
        "hibernate.target",
        "hybrid-sleep.target"
    ];

    println!("Systemd Targets:");
    for target in targets {
        let output = Command::new("systemctl")
            .args(["is-enabled", target])
            .output();

        match output {
            Ok(result) => {
                let status = String::from_utf8_lossy(&result.stdout).trim().to_string();
                let icon = if status.contains("masked") { "🔒" } else { "🔓" };
                println!("  {} {}: {}", icon, target, status);
            }
            Err(_) => {
                println!("  ❓ {}: unknown", target);
            }
        }
    }

    println!("\nLogind Configuration:");
    let config_exists = std::path::Path::new("/etc/systemd/logind.conf.d/99-suspend-manager.conf").exists();
    if config_exists {
        println!("  🔒 Custom config: active (suspend disabled)");
    } else {
        println!("  🔓 Custom config: none (system defaults)");
    }
}
