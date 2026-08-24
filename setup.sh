#!/bin/bash
# =============================================
#  FLOP Agent Kit - Linux VPS One-Command Setup
#  Runs all 4 airdrop qualification steps.
#  Usage:  bash setup.sh
# =============================================

set -euo pipefail

GREEN="\033[32m"
CYAN="\033[36m"
RED="\033[31m"
BOLD="\033[1m"
OFF="\033[0m"

echo ""
echo -e "${CYAN}${BOLD}=============================================${OFF}"
echo -e "${CYAN}${BOLD}  FLOP Agent Kit - VPS Setup                 ${OFF}"
echo -e "${CYAN}${BOLD}  \$FLOP Airdrop Qualifier (Q4 2026)         ${OFF}"
echo -e "${CYAN}${BOLD}=============================================${OFF}"
echo ""

# Check Python3 and build dependencies
if ! command -v python3 &>/dev/null || ! command -v gcc &>/dev/null; then
    echo -e "${RED}[!] Dependencies missing. Installing...${OFF}"
    sudo apt update -y && sudo apt install -y python3 python3-pip python3-dev build-essential
fi
echo -e "${GREEN}[OK] Python3: $(python3 --version)${OFF}"

# Install PyNaCl
echo -e "${CYAN}[*] Installing PyNaCl...${OFF}"
pip3 install --quiet pynacl 2>/dev/null \
  || pip3 install --quiet --break-system-packages pynacl 2>/dev/null \
  || python3 -m pip install --quiet pynacl 2>/dev/null \
  || { echo -e "${RED}[!] Could not install PyNaCl. Try: pip3 install pynacl${OFF}"; exit 1; }
echo -e "${GREEN}[OK] PyNaCl installed${OFF}"

# Setup working directory
WORKDIR="$PWD"
echo -e "${GREEN}[OK] Working directory: $WORKDIR${OFF}"

if [ ! -f "$WORKDIR/flop_agent.py" ]; then
    echo -e "${RED}[!] Error: flop_agent.py not found in the current directory.${OFF}"
    echo -e "${RED}Make sure both setup.sh and flop_agent.py are in the same folder.${OFF}"
    exit 1
fi

# Run all 4 steps
echo ""
python3 flop_agent.py run-all

echo ""
echo -e "${GREEN}${BOLD}==================================================${OFF}"
echo -e "${GREEN}${BOLD} Done! Your agent is live on Technocore.${OFF}"
echo -e "${GREEN}${BOLD} Keys saved at: $WORKDIR/agent_key.json${OFF}"
echo -e "${GREEN}${BOLD} IMPORTANT: BACKUP agent_key.json for the \$FLOP claim!${OFF}"
echo -e "${GREEN}${BOLD}==================================================${OFF}"
echo ""
echo -e "${CYAN}Next steps:${OFF}"
echo "  1. Make a useful contribution (e.g., post a guide on X)"
echo "  2. Run: python3 flop_agent.py contribute"
echo "  3. The script will guide you and generate the final X post template!"
echo ""
