#!/bin/bash

# 색상 코드 정의

RED='\033[1;31m'    # 빨간색
GREEN='\033[32m'  # 초록색
CYAN='\033[36m'   # 하늘색

YELLOWBOLD='\033[1;33m'
WHITEBOLD='\033[1;37m'
RESET='\033[0m'   # 색상 초기화

# 첫 번째 스크립트: 안전 디렉토리 상태 확인
echo -e "${YELLOWBOLD}==== Script Start: check_safe_repos.sh ====${RESET}"
echo ""

echo -e "${WHITEBOLD}==== Checking Safe Directories (Existing or Missing) ====${RESET}"
SAFE_REPOS=$(git config --global --get-all safe.directory | sed '/^\s*$/d')

for SAFE_REPO in $SAFE_REPOS; do
    if [[ -d "$SAFE_REPO" ]]; then
        echo -e "${GREEN}Safe directory exists: $SAFE_REPO${RESET}"
    else
        echo -e "${RED}Safe directory missing or invalid: $SAFE_REPO${RESET}"
    fi
done

echo
echo -e "${WHITEBOLD}==== Checking Unsafe Directories ====${RESET}"

# 두 번째 스크립트: 안전하지 않은 `.git` 디렉토리만 확인
ALL_REPOS=$(find $(pwd | cut -d'/' -f1) -type d -name ".git" -print | sed 's|/.git||' | tr '[:lower:]' '[:upper:]' | sed 's|/|\\|g')
SAFE_REPOS=$(git config --global --get-all safe.directory | tr '[:lower:]' '[:upper:]')

for REPO in $ALL_REPOS; do
    if ! echo "$SAFE_REPOS" | grep -q "$REPO"; then
        echo -e "${RED}Unsafe directory: $REPO ${RESET}"
    fi
done

echo ""