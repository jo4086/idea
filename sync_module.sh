# 주석

RED='\033[1;31m'
GREEN='\033[32m'
YELLOW='\033[33m'

GREENBOLD='\033[1;32m'
YELLOWBOLD='\033[1;33m'
WHITEBOLD='\033[1;37m'
RESET='\033[0m'

ROOT_PATH=$(pwd | sed 's|/library.*||')

# 1. 안전한 디렉토리 체크
echo -e "${YELLOWBOLD}┌── 1. Checking safe directories ...${RESET}"
SAFE_REPOS=$(git config --global --get-all safe.directory | sed '/^\s*$/d' | sort) 
ALL_REPOS=$(find $(pwd | cut -d'/' -f1) -type d -name ".git" -print | sed 's|/.git||' | tr '[:lower:]' '[:upper:]' | sed 's|/|\\|g')
SAFE_REPOS_UPPER=$(echo "$SAFE_REPOS" | tr '[:lower:]' '[:upper:]')

UNSAFE_REPOS=()

for REPO in $ALL_REPOS; do
    if ! echo "$SAFE_REPOS_UPPER" | grep -q "$REPO"; then
        UNSAFE_REPOS+=("$REPO")
    fi
done

echo -e "${YELLOWBOLD}└┬[ ${RESET}${GREEN}Safe directories ${YELLOWBOLD}]${RESET}"
for REPO in $SAFE_REPOS; do
    echo -e "${YELLOWBOLD} └> ${RESET}$REPO${RESET}"
done


if [[ ${#UNSAFE_REPOS[@]} -gt 0 ]]; then
    echo -e "${YELLOWBOLD}└─┬▶ ${RED}ERROR: The following directories are unsafe:${RESET}"
    for REPO in "${UNSAFE_REPOS[@]}"; do
        echo -e "${YELLOWBOLD}  └─▶ ${RED}  - $REPO${RESET}"
    done

    exit 1
else
    echo -e "${YELLOW} >>>> ${GREEN}SUCCESS: All directories are safe.${YELLOW} <<<< ${RESET}"
fi

# 2. 서브모듈 동기화
echo -e "${YELLOWBOLD}┌───── 2. submodule update --recursive --remote ...${RESET}"
# git submodule update --recursive --remote
# git status
