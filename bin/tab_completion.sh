#!/usr/bin/env bash

__filedirs()
{
  local IFS=$'\n'
  COMPREPLY=( $(compgen -o plusdirs -f -- "${cur}") )
}

_mde() {
  local cur prev opts
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  opts="$(mde --tab-completions)"

  if [[ ${cur} == -* ]] ; then
    COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
    return 0
  fi

  __filedirs
}

complete -o filenames -F _mde mde
