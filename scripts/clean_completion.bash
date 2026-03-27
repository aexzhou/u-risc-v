# Bash tab completion for scripts/clean
#
# Auto-loaded by env.sh (matches scripts/*_completion.bash)

_clean_completions() {
    local cur script repo_root rundir
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    script="${COMP_WORDS[0]}"

    # Resolve repo root: one level up from the directory containing clean
    local script_abs
    script_abs="$(command -v "$script" 2>/dev/null || echo "$script")"
    script_abs="$(realpath "$script_abs" 2>/dev/null || readlink -f "$script_abs" 2>/dev/null || echo "$script_abs")"
    repo_root="$(dirname "$(dirname "$script_abs")")"
    rundir="$repo_root/rundir"

    # Don't complete if a name argument is already present
    local i
    for (( i = 1; i < COMP_CWORD; i++ )); do
        local w="${COMP_WORDS[i]}"
        [[ "$w" == -* ]] && continue
        return 0
    done

    # Complete from rundir/ subdirectory names + "all"
    local choices="all"
    if [[ -d "$rundir" ]]; then
        local dirs
        dirs=$(find "$rundir" -mindepth 1 -maxdepth 1 -type d \
               -printf "%f\n" 2>/dev/null | sort)
        choices="all $dirs"
    fi
    COMPREPLY=( $(compgen -W "$choices" -- "$cur") )
}

complete -F _clean_completions clean
