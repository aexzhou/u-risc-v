# Bash tab completion for scripts/run.py
#
# To activate (add one of these to your ~/.bashrc):
#   source /path/to/uriscv/scripts/run_completion.bash
# Or for auto-load in the repo:
#   source scripts/run_completion.bash

_run_py_completions() {
    local cur script repo_root
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    script="${COMP_WORDS[0]}"

    # Resolve repo root: one level up from the directory containing run
    local script_abs
    script_abs="$(command -v "$script" 2>/dev/null || echo "$script")"
    script_abs="$(realpath "$script_abs" 2>/dev/null || readlink -f "$script_abs" 2>/dev/null || echo "$script_abs")"
    repo_root="$(dirname "$(dirname "$script_abs")")"

    [[ -d "$repo_root/tb" ]] || return 0

    # Complete flags
    if [[ "$cur" == -* ]]; then
        COMPREPLY=( $(compgen -W "--trace" -- "$cur") )
        return 0
    fi

    # Collect testnames from all .svh and .sv files under tb/
    local tests
    tests=$(find "$repo_root/tb" \( -name "*.svh" -o -name "*.sv" \) \
            -printf "%f\n" 2>/dev/null \
            | sed 's/\.[^.]*$//' \
            | sort -u)

    COMPREPLY=( $(compgen -W "$tests" -- "$cur") )
}

complete -F _run_py_completions run
