#!/usr/bin/env bash

__filedirs()
{
  local IFS=$'\n'
  COMPREPLY=( $(compgen -o plusdirs -f -- "${cur}") )
  # COMPREPLY=( $(compgen -d) $(compgen -f -- "${cur}") )
}

__filedirs_all()
{
  COMPREPLY='.'
}

_mde_echo_version() {
  echo "1.3.6"
}

_mde() {
  local cur prev opts
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  # printf '%s' "-;${prev}-:${cur}-"

  # current word is an option type
  # if previous word is an option name
  #   stage 2: replace with option default value
  #
  if [[ "${cur}" =~ ^\..+\.$ ]] ; then
    if [[ ${prev} == -* ]] ; then
      case $prev in
        
              --config) COMPREPLY="."; return 0 ;;
            
              --debug) COMPREPLY="0"; return 0 ;;
            
              -d) COMPREPLY="0"; return 0 ;;
            
              --filename) COMPREPLY="."; return 0 ;;
            
              -f) COMPREPLY="."; return 0 ;;
            
              --path) COMPREPLY="."; return 0 ;;
            
              -p) COMPREPLY="."; return 0 ;;
            
              --user-must-approve) COMPREPLY="1"; return 0 ;;
            
              -q) COMPREPLY="1"; return 0 ;;
            
              --list-count) COMPREPLY="32"; return 0 ;;
            
              --output-execution-summary) COMPREPLY="0"; return 0 ;;
            
              --output-script) COMPREPLY="0"; return 0 ;;
            
              --output-stdout) COMPREPLY="1"; return 0 ;;
            
              --save-executed-script) COMPREPLY="0"; return 0 ;;
            
              --save-execution-output) COMPREPLY="0"; return 0 ;;
            
              --saved-script-folder) COMPREPLY="logs"; return 0 ;;
            
              --saved-stdout-folder) COMPREPLY="logs"; return 0 ;;
            
              --display-level) COMPREPLY="1"; return 0 ;;
            
      esac
    fi
  fi

  # current word is an option name or start of
  # present matching option names
  #
  if [[ ${cur} == -* ]] ; then
    opts=("--block-name" "--config" "--debug" "--filename" "--help" "--path" "--user-must-approve" "--version" "--exit" "--list-blocks" "--list-default-env" "--list-default-yaml" "--list-docs" "--list-recent-output" "--list-recent-scripts" "--select-recent-output" "--select-recent-script" "--tab-completions" "--run-last-script" "--pwd" "--list-count" "--output-execution-summary" "--output-script" "--output-stdout" "--save-executed-script" "--save-execution-output" "--saved-script-folder" "--saved-stdout-folder" "--display-level")
    COMPREPLY=( $(compgen -W "$(printf "'%s' " "${opts[@]}")" -- "${cur}") )

    return 0
  fi

  # no current word
  # if previous word is an option name
  #   stage 1: present option type 
  #
  if [[ -z ${cur} ]] ; then
    case $prev in
      
          --block-name) COMPREPLY=".NAME."; return 0 ;;
        
          -b) COMPREPLY=".NAME."; return 0 ;;
        
          --config) COMPREPLY=".PATH."; return 0 ;;
        
          --debug) COMPREPLY=".BOOL."; return 0 ;;
        
          -d) COMPREPLY=".BOOL."; return 0 ;;
        
          --filename) COMPREPLY=".RELATIVE_PATH."; return 0 ;;
        
          -f) COMPREPLY=".RELATIVE_PATH."; return 0 ;;
        
          --path) COMPREPLY=".RELATIVE_PATH."; return 0 ;;
        
          -p) COMPREPLY=".RELATIVE_PATH."; return 0 ;;
        
          --user-must-approve) COMPREPLY=".BOOL."; return 0 ;;
        
          -q) COMPREPLY=".BOOL."; return 0 ;;
        
          --list-count) COMPREPLY=".INT.1-."; return 0 ;;
        
          --output-execution-summary) COMPREPLY=".BOOL."; return 0 ;;
        
          --output-script) COMPREPLY=".BOOL."; return 0 ;;
        
          --output-stdout) COMPREPLY=".BOOL."; return 0 ;;
        
          --save-executed-script) COMPREPLY=".BOOL."; return 0 ;;
        
          --save-execution-output) COMPREPLY=".BOOL."; return 0 ;;
        
          --saved-script-folder) COMPREPLY=".RELATIVE_PATH."; return 0 ;;
        
          --saved-stdout-folder) COMPREPLY=".RELATIVE_PATH."; return 0 ;;
        
          --display-level) COMPREPLY=".INT.0-3."; return 0 ;;
        
    esac
  fi

  # current word is unrecognized
  # present matching directory or file names
  #
  __filedirs
}

complete -o filenames -o nospace -F _mde mde
# _mde_echo_version
# echo "Updated: 2023-10-15 15:30:07 UTC"
