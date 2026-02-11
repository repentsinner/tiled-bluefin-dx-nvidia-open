#!/bin/bash
# Waybar module: show image age (fuzzy) and update availability

fuzzy_age() {
    local seconds=$1
    local minutes=$((seconds / 60))
    local hours=$((seconds / 3600))
    local days=$((seconds / 86400))
    local weeks=$((seconds / 604800))

    if [ "$minutes" -lt 1 ]; then
        echo "now"
    elif [ "$minutes" -lt 60 ]; then
        echo "${minutes}min"
    elif [ "$hours" -lt 24 ]; then
        echo "${hours}hr"
    elif [ "$days" -lt 14 ]; then
        echo "${days}d"
    else
        echo "${weeks}wk"
    fi
}

STATUS_JSON=$(rpm-ostree status --json 2>/dev/null)
if [ -z "$STATUS_JSON" ]; then
    echo '{"text": "", "tooltip": "Unable to get image status"}'
    exit 0
fi

NOW=$(date +%s)

# Booted deployment
BOOTED_VERSION=$(echo "$STATUS_JSON" | jq -r '[.deployments[] | select(.booted)][0].version // empty')
BOOTED_TS=$(echo "$STATUS_JSON" | jq -r '[.deployments[] | select(.booted)][0].timestamp // empty')
BOOTED_IMAGE=$(echo "$STATUS_JSON" | jq -r '[.deployments[] | select(.booted)][0]."container-image-reference" // empty' | sed 's/^ostree-unverified-registry://')

# Staged deployment
STAGED_VERSION=$(echo "$STATUS_JSON" | jq -r '[.deployments[] | select(.staged)][0].version // empty')
STAGED_TS=$(echo "$STATUS_JSON" | jq -r '[.deployments[] | select(.staged)][0].timestamp // empty')

# Age of booted image
AGE=""
if [ -n "$BOOTED_TS" ]; then
    AGE=$(fuzzy_age $((NOW - BOOTED_TS)))
fi

if [ -n "$STAGED_VERSION" ] && [ "$STAGED_TS" != "$BOOTED_TS" ]; then
    STAGED_AGE=$(fuzzy_age $((NOW - STAGED_TS)))
    TEXT=" ${AGE}"
    TOOLTIP="Booted: ${BOOTED_VERSION} (${AGE} ago)\nStaged: ${STAGED_VERSION} (${STAGED_AGE} ago)\nReboot to apply"
    CLASS="update-available"
else
    TEXT="${AGE}"
    TOOLTIP="Image: ${BOOTED_IMAGE}\nVersion: ${BOOTED_VERSION}\nBuilt: $(date -d @"$BOOTED_TS" '+%Y-%m-%d %H:%M' 2>/dev/null)"
    CLASS="current"
fi

echo "{\"text\": \"${TEXT}\", \"tooltip\": \"${TOOLTIP}\", \"class\": \"${CLASS}\"}"
