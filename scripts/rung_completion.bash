# Bash tab completion for scripts/rung
#
# Auto-loaded by env.sh (matches scripts/*_completion.bash)

_rung_completions() {
    local cur prev
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    local script="${COMP_WORDS[0]}"
    local script_abs
    script_abs="$(command -v "$script" 2>/dev/null || echo "$script")"
    script_abs="$(realpath "$script_abs" 2>/dev/null || readlink -f "$script_abs" 2>/dev/null || echo "$script_abs")"
    local repo_root
    repo_root="$(dirname "$(dirname "$script_abs")")"

    local config_dir="$repo_root/models/gem5/cpu"

    # Complete option values
    case "$prev" in
        --binary)
            COMPREPLY=( $(compgen -f -- "$cur") )
            return 0 ;;
        --resource)
            return 0 ;;  # free-text gem5 resource name, no completion
        -o|--outdir)
            COMPREPLY=( $(compgen -d -- "$cur") )
            return 0 ;;
    esac

    # Complete flags
    if [[ "$cur" == -* ]]; then
        COMPREPLY=( $(compgen -W "--binary --resource -o --outdir -h --help" -- "$cur") )
        return 0
    fi

    # Count positional (non-flag) arguments before cursor
    local positional=0
    local i skip_next=0
    for (( i = 1; i < COMP_CWORD; i++ )); do
        if (( skip_next )); then skip_next=0; continue; fi
        local w="${COMP_WORDS[i]}"
        case "$w" in
            --binary|--resource|-o|--outdir)
                skip_next=1; continue ;;
            -h|--help)
                continue ;;
            -*)
                continue ;;
            *)
                (( positional++ )) ;;
        esac
    done

    if (( positional == 0 )); then
        # Complete config names (strip .py extension)
        if [[ -d "$config_dir" ]]; then
            local configs
            configs=$(find "$config_dir" -maxdepth 1 -name '*.py' \
                      -printf "%f\n" 2>/dev/null | sed 's/\.py$//' | sort)
            COMPREPLY=( $(compgen -W "$configs" -- "$cur") )
        fi
    fi
}

complete -F _rung_completions rung
