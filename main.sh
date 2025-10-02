#!/bin/bash

# TermTurtle - Intelligent Shell Front-End
# Translates natural language intent into precise Linux commands
# Designed for security professionals and system administrators
#
# Author: TermTurtle Project
# Version: 2.1.0
# License: MIT

set -euo pipefail

# Colors and formatting
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly NC='\033[0m' # No Color

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_FILE="${SCRIPT_DIR}/.termturtle_config"
readonly HISTORY_FILE="${SCRIPT_DIR}/.termturtle_history"
readonly COMMAND_DB="${SCRIPT_DIR}/termturtle_commands.json"

# Global variables
declare -g INTERACTIVE_MODE=true
declare -g VERBOSE_MODE=false
declare -g AUTO_EXECUTE=false
declare -g LEARNING_MODE=true

# ASCII Art Banner
show_banner() {
    echo -e "${CYAN}${BOLD}"
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════╗
║  ████████╗███████╗██████╗ ███╗   ███╗████████╗██╗   ██╗██████╗ ║
║  ╚══██╔══╝██╔════╝██╔══██╗████╗ ████║╚══██╔══╝██║   ██║██╔══██╗║
║     ██║   █████╗  ██████╔╝██╔████╔██║   ██║   ██║   ██║██████╔╝║
║     ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║   ██║   ██║   ██║██╔══██╗║
║     ██║   ███████╗██║  ██║██║ ╚═╝ ██║   ██║   ╚██████╔╝██║  ██║║
║     ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝║
║            v 1.0 By Taylor Christian Newsome                   ║
║           Intelligent Shell Front-End v2.1.0                   ║
║        Natural Language → Precise Linux Commands               ║
╚════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

# Initialize command database
init_command_db() {
    if [[ ! -f "$COMMAND_DB" ]]; then
        log_info "Initializing command database..."
        cat > "$COMMAND_DB" << 'EOF'
{
  "commands": [
    {
      "intent": ["scan network", "network scan", "discover hosts", "find devices"],
      "command": "nmap -sn {network}",
      "description": "Discover live hosts on network",
      "category": "reconnaissance",
      "risk": "low",
      "params": ["network"],
      "examples": ["nmap -sn 192.168.1.0/24"]
    },
    {
      "intent": ["port scan", "scan ports", "check open ports"],
      "command": "nmap -sS -O {target}",
      "description": "TCP SYN scan with OS detection",
      "category": "reconnaissance",
      "risk": "medium",
      "params": ["target"],
      "examples": ["nmap -sS -O 192.168.1.100"]
    },
    {
      "intent": ["check listening ports", "show open ports", "netstat ports"],
      "command": "ss -tulpn",
      "description": "Show listening ports and processes",
      "category": "system",
      "risk": "low",
      "params": [],
      "examples": ["ss -tulpn"]
    },
    {
      "intent": ["monitor network traffic", "capture packets", "sniff traffic"],
      "command": "tcpdump -i {interface} -w {output}.pcap",
      "description": "Capture network packets to file",
      "category": "monitoring",
      "risk": "medium",
      "params": ["interface", "output"],
      "examples": ["tcpdump -i eth0 -w capture.pcap"]
    },
    {
      "intent": ["find files", "search files", "locate file"],
      "command": "find {path} -name '*{pattern}*' -type f",
      "description": "Search for files by name pattern",
      "category": "filesystem",
      "risk": "low",
      "params": ["path", "pattern"],
      "examples": ["find /home -name '*.log' -type f"]
    },
    {
      "intent": ["check disk usage", "disk space", "df"],
      "command": "df -h",
      "description": "Show filesystem disk space usage",
      "category": "system",
      "risk": "low",
      "params": [],
      "examples": ["df -h"]
    },
    {
      "intent": ["show processes", "list processes", "ps"],
      "command": "ps aux --sort=-%cpu | head -20",
      "description": "Show top CPU-consuming processes",
      "category": "system",
      "risk": "low",
      "params": [],
      "examples": ["ps aux --sort=-%cpu | head -20"]
    },
    {
      "intent": ["check system logs", "view logs", "journalctl"],
      "command": "journalctl -f --since '{timeframe}'",
      "description": "Follow system logs from timeframe",
      "category": "monitoring",
      "risk": "low",
      "params": ["timeframe"],
      "examples": ["journalctl -f --since '1 hour ago'"]
    },
    {
      "intent": ["firewall status", "check firewall", "ufw status"],
      "command": "ufw status verbose",
      "description": "Show detailed firewall status",
      "category": "security",
      "risk": "low",
      "params": [],
      "examples": ["ufw status verbose"]
    },
    {
      "intent": ["check connections", "active connections", "netstat"],
      "command": "ss -tuln",
      "description": "Show active network connections",
      "category": "network",
      "risk": "low",
      "params": [],
      "examples": ["ss -tuln"]
    }
  ]
}
EOF
        log_success "Command database initialized"
    fi
}

# Parse natural language input
parse_intent() {
    local input="$1"
    local best_match=""
    local best_score=0
    local matched_command=""

    # Convert input to lowercase for matching
    input=$(echo "$input" | tr '[:upper:]' '[:lower:]')

    # Parse JSON and find best match
    while IFS= read -r line; do
        local intent_array=$(echo "$line" | jq -r '.intent[]')
        local command=$(echo "$line" | jq -r '.command')
        local description=$(echo "$line" | jq -r '.description')
        local category=$(echo "$line" | jq -r '.category')
        local risk=$(echo "$line" | jq -r '.risk')

        # Calculate match score
        local score=0
        while IFS= read -r intent; do
            if [[ "$input" == *"$intent"* ]]; then
                score=$((score + ${#intent}))
            fi
        done <<< "$intent_array"

        if [[ $score -gt $best_score ]]; then
            best_score=$score
            best_match="$line"
            matched_command="$command"
        fi
    done < <(jq -c '.commands[]' "$COMMAND_DB")

    if [[ $best_score -gt 0 ]]; then
        echo "$best_match"
        return 0
    else
        return 1
    fi
}

# Extract parameters from user input
extract_parameters() {
    local input="$1"
    local command_template="$2"
    local params_json="$3"

    local final_command="$command_template"

    # Extract parameters based on common patterns
    while IFS= read -r param; do
        case "$param" in
            "network")
                if [[ "$input" =~ ([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}) ]]; then
                    final_command="${final_command//\{network\}/${BASH_REMATCH[1]}}"
                else
                    final_command="${final_command//\{network\}/192.168.1.0\/24}"
                fi
                ;;
            "target")
                if [[ "$input" =~ ([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}) ]]; then
                    final_command="${final_command//\{target\}/${BASH_REMATCH[1]}}"
                else
                    read -p "Enter target IP/hostname: " target
                    final_command="${final_command//\{target\}/$target}"
                fi
                ;;
            "interface")
                if [[ "$input" =~ (eth[0-9]+|wlan[0-9]+|enp[0-9]+s[0-9]+) ]]; then
                    final_command="${final_command//\{interface\}/${BASH_REMATCH[1]}}"
                else
                    final_command="${final_command//\{interface\}/eth0}"
                fi
                ;;
            "path")
                if [[ "$input" =~ (/[a-zA-Z0-9/_-]+) ]]; then
                    final_command="${final_command//\{path\}/${BASH_REMATCH[1]}}"
                else
                    final_command="${final_command//\{path\}/\/home}"
                fi
                ;;
            "pattern")
                if [[ "$input" =~ \*([a-zA-Z0-9._-]+)\* ]]; then
                    final_command="${final_command//\{pattern\}/${BASH_REMATCH[1]}}"
                else
                    read -p "Enter search pattern: " pattern
                    final_command="${final_command//\{pattern\}/$pattern}"
                fi
                ;;
            "output")
                final_command="${final_command//\{output\}/capture_$(date +%Y%m%d_%H%M%S)}"
                ;;
            "timeframe")
                final_command="${final_command//\{timeframe\}/1 hour ago}"
                ;;
        esac
    done < <(echo "$params_json" | jq -r '.[]')

    echo "$final_command"
}

# Display command with syntax highlighting
display_command() {
    local command="$1"
    local description="$2"
    local category="$3"
    local risk="$4"

    echo -e "\n${BOLD}${WHITE}╭─ Command Match Found${NC}"
    echo -e "${BOLD}${WHITE}│${NC}"
    echo -e "${BOLD}${WHITE}├─ Description:${NC} ${CYAN}$description${NC}"
    echo -e "${BOLD}${WHITE}├─ Category:${NC} ${PURPLE}$category${NC}"

    # Risk color coding
    local risk_color="$GREEN"
    [[ "$risk" == "medium" ]] && risk_color="$YELLOW"
    [[ "$risk" == "high" ]] && risk_color="$RED"

    echo -e "${BOLD}${WHITE}├─ Risk Level:${NC} ${risk_color}$risk${NC}"
    echo -e "${BOLD}${WHITE}│${NC}"
    echo -e "${BOLD}${WHITE}├─ Command:${NC}"
    echo -e "${BOLD}${WHITE}│${NC}   ${GREEN}$command${NC}"
    echo -e "${BOLD}${WHITE}╰─${NC}"
}

# Execute command with confirmation
execute_command() {
    local command="$1"
    local risk="$2"

    if [[ "$AUTO_EXECUTE" == "true" ]]; then
        log_info "Auto-executing command..."
        eval "$command"
        return $?
    fi

    echo -e "\n${YELLOW}Execute this command? ${NC}"
    echo -e "${DIM}[y]es / [n]o / [c]opy to clipboard / [e]dit${NC}"

    read -n 1 -r response
    echo

    case "$response" in
        y|Y)
            log_info "Executing command..."
            echo -e "${DIM}$ $command${NC}"
            eval "$command"
            local exit_code=$?
            if [[ $exit_code -eq 0 ]]; then
                log_success "Command completed successfully"
            else
                log_error "Command failed with exit code $exit_code"
            fi
            return $exit_code
            ;;
        c|C)
            echo -n "$command" | xclip -selection clipboard 2>/dev/null || \
            echo -n "$command" | pbcopy 2>/dev/null || \
            log_warn "Could not copy to clipboard (xclip/pbcopy not available)"
            log_info "Command copied to clipboard"
            ;;
        e|E)
            echo -e "${CYAN}Edit command:${NC}"
            read -e -i "$command" edited_command
            if [[ -n "$edited_command" ]]; then
                execute_command "$edited_command" "$risk"
            fi
            ;;
        *)
            log_info "Command execution cancelled"
            ;;
    esac
}

# Add command to history
add_to_history() {
    local input="$1"
    local command="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $input | $command" >> "$HISTORY_FILE"
}

# Show usage help
show_help() {
    echo -e "${BOLD}${WHITE}TermTurtle - Intelligent Shell Front-End${NC}\n"
    echo -e "${CYAN}USAGE:${NC}"
    echo -e "  $0 [OPTIONS] [QUERY]"
    echo -e ""
    echo -e "${CYAN}OPTIONS:${NC}"
    echo -e "  -h, --help          Show this help message"
    echo -e "  -v, --verbose       Enable verbose output"
    echo -e "  -a, --auto          Auto-execute commands (dangerous!)"
    echo -e "  -i, --interactive   Interactive mode (default)"
    echo -e "  --history          Show command history"
    echo -e "  --update           Update command database"
    echo -e ""
    echo -e "${CYAN}EXAMPLES:${NC}"
    echo -e "  $0 \"scan network for devices\""
    echo -e "  $0 \"check open ports on 192.168.1.100\""
    echo -e "  $0 \"find log files in /var/log\""
    echo -e "  $0 \"monitor network traffic on eth0\""
    echo -e ""
    echo -e "${CYAN}CATEGORIES:${NC}"
    echo -e "  ${PURPLE}reconnaissance${NC} - Network scanning and discovery"
    echo -e "  ${PURPLE}monitoring${NC}     - System and network monitoring"
    echo -e "  ${PURPLE}security${NC}       - Security-related commands"
    echo -e "  ${PURPLE}system${NC}         - System administration"
    echo -e "  ${PURPLE}filesystem${NC}     - File and directory operations"
    echo -e "  ${PURPLE}network${NC}        - Network configuration and status"
}

# Interactive mode
interactive_mode() {
    show_banner
    echo -e "${DIM}Type 'help' for commands, 'exit' to quit${NC}\n"

    while true; do
        echo -e -n "${BOLD}${CYAN}turtle>${NC} "
        read -r input

        case "$input" in
            "exit"|"quit"|"q")
                echo -e "${GREEN}Goodbye!${NC}"
                break
                ;;
            "help"|"h")
                show_help
                ;;
            "history")
                if [[ -f "$HISTORY_FILE" ]]; then
                    echo -e "${CYAN}Command History:${NC}"
                    tail -20 "$HISTORY_FILE" | while IFS='|' read -r timestamp query command; do
                        echo -e "${DIM}$timestamp${NC} ${YELLOW}$query${NC} → ${GREEN}$command${NC}"
                    done
                else
                    log_info "No history available"
                fi
                ;;
            "clear")
                clear
                show_banner
                ;;
            "")
                continue
                ;;
            *)
                process_query "$input"
                ;;
        esac
        echo
    done
}

# Process natural language query
process_query() {
    local query="$1"

    if [[ "$VERBOSE_MODE" == "true" ]]; then
        log_info "Processing query: '$query'"
    fi

    local match_result
    if match_result=$(parse_intent "$query"); then
        local command_template=$(echo "$match_result" | jq -r '.command')
        local description=$(echo "$match_result" | jq -r '.description')
        local category=$(echo "$match_result" | jq -r '.category')
        local risk=$(echo "$match_result" | jq -r '.risk')
        local params=$(echo "$match_result" | jq -c '.params')

        local final_command
        final_command=$(extract_parameters "$query" "$command_template" "$params")

        display_command "$final_command" "$description" "$category" "$risk"

        if [[ "$INTERACTIVE_MODE" == "true" ]]; then
            execute_command "$final_command" "$risk"
        else
            echo -e "\n${GREEN}$final_command${NC}"
        fi

        add_to_history "$query" "$final_command"
    else
        log_error "No matching command found for: '$query'"
        echo -e "${DIM}Try rephrasing your request or use 'help' for examples${NC}"
        return 1
    fi
}

# Main function
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE_MODE=true
                shift
                ;;
            -a|--auto)
                AUTO_EXECUTE=true
                log_warn "Auto-execute mode enabled - commands will run without confirmation!"
                shift
                ;;
            -i|--interactive)
                INTERACTIVE_MODE=true
                shift
                ;;
            --history)
                if [[ -f "$HISTORY_FILE" ]]; then
                    cat "$HISTORY_FILE"
                else
                    log_info "No history available"
                fi
                exit 0
                ;;
            --update)
                log_info "Updating command database..."
                rm -f "$COMMAND_DB"
                init_command_db
                log_success "Command database updated"
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                # Remaining arguments are the query
                INTERACTIVE_MODE=false
                process_query "$*"
                exit $?
                ;;
        esac
    done

    # Check dependencies
    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not installed. Please install jq to continue."
        exit 1
    fi

    # Initialize
    init_command_db

    # Start interactive mode if no query provided
    if [[ "$INTERACTIVE_MODE" == "true" ]]; then
        interactive_mode
    else
        show_help
    fi
}

# Trap signals for clean exit
trap 'echo -e "\n${YELLOW}Interrupted${NC}"; exit 130' INT TERM

# Run main function
main "$@"
