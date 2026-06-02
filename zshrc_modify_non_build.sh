#!/usr/bin/env bash
set -euo pipefail

# Horizontal rule function
hr() {
    printf '%*s\n' "${COLUMNS:-80}" '' | tr ' ' '-'
}

# Custome alias section helper variables and function
CUSTOM_ALIAS_START="# BEGIN CUSTOM ALIASES"
CUSTOM_ALIAS_END="# END CUSTOM ALIASES"

ensure_custom_alias_section() {
  if ! grep -qFx "$CUSTOM_ALIAS_START" "$ZSHRC"; then
    cat << EOF >> "$ZSHRC"

$CUSTOM_ALIAS_START

$CUSTOM_ALIAS_END
EOF
  fi
}

# Identify the correct ~/.zshrc file
ZSHRC="${1:-$HOME/.zshrc}"

# backup existing ~/.zshrc
echo "Backing up existing ~/.zdhrc file."
cp "$ZSHRC" "$ZSHRC.bak.$(date +%Y%m%d-%H%M%S)"

# Add date_time_info() before configure_prompt(), if missing
echo "Adding date_time_info() function to ~/.zshrc ."
if ! grep -q '^date_time_info()' "$ZSHRC"; then
  sed -i '/^configure_prompt()/i\
# Date time\
date_time_info() {\
    echo "$(date '\''+%Y-%m-%dT%H:%M:%S%z'\'')"\
}\
' "$ZSHRC"
fi

# Add date/time segment to the twoline PROMPT if missing
echo "Adding date/time segment to prompt."
if ! grep -q '$(date_time_info)' "$ZSHRC"; then
  sed -i \
    's|)-\[%B%F{reset}%(6~|)-[%F{white}$(date_time_info)%F{%(#.blue.green)}]-[%B%F{reset}%(6~|' \
    "$ZSHRC"
fi

# Check for, and add, custom alias section for management
ensure_custom_alias_section

# add_alias function
add_alias() {
  local alias_name="$1"
  local alias_value="$2"
  if ! grep -qE "^[[:space:]]*alias[[:space:]]+$alias_name=" "$ZSHRC"; then
    echo "Alias not found in ~/.zshrc, adding..."
    sed -i "/^# END CUSTOM ALIASES$/i alias $alias_name='$alias_value'" "$ZSHRC"
  else
    echo "Alias already exists."
  fi
}

# Add some custom aliases for specific packages

# Function to initiate alias adding
# First get alias name and value, and pass it to add_alias()
# This was kept separate so that the add_alias() function could be used outside of
# this process. Additionally, this will check based on command pressence, too.
process_alias() {
  local alias_name="$1"
  local alias_value="$2"
  local alias_dependency="$3"
  echo "Checking if command <$alias_dependency> is present for alias: <$alias_name = $alias_value>"
  if command -v "$alias_dependency" > /dev/null 2>&1; then
    echo "<$alias_dependency> appears to be present."
    # Specifically remove the ll alias, if it exists and lsd is present.
    if [[ "$alias_name" == "ll" ]]; then
      echo "Existing alias for <ll> found. Removing."
      sed -i "/^[[:space:]]*alias[[:space:]]\+ll=/d" "$ZSHRC"
    fi
    add_alias "$alias_name" "$alias_value"
  else
    echo "Command <$alias_dependency> appears not to be present. Skipping alias."
  fi
}

# Add some additional custom aliases that have no dependencies
echo "Adding custom aliases"
declare -A aliases=(  
[lsl]="ls -l"
[myip]="curl ifconfig.me"  
[nmap]="sudo grc nmap -g53 --randomize-hosts --script-args http.useragent=\"Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.71 Safari/537.36 Edge/12.0i"  
[grep]="grep --color=auto"
[upgrade]="sudo apt update && sudo apt full-upgrade -y"
[passgen]="openssl rand -base64 24"
[ifconfig]="ip a"

)

for alias_name in "${!aliases[@]}"; do
add_alias "$alias_name" "${aliases[$alias_name]}"
done

# Array of conditional aliases
declare -A conditional_alias_values=(
  [ll]="lsd -la --group-dirs first"
  [tree]="lsd --tree"
  [cat]="batcat"
)

# Array of conditiona aliases and associated command dependency
declare -A conditional_alias_deps=(
  [ll]="lsd"
  [tree]="lsd"
  [cat]="batcat"
)

# Go through and add conditional_aliases
for alias_name in "${!conditional_alias_values[@]}"; do
  printf "\n"
  process_alias "$alias_name" "${conditional_alias_values[$alias_name]}" "${conditional_alias_deps[$alias_name]}"
  hr
  printf "\n"
done

# Add NSE script search
echo "Adding NSE script search to ~/.zshrc ."
if ! grep -qE '^nsearch[[:space:]]*\(\)' "$ZSHRC"; then
cat << 'EOF' >> "$ZSHRC"

# Nmap NSE scripts search  
nsearch() {
locate '*.nse' | grep -o "$1".*
}
EOF
fi