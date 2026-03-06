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
        COMPREPLY=( $(compgen -W "--trace -j" -- "$cur") )
        return 0
    fi

    # Don't offer name completions if a non-flag argument is already present
    # before the current cursor position.
    local i
    for (( i = 1; i < COMP_CWORD; i++ )); do
        local w="${COMP_WORDS[i]}"
        # Skip flags and their values (-j N)
        if [[ "$w" == --trace ]]; then continue; fi
        if [[ "$w" == -j ]]; then (( i++ )); continue; fi
        if [[ "$w" == -* ]]; then continue; fi
        # A non-flag word found: name is already set, nothing more to complete
        return 0
    done

    # If the current word is a prefix of "regress_" (or already starts with it),
    # complete only regression list names so that r<TAB> -> regress_.
    if [[ "regress_" == "$cur"* || "$cur" == regress_* ]]; then
        local regressions
        regressions=$(find "$repo_root/tb" -name "regress_*.list" \
                      -printf "%f\n" 2>/dev/null \
                      | sed 's/\.list$//' \
                      | sort -u)
        COMPREPLY=( $(compgen -W "$regressions" -- "$cur") )
    else
        local tests
        tests=$(find "$repo_root/tb" \( -name "*.svh" -o -name "*.sv" \) \
                -printf "%f\n" 2>/dev/null \
                | sed 's/\.[^.]*$//' \
                | sort -u)
        COMPREPLY=( $(compgen -W "$tests" -- "$cur") )
    fi
}

complete -F _run_py_completions run
