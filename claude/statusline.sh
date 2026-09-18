#!/bin/bash
input=$(cat)

# Single jq call to extract all fields
eval "$(echo "$input" | jq -r '
  @sh "MODEL=\(.model.display_name)",
  @sh "DIR=\(.workspace.current_dir)",
  @sh "COST=\(.cost.total_cost_usd // 0)",
  @sh "PCT_RAW=\(.context_window.used_percentage // 0)",
  @sh "DURATION_MS=\(.cost.total_duration_ms // 0)",
  @sh "TOKENS_INPUT=\(.context_window.total_input_tokens // 0)",
  @sh "TOKENS_OUTPUT=\(.context_window.total_output_tokens // 0)",
  @sh "TOKENS_MAX=\(.context_window.context_window_size // 0)"
')"
PCT=${PCT_RAW%%.*}

CYAN='\033[36m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; RESET='\033[0m'

# Pick bar color based on context usage
if [ "$PCT" -ge 90 ]; then BAR_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then BAR_COLOR="$YELLOW"
else BAR_COLOR="$GREEN"; fi

FILLED=$((PCT / 10)); EMPTY=$((10 - FILLED))
printf -v FILL "%${FILLED}s"; printf -v PAD "%${EMPTY}s"
BAR="${FILL// /█}${PAD// /░}"

# Format token counts as compact "45k/200k"
format_tokens() {
    local t=$1
    if [ "$t" -ge 1000000 ]; then
        printf '%.1fM' "$(echo "$t / 1000000" | bc -l)"
    elif [ "$t" -ge 1000 ]; then
        printf '%dk' "$((t / 1000))"
    else
        printf '%d' "$t"
    fi
}
TOKENS_USED=$((TOKENS_INPUT + TOKENS_OUTPUT))
TOKENS_DISPLAY="$(format_tokens "$TOKENS_USED")/$(format_tokens "$TOKENS_MAX")"

MINS=$((DURATION_MS / 60000)); SECS=$(((DURATION_MS % 60000) / 1000))

BRANCH_LINK=""
if git -C "$DIR" rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH_NAME=$(git -C "$DIR" branch --show-current 2>/dev/null)
    # Detached HEAD: show short SHA instead
    if [ -z "$BRANCH_NAME" ]; then
        BRANCH_NAME=$(git -C "$DIR" rev-parse --short HEAD 2>/dev/null)
        BRANCH_ICON="🔖"
    else
        BRANCH_ICON="🌿"
    fi
    # Dirty indicator
    DIRTY=""
    if ! git -C "$DIR" diff --quiet HEAD 2>/dev/null || \
       [ -n "$(git -C "$DIR" ls-files --others --exclude-standard 2>/dev/null | head -1)" ]; then
        DIRTY=" ●"
    fi
    REMOTE_URL=$(git -C "$DIR" remote get-url origin 2>/dev/null)
    if [ -n "$BRANCH_NAME" ] && [ -n "$REMOTE_URL" ]; then
        GH_URL=$(echo "$REMOTE_URL" | sed -E 's|^git@github\.com:|https://github.com/|; s|\.git$||; s|^https://github\.com/|https://github.com/|')
        BRANCH_LINK=" | \033]8;;${GH_URL}/tree/${BRANCH_NAME}\033\\${BRANCH_ICON} ${BRANCH_NAME}${DIRTY}\033]8;;\033\\"
    elif [ -n "$BRANCH_NAME" ]; then
        BRANCH_LINK=" | ${BRANCH_ICON} ${BRANCH_NAME}${DIRTY}"
    fi
fi

echo -e "${CYAN}[$MODEL]${RESET} 📁 ${DIR##*/}${BRANCH_LINK}"
COST_FMT=$(printf '$%.2f' "$COST")
echo -e "${BAR_COLOR}${BAR}${RESET} ${PCT}% (${TOKENS_DISPLAY}) | ${YELLOW}${COST_FMT}${RESET} | ⏱️ ${MINS}m ${SECS}s"
