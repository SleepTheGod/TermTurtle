# TermTurtle
![Uploading image.png…]()

License: MIT
Shell: Bash
Platform: Cross Platform

TermTurtle is a cross-platform intelligent shell front-end that translates natural language intents into precise system commands. Whether you're on Linux, BSD, macOS, or Windows, TermTurtle makes complex shell operations accessible by understanding everyday queries like "scan the network" or "check disk usage" and generating the right command for your environment.

Powered by a JSON-based command database, it supports reconnaissance, system monitoring, file operations, and more—while prioritizing safety with risk assessments and confirmation prompts.

Made by Taylor Christian Newsome

Features

- Natural Language Processing: Describe what you want in plain English (e.g., "list files in home directory"), and get the equivalent shell command.
- Cross-Platform Support: Works seamlessly on:
  - Linux (Bash/Zsh/Fish)
  - BSD variants (FreeBSD, OpenBSD, NetBSD)
  - macOS
  - Windows (PowerShell/CMD via Cygwin/MSYS/Winget)
- Risk-Aware Execution: Commands are categorized by risk level (low/medium/high) with color-coded warnings and optional auto-execution.
- Interactive Mode: REPL-like interface for ongoing sessions.
- Extensible Database: Easy to add new commands via termturtle_commands.json.
- History & Clipboard Integration: Tracks usage and copies commands for easy pasting.
- Verbose Logging: Detailed output for debugging.

Quick Demo

$ ./termturtle2.sh "scan network"
╭─ Command Match Found
│
├─ Platform: linux (bash shell)
├─ Description: Discover live hosts on network
├─ Category: reconnaissance
├─ Risk Level: low
│
├─ Command:
│   nmap -sn 192.168.1.0/24
╰─

Execute this command? [y]es / [n]o / [c]opy to clipboard / [e]dit

Installation

Prerequisites
- jq: Required for JSON parsing. Install via your package manager:
  - Linux: sudo apt install jq (Debian/Ubuntu) or sudo yum install jq (RHEL/CentOS)
  - macOS: brew install jq
  - Windows: Available via Winget (winget install jqlang.jq) or Chocolatey (choco install jq)
  - BSD: pkg install jq

Setup
1. Clone the repository:
   git clone https://github.com/SleepTheGod/TermTurtle.git
   cd TermTurtle

2. Make the script executable:
   chmod +x termturtle2.sh

3. (Optional) Customize the command database by editing termturtle_commands.json.

No additional setup is needed—TermTurtle auto-detects your OS, shell, and package manager.

Usage

Run the script with natural language queries or in interactive mode.

Command-Line Mode
# Basic query
./termturtle2.sh "check open ports on localhost"

# With options
./termturtle2.sh -v "install vim"          # Verbose output
./termturtle2.sh -a "ping google.com"       # Auto-execute (use with caution!)
./termturtle2.sh --history                  # View command history
./termturtle2.sh --update                   # Refresh command database

Interactive Mode
```bash
$ ./termturtle2.sh -i
╔════════════════════════════════════════════════════════════════╗
║  ████████╗███████╗██████╗ ███╗   ███╗████████╗██╗   ██╗██████╗ ║
║  ╚══██╔══╝██╔════╝██╔══██╗████╗ ████║╚══██╔══╝██║   ██║██╔══██╗║
║     ██║   █████╗  ██████╔╝██╔████╔██║   ██║   ██║   ██║██████╔╝║
║     ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║   ██║   ██║   ██║██╔══██╗║
║     ██║   ███████╗██║  ██║██║ ╚═╝ ██║   ██║   ╚██████╔╝██║  ██║║
║     ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝║
║                                                                ║
║        Cross-Platform Intelligent Shell v3.0.0                 ║
║     Natural Language → Universal System Commands               ║
║   Linux • BSD • macOS • Windows • PowerShell • CMD             ║
╚════════════════════════════════════════════════════════════════╝

Detected: linux with bash shell and apt package manager

Type 'help' for commands, 'exit' to quit

turtle> show processes
# ... (displays command and prompts for execution)

Options
Flag                Description
-h, --help          Show help message
-v, --verbose       Enable verbose logging
-a, --auto          Auto-execute commands (⚠️ Dangerous!)
-i, --interactive   Launch interactive REPL (default if no query)
--history           Display recent command history
--update            Reinitialize the command database
```
For full help: ./termturtle2.sh --help

Examples

Here are some supported intents and generated commands (platform-specific):

Query                  Linux                          macOS                          Windows
"scan network"         nmap -sn 192.168.1.0/24        nmap -sn 192.168.1.0/24        nmap -sn 192.168.1.0/24
"list files in home"   ls -la $HOME                   ls -la $HOME                   dir C:\Users /a
"install git"          apt install git                brew install git               winget install Git.Git
"check disk usage"     df -h                          df -h                          wmic logicaldisk get size,freespace,caption
"kill process 1234"    kill -9 1234                   kill -9 1234                   taskkill /PID 1234 /F

See termturtle_commands.json for all supported commands and categories (reconnaissance, monitoring, system, filesystem, network, security).

Configuration

- Command Database: Edit termturtle_commands.json to add intents, platforms, or examples. Each entry includes:
  - intent: Array of natural language phrases
  - platforms: OS-specific command templates (use {param} placeholders)
  - params: Required parameters (e.g., ["target"])
  - risk: "low", "medium", or "high"
- History: Stored in .termturtle_history (local to script dir).
- Config: .termturtle_config (auto-generated; currently unused but extensible).

Run ./termturtle2.sh --update to reset the database.

Troubleshooting

- jq not found: Install as per prerequisites.
- Command not supported: Check if your platform is detected correctly (run with -v).
- Parameter prompts: For ambiguous inputs, TermTurtle will ask for details interactively.
- Windows quirks: Ensure you're running in a Bash-compatible environment (e.g., Git Bash) for full support.

Contributing

Contributions welcome! 

1. Fork the repo and create a feature branch (git checkout -b feature/amazing-feature).
2. Commit your changes (git commit -m 'Add amazing feature').
3. Push to the branch (git push origin feature/amazing-feature).
4. Open a Pull Request.

Focus areas: New commands, platform support, better NLP matching, or UI enhancements.

License

This project is licensed under the MIT License - see the LICENSE file for details.

Acknowledgments

- Built with Bash for universal compatibility.
- Inspired by tools like tldr and AI assistants like Grok.
- Thanks to the open-source community for tools like jq and nmap.

---

Star this repo if it saves you time! Questions? Open an issue at SleepTheGod/TermTurtle.
