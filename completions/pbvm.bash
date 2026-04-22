# pbvm bash completion
# Install: source this file from ~/.bashrc, or drop it into
# /usr/local/etc/bash_completion.d/ (Homebrew) or /etc/bash_completion.d/.

_pbvm_complete() {
  local cur prev words cword
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  local commands="install uninstall list listall use current which exec version help"

  if [[ $COMP_CWORD -eq 1 ]]; then
    COMPREPLY=( $(compgen -W "$commands" -- "$cur") )
    return 0
  fi

  case "${COMP_WORDS[1]}" in
    use|uninstall|exec)
      local root="${PBVM_ROOT:-$HOME/.pbvm}"
      local versions=""
      if [[ -d "$root/versions" ]]; then
        versions="$(ls -1 "$root/versions" 2>/dev/null \
                    | sed -n 's/^protoc-//p')"
      fi
      COMPREPLY=( $(compgen -W "$versions" -- "$cur") )
      ;;
    help)
      COMPREPLY=( $(compgen -W "$commands" -- "$cur") )
      ;;
    listall)
      COMPREPLY=( $(compgen -W "--refresh" -- "$cur") )
      ;;
  esac
}

complete -F _pbvm_complete pbvm
