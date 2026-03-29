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

# Show git branch in prompt
_uriscv_git_branch() {
    git -C "$_URISCV_ROOT" symbolic-ref --short HEAD 2>/dev/null
}
_C_GREEN='\[\e[01;32m\]'
_C_BLUE='\[\e[01;34m\]'
_C_YELLOW='\001\e[01;33m\002'
_C_RESET='\[\e[00m\]'
_C_RESET_SUB='\001\e[00m\002'
PS1="${_C_GREEN}"'\u@\h'"${_C_RESET}"':'"${_C_BLUE}"'\w'"${_C_RESET}"'$( b=$(_uriscv_git_branch); [ -n "$b" ] && printf " '"${_C_YELLOW}"'(%s)'"${_C_RESET_SUB}"'" "$b") \$ '

export CHAMPSIM_TRACE_DIR='/champsim/traces'




echo "uriscv env loaded  (root: $_URISCV_ROOT)"
