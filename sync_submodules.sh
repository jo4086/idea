#!/bin/bash

# 색상 코드 정의
RED='\033[1;31m'
GREEN='\033[32m'
YELLOW='\033[33m'
WHITEBOLD='\033[1;37m'
RESET='\033[0m'

# 현재 디렉토리에서 부모 디렉토리 추출
PARENT_REPO=$(pwd | sed 's|/library.*||')

# 1. 안전한 디렉토리 점검
echo -e "${YELLOW}Checking safe directories...${RESET}"
SAFE_REPOS=$(git config --global --get-all safe.directory | sed '/^\s*$/d')
ALL_REPOS=$(find $(pwd | cut -d'/' -f1) -type d -name ".git" -print | sed 's|/.git||' | tr '[:lower:]' '[:upper:]' | sed 's|/|\\|g')
SAFE_REPOS_UPPER=$(echo "$SAFE_REPOS" | tr '[:lower:]' '[:upper:]')

UNSAFE_REPOS=()

for REPO in $ALL_REPOS; do
    if ! echo "$SAFE_REPOS_UPPER" | grep -q "$REPO"; then
        UNSAFE_REPOS+=("$REPO")
    fi
done

if [[ ${#UNSAFE_REPOS[@]} -gt 0 ]]; then
    echo -e "${RED}ERROR: The following directories are unsafe:${RESET}"
    for REPO in "${UNSAFE_REPOS[@]}"; do
        echo -e "${RED}  - $REPO${RESET}"
    done

    exit 1
else
    echo -e "${GREEN}SUCCESS: All directories are safe.${RESET}"
fi

# 2. 부모 레포지토리 작업
echo -e "${YELLOW}Moving to parent repository: $PARENT_REPO${RESET}"
cd "$PARENT_REPO" || { echo -e "${RED}ERROR: Failed to access $PARENT_REPO${RESET}"; exit 1; }

echo -e "${YELLOW}Checking local changes in parent repository...${RESET}"
if [[ $(git status --porcelain) ]]; then
    echo -e "${YELLOW}Local changes detected. Committing and pushing changes...${RESET}"
    CURRENT_TIME=$(date "+%y/%m/%d, %Hh%Mm")
    git add .
    git commit -m "UpdateAT: $CURRENT_TIME | parent"
    git push origin main || { echo -e "${RED}Failed to push parent repository changes.${RESET}"; exit 1; }
else
    echo -e "${GREEN}No local changes detected in parent repository.${RESET}"
fi

echo -e "${YELLOW}Checking submodule updates in parent repository...${RESET}"
if [[ $(git status --porcelain) ]]; then
    git add library/howswift library/propStyling
    git commit -m "Update submodule references to latest commits"
    git push origin main || { echo -e "${RED}Failed to push submodule changes in parent repository.${RESET}"; exit 1; }
else
    echo -e "${GREEN}No submodule changes to commit in parent repository.${RESET}"
fi

# 3. 서브모듈 작업
git submodule foreach "
    echo -e \"${YELLOW}Processing submodule at \$sm_path...${RESET}\"

    # 변경사항 확인 및 커밋
    git add -A
    if [[ \$(git status --porcelain) ]]; then
        echo -e \"${CYAN}Local changes detected in \$sm_path. Committing and pushing...${RESET}\"
        git commit -m \"Auto-commit changes in submodule\"
        git push origin main
    else
        echo -e \"${GREEN}No changes to commit in \$sm_path.${RESET}\"
    fi

    # 서브모듈의 원본 디렉토리에서 Git pull
    ORIGINAL_PATH=\"/k/library/\${sm_path##*/}\"
    echo -e \"${YELLOW}Pulling changes in original location: \$ORIGINAL_PATH${RESET}\"
    if [[ -d \"\$ORIGINAL_PATH\" ]]; then
        cd \"\$ORIGINAL_PATH\"
        git pull --rebase || { echo -e \"${RED}Failed to pull in \$ORIGINAL_PATH.${RESET}\"; exit 1; }
        cd - > /dev/null
    else
        echo -e \"${RED}Original path \$ORIGINAL_PATH does not exist.${RESET}\"
    fi
"
