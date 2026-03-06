#!/usr/bin/env bash
# env.sh — set up the uriscv dev environment for the current shell session
# Usage: source env.sh

_URISCV_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Add scripts/ to PATH (idempotent)
case ":$PATH:" in
    *":$_URISCV_ROOT/scripts:"*) ;;
    *) export PATH="$_URISCV_ROOT/scripts:$PATH" ;;
esac

# Tab completions for run script
for _f in "$_URISCV_ROOT"/scripts/*_completion.bash; do
    # shellcheck source=/dev/null
    [[ -f "$_f" ]] && source "$_f"
done
unset _f

echo "uriscv env loaded  (root: $_URISCV_ROOT)"
