# Bash tab completion for scripts/run_cs
#
# Auto-loaded by env.sh (matches scripts/*_completion.bash)

_run_cs_completions() {
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

    local bin_dir="$repo_root/models/cpu/champsim/bin"
    local trace_dir="${CHAMPSIM_TRACE_DIR:-/champsim/traces}"

    # Complete option values
    case "$prev" in
        -w|--warmup-instructions|-i|--simulation-instructions)
            return 0 ;;  # numeric arg, no completion
        --json)
            COMPREPLY=( $(compgen -f -- "$cur") )
            return 0 ;;
    esac

    # Complete flags
    if [[ "$cur" == -* ]]; then
        COMPREPLY=( $(compgen -W "-w --warmup-instructions -i --simulation-instructions --hide-heartbeat --json -h --help" -- "$cur") )
        return 0
    fi

    # Count positional (non-flag) arguments before cursor
    local positional=0
    local i skip_next=0
    for (( i = 1; i < COMP_CWORD; i++ )); do
        if (( skip_next )); then skip_next=0; continue; fi
        local w="${COMP_WORDS[i]}"
        case "$w" in
            -w|--warmup-instructions|-i|--simulation-instructions|--json)
                skip_next=1; continue ;;
            --hide-heartbeat|-h|--help)
                continue ;;
            -*)
                continue ;;
            *)
                (( positional++ )) ;;
        esac
    done

    if (( positional == 0 )); then
        # Complete bin names
        if [[ -d "$bin_dir" ]]; then
            local bins
            bins=$(find "$bin_dir" -mindepth 1 -maxdepth 1 -executable \
                   -printf "%f\n" 2>/dev/null | sort)
            COMPREPLY=( $(compgen -W "$bins" -- "$cur") )
        fi
    elif (( positional == 1 )); then
        # Complete trace names
        if [[ -d "$trace_dir" ]]; then
            local traces
            traces=$(find "$trace_dir" -mindepth 1 -maxdepth 1 -type f \
                     -printf "%f\n" 2>/dev/null | sort)
            COMPREPLY=( $(compgen -W "$traces" -- "$cur") )
        fi
    fi
}

complete -F _run_cs_completions run_cs
