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

# 1-1. 안전하지 않은 디렉토리 탐지
for REPO in $ALL_REPOS; do
    if ! echo "$SAFE_REPOS_UPPER" | grep -q "$REPO"; then
        UNSAFE_REPOS+=("$REPO")
    fi
done

# 1-2. 안전하지 않은 디렉토리가 있을 경우 처리
if [[ ${#UNSAFE_REPOS[@]} -gt 0 ]]; then
    echo -e "${RED}ERROR: The following directories are unsafe:${RESET}"
    for REPO in "${UNSAFE_REPOS[@]}"; do
        echo -e "${RED}  - $REPO${RESET}"
    done

    echo -e "${WHITEBOLD}To fix this, add these directories to safe.directory:${RESET}"
    for REPO in "${UNSAFE_REPOS[@]}"; do
        echo "git config --global --add safe.directory $REPO"
    done

    exit 1
else
    echo -e "${GREEN}SUCCESS: All directories are safe.${RESET}"
fi

# 2. 부모 디렉토리 이동
echo -e "${YELLOW}Moving to parent repository: $PARENT_REPO${RESET}"
cd "$PARENT_REPO" || { echo -e "${RED}ERROR: Failed to access $PARENT_REPO${RESET}"; exit 1; }

# 3. 로컬 변경사항 확인
echo -e "${YELLOW}Checking local changes...${RESET}"
if [[ $(git status --porcelain) ]]; then
    echo -e "${YELLOW}Local changes detected. Committing and pushing changes...${RESET}"
    
    # 3-1. 변경사항 커밋 및 푸쉬
    CURRENT_TIME=$(date "+%y/%m/%d, %Hh%Mm")
    REPO_TYPE="parent"
    COMMIT_MESSAGE="UpdateAT: $CURRENT_TIME | $REPO_TYPE"

    git add .
    git commit -m "$COMMIT_MESSAGE"
    git push origin main
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}ERROR: Failed to push changes to remote.${RESET}"
        exit 1
    fi

    echo -e "${GREEN}SUCCESS: Local changes pushed to remote.${RESET}"
else
    echo -e "${GREEN}No local changes detected.${RESET}"
fi

# 4. 서브모듈 업데이트 및 원본 위치 동기화
echo -e "${YELLOW}Updating submodules and original directories...${RESET}"
git submodule update --remote --recursive

# 서브모듈에서 변경사항 확인 및 커밋/푸쉬
git submodule foreach '
    echo -e "${YELLOW}Processing submodule at $sm_path...${RESET}"
    git add .gitattributes
    if [[ $(git status --porcelain) ]]; then
        echo -e "${CYAN}Local changes detected in $sm_path. Committing and pushing...${RESET}"
        git commit -m "Add .gitattributes for consistent line endings"
        git push origin main
    else
        echo -e "${GREEN}No changes to commit in $sm_path.${RESET}"
    fi

    # 서브모듈의 원본 디렉토리에서 Git pull
    ORIGINAL_PATH="/k/library/${sm_path##*/}"
    echo -e "${YELLOW}Pulling changes in original location: $ORIGINAL_PATH${RESET}"
    if [[ -d "$ORIGINAL_PATH" ]]; then
        cd "$ORIGINAL_PATH"
        git pull --rebase || { echo -e "${RED}Failed to pull in $ORIGINAL_PATH.${RESET}"; exit 1; }
        cd - > /dev/null
    else
        echo -e "${RED}Original path $ORIGINAL_PATH does not exist.${RESET}"
    fi
'