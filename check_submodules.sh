#!/bin/bash

# 색상 코드 정의
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'

YELLOWBOLD='\033[1;33m'
BOLD='\033[1m'
RESET='\033[0m'

# 부모 레포지토리 경로
PARENT_REPO="/k/idea"

# 서브모듈 상태 확인
cd "$PARENT_REPO"

echo ""
echo -e "${YELLOWBOLD}==== Script Start: check_submodules.sh ====${RESET}"
echo -e "${YELLOW}└▶ Parent: Check_submodules${RESET}"
echo ""

echo -e "${BLUE}==== Checking Submodule Relationships in Parent Repository (${PARENT_REPO}) ====${RESET}"

# 1. .gitmodules 파일 확인
if [[ -f "$PARENT_REPO/.gitmodules" ]]; then
    echo -e "${GREEN}SUCCESS: .gitmodules file loaded.${RESET}"
    cat "$PARENT_REPO/.gitmodules"
else
    echo -e "${RED}ERROR: No .gitmodules file found in $PARENT_REPO${RESET}"
    exit 1
fi

echo
# 2. 서브모듈 상태 확인
echo -e "${BLUE}Submodule status:${RESET}"
git submodule status
if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}SUCCESS: Submodule status retrieved.${RESET}"
else
    echo -e "${RED}ERROR: Failed to retrieve submodule status.${RESET}"
    exit 1
fi

echo
# 3. 서브모듈 초기화 상태 확인
echo -e "${BLUE}Initializing and updating submodules...${RESET}"
git submodule init && git submodule update
if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}SUCCESS: Submodules initialized and updated.${RESET}"
else
    echo -e "${RED}ERROR: Failed to initialize or update submodules.${RESET}"
    exit 1
fi

echo
# 4. 서브모듈의 커밋 비교
echo -e "${BLUE}Submodule commit differences:${RESET}"
SUBMODULE_PATHS=$(git config --file .gitmodules --get-regexp path | awk '{print $2}')
for SUBMODULE in $SUBMODULE_PATHS; do
    echo -e "${BOLD}Checking submodule: $SUBMODULE${RESET}"
    PARENT_COMMIT=$(git ls-tree HEAD "$SUBMODULE" | awk '{print $3}')
    CURRENT_COMMIT=$(git -C "$SUBMODULE" rev-parse HEAD)

    if [[ "$PARENT_COMMIT" == "$CURRENT_COMMIT" ]]; then
        echo -e "${GREEN}SUCCESS: Submodule '$SUBMODULE' is up-to-date.${RESET}"
    else
        echo -e "${YELLOW}WARNING: Submodule '$SUBMODULE' is NOT up-to-date.${RESET}"
        echo -e "  Parent commit:  ${PARENT_COMMIT}"
        echo -e "  Current commit: ${CURRENT_COMMIT}"
    fi
    echo
done

echo -e "${GREEN}SUCCESS: Submodule check completed.${RESET}"
