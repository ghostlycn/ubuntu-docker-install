#!/bin/bash

# Color & Icon Setting
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m'
ICON_SUCCESS="✔"
ICON_FAIL="✘"

trap 'on_interrupt' INT
on_interrupt() {
  echo -e "\n${RED}🚫 Has been canceled.${NC}"
  exit 130
}

# Task List & Command
STEPS=(
  "System Package Update:sudo apt update"
  "Package Install:sudo apt install -y apt-transport-https ca-certificates curl software-properties-common"
  "Add Docker GPG Key:curl -fsSl https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -"
  "Add Docker Repo:sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable\""
  "Update After Repo Add:sudo apt update"
  "Docker Install:sudo apt install -y docker-ce"
  "Automatically Activates System Reboot:sudo systemctl enable docker"
  "Remove Old Docker Compose:[ -f /usr/local/bin/docker-compose ] && sudo rm -f /usr/local/bin/docker-compose || true"
  "Latest Install Docker Compose:sudo curl -L \"https://github.com/docker/compose/releases/download/\$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -Po '\"tag_name\": \"\\K.*?(?=\")')/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose"
  "Make Docker Compose Executable:sudo chmod +x /usr/local/bin/docker-compose"
  "Setting Up Symbolic Links:sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose"
  "Create Docker Group:sudo groupadd docker || true"
  "Add User to Group:sudo usermod -aG docker $USER"
)

CURRENT_STEP=0
TOTAL_STEPS=${#STEPS[@]}
MAX_DESC_LEN=0

# Max Len
for s in "${STEPS[@]}"; do
  desc="${s%%:*}"
  [ ${#desc} -gt $MAX_DESC_LEN ] && MAX_DESC_LEN=${#desc}
done

pad_right() {
  printf "%-${2}s" "$1"
}

spinner() {
  local pid=$1
  local delay=0.1
  local spinstr='|/-\\'
  while kill -0 "$pid" 2>/dev/null; do
    local temp=${spinstr#?}
    printf "\r[%-1s/%-1s] %s [%c] " "$CURRENT_STEP" "$TOTAL_STEPS" "$(pad_right "$DESC" $MAX_DESC_LEN)" "$spinstr"
    spinstr=$temp${spinstr%"$temp"}
    sleep $delay
  done
}

start() {
  CURRENT_STEP=$((CURRENT_STEP + 1))
  DESC="$1"
  CMD="$2"
  ERR_FILE=$(mktemp)

  bash -c "$CMD" >/dev/null 2>"$ERR_FILE" &
  CMD_PID=$!
  spinner $CMD_PID
  wait $CMD_PID
  STATUS=$?
  printf "\r\033[K"

  if [ $STATUS -eq 0 ]; then
    printf "[%-1s/%-1s] %s [%b] %b\n" "$CURRENT_STEP" "$TOTAL_STEPS" "$(pad_right "$DESC" $MAX_DESC_LEN)" "${GREEN}$ICON_SUCCESS${NC}" "${GREEN}SUCCESS${NC}"
  else
    printf "[%-1s/%-1s] %s [%b] %b\n" "$CURRENT_STEP" "$TOTAL_STEPS" "$(pad_right "$DESC" $MAX_DESC_LEN)" "${RED}$ICON_FAIL${NC}" "${RED}FAIL${NC}"
    cat "$ERR_FILE"
    rm -f "$ERR_FILE"
    exit 1
  fi

  rm -f "$ERR_FILE"
}

# Main Start
for step_entry in "${STEPS[@]}"; do
  desc="${step_entry%%:*}"
  cmd="${step_entry#*:}"
  start "$desc" "$cmd"
done

echo -e "\n${GREEN}✅ All tasks are complete. You may need to logout/login to apply new group permissions.${NC}"
