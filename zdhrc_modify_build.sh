#!/usr/bin/env bash
set -euo pipefail

# Identify the correct ~/.zshrc file
ZSHRC="${1:-/etc/skel/.zshrc}"

# backup existing ~/.zshrc
cp "$ZSHRC" "$ZSHRC.bak.$(date +%Y%m%d-%H%M%S)"

# Add date_time_info() before configure_prompt(), if missing
if ! grep -q '^date_time_info()' "$ZSHRC"; then
  sed -i '/^configure_prompt()/i\
# Date time\
date_time_info() {\
    echo "$(date '\''+%Y-%m-%dT%H:%M:%S%z'\'')"\
}\
' "$ZSHRC"
fi

# Add date/time segment to the twoline PROMPT if missing
if ! grep -q '$(date_time_info)' "$ZSHRC"; then
  sed -i \
    's|)-\[%B%F{reset}%(6~|)-[%F{white}$(date_time_info)%F{%(#.blue.green)}]-[%B%F{reset}%(6~|' \
    "$ZSHRC"
fi

cat << 'EOF' >>> "$ZSHRC"
# Custom aliases
lsl = ls -l
myip = curl ifconfig.me
nmap = sudo grc nmap -g53 --randomize-hosts --script-args http.useragent="Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.71 Safari/537.36 Edge/12.0i"
upgrade = sudo apt update && sudo apt full-upgrade -y
passgen = openssl rand -base64 24
ifconfig = ip a

#Nmap NSE scripts search (add to .bashrc or .zshrc) 
nsearch() { locate *.nse | grep -o "$1".*; }
EOF