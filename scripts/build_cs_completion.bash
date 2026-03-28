# Bash tab completion for scripts/build_cs
#
# Auto-loaded by env.sh (matches scripts/*_completion.bash)

_build_cs_completions() {
    local cur
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"

    # Only complete the first positional arg
    if (( COMP_CWORD > 1 )); then return 0; fi

    local script="${COMP_WORDS[0]}"
    local script_abs
    script_abs="$(command -v "$script" 2>/dev/null || echo "$script")"
    script_abs="$(realpath "$script_abs" 2>/dev/null || readlink -f "$script_abs" 2>/dev/null || echo "$script_abs")"
    local repo_root
    repo_root="$(dirname "$(dirname "$script_abs")")"
    local config_dir="$repo_root/models/cpu/configs"

    if [[ -d "$config_dir" ]]; then
        local configs
        configs=$(find "$config_dir" -name '*.json' -printf "%f\n" 2>/dev/null \
                  | sed 's/\.json$//' | sort)
        COMPREPLY=( $(compgen -W "$configs" -- "$cur") )
    fi
}

complete -F _build_cs_completions build_cs
