#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd -- "$repo_dir"

if [[ $# -gt 1 ]]; then
    printf 'Usage: bash sync-main.sh [commit-message]\n' >&2
    exit 1
fi

if [[ "$(git branch --show-current)" != main ]]; then
    printf 'Switch to main before running this script.\n' >&2
    exit 1
fi

for operation in MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD rebase-merge rebase-apply; do
    if [[ -e "$(git rev-parse --git-path "$operation")" ]]; then
        printf 'Finish or abort the existing Git operation first: %s\n' "$operation" >&2
        exit 1
    fi
done

git remote get-url origin >/dev/null

if [[ -f .env ]]; then
    if ! git check-ignore -q .env || git ls-files --error-unmatch .env >/dev/null 2>&1; then
        printf '.env must be ignored and untracked before continuing.\n' >&2
        exit 1
    fi
    source ./.env
fi

if [[ -n "${GIT_USER_NAME:-}" || -n "${GIT_USER_EMAIL:-}" ]]; then
    if [[ -z "${GIT_USER_NAME:-}" || -z "${GIT_USER_EMAIL:-}" ]]; then
        printf 'Set both GIT_USER_NAME and GIT_USER_EMAIL in .env.\n' >&2
        exit 1
    fi
    git config --local user.name "$GIT_USER_NAME"
    git config --local user.email "$GIT_USER_EMAIL"
fi

if ! git var GIT_AUTHOR_IDENT >/dev/null 2>&1 || ! git var GIT_COMMITTER_IDENT >/dev/null 2>&1; then
    printf 'Set GIT_USER_NAME and GIT_USER_EMAIL in .env before running this script.\n' >&2
    exit 1
fi

if [[ -n "${GIT_USERNAME:-}" || -n "${GIT_TOKEN:-}" ]]; then
    if [[ -z "${GIT_USERNAME:-}" || -z "${GIT_TOKEN:-}" ]]; then
        printf 'Set both GIT_USERNAME and GIT_TOKEN, or leave both empty.\n' >&2
        exit 1
    fi
    export GIT_USERNAME GIT_TOKEN
    askpass_file="$(mktemp)"
    trap 'rm -f -- "$askpass_file"' EXIT
    printf '%s\n' '#!/usr/bin/env bash' \
        'case "$1" in' \
        '    *Username*) printf "%s\n" "$GIT_USERNAME" ;;' \
        '    *Password*) printf "%s\n" "$GIT_TOKEN" ;;' \
        '    *) exit 1 ;;' \
        'esac' > "$askpass_file"
    chmod 700 "$askpass_file"
    export GIT_ASKPASS="$askpass_file"
    export GIT_TERMINAL_PROMPT=0
    export GIT_CONFIG_COUNT=1
    export GIT_CONFIG_KEY_0=credential.helper
    export GIT_CONFIG_VALUE_0=''
    export LC_ALL=C
fi

git add --all
if ! git diff --cached --quiet; then
    git commit -m "${1:-Update current changes}"
else
    printf 'No local changes to commit.\n'
fi

if ! git pull --no-rebase --no-edit origin main; then
    printf 'Pull/merge failed. Resolve any conflicts and commit, or abort the merge, then rerun. Nothing was pushed.\n' >&2
    exit 1
fi

git push origin main:main