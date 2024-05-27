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
  echo "2.0.6"
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
            
              --dump-delegate-object) COMPREPLY="0"; return 0 ;;
            
              --dump-blocks-in-file) COMPREPLY="0"; return 0 ;;
            
              --dump-inherited-block_names) COMPREPLY="0"; return 0 ;;
            
              --dump-inherited-dependencies) COMPREPLY="0"; return 0 ;;
            
              --dump-inherited-lines) COMPREPLY="0"; return 0 ;;
            
              --dump-menu-blocks) COMPREPLY="0"; return 0 ;;
            
              --dump-selected-block) COMPREPLY="0"; return 0 ;;
            
              --filename) COMPREPLY="."; return 0 ;;
            
              -f) COMPREPLY="."; return 0 ;;
            
              --find) COMPREPLY="''"; return 0 ;;
            
              -?) COMPREPLY="''"; return 0 ;;
            
              --find-path) COMPREPLY="''"; return 0 ;;
            
              --how) COMPREPLY="''"; return 0 ;;
            
              -?) COMPREPLY="''"; return 0 ;;
            
              --list-count) COMPREPLY="32"; return 0 ;;
            
              --load-code) COMPREPLY="''"; return 0 ;;
            
              --open) COMPREPLY="''"; return 0 ;;
            
              -o) COMPREPLY="''"; return 0 ;;
            
              --output-script) COMPREPLY="0"; return 0 ;;
            
              --output-stdout) COMPREPLY="1"; return 0 ;;
            
              --path) COMPREPLY="."; return 0 ;;
            
              -p) COMPREPLY="."; return 0 ;;
            
              --user-must-approve) COMPREPLY="0"; return 0 ;;
            
              -q) COMPREPLY="0"; return 0 ;;
            
              --display-level) COMPREPLY="1"; return 0 ;;
            
      esac
    fi
  fi

  # current word is an option name or start of
  # present matching option names
  #
  if [[ ${cur} == -* ]] ; then
    opts=("--block-name" "--config" "--debug" "--dump-delegate-object" "--dump-blocks-in-file" "--dump-inherited-block_names" "--dump-inherited-dependencies" "--dump-inherited-lines" "--dump-menu-blocks" "--dump-selected-block" "--exit" "--filename" "--find" "--find-path" "--help" "--how" "--list-blocks" "--list-count" "--list-default-env" "--list-default-yaml" "--list-docs" "--list-recent-output" "--list-recent-scripts" "--load-code" "--open" "--output-script" "--output-stdout" "--path" "--pwd" "--run-last-script" "--select-recent-output" "--select-recent-script" "--tab-completions" "--user-must-approve" "--version" "--display-level")
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
        
          --dump-delegate-object) COMPREPLY=".BOOL."; return 0 ;;
        
          --dump-blocks-in-file) COMPREPLY=".BOOL."; return 0 ;;
        
          --dump-inherited-block_names) COMPREPLY=".BOOL."; return 0 ;;
        
          --dump-inherited-dependencies) COMPREPLY=".BOOL."; return 0 ;;
        
          --dump-inherited-lines) COMPREPLY=".BOOL."; return 0 ;;
        
          --dump-menu-blocks) COMPREPLY=".BOOL."; return 0 ;;
        
          --dump-selected-block) COMPREPLY=".BOOL."; return 0 ;;
        
          --filename) COMPREPLY=".RELATIVE_PATH."; return 0 ;;
        
          -f) COMPREPLY=".RELATIVE_PATH."; return 0 ;;
        
          --find) COMPREPLY=".FIND."; return 0 ;;
        
          -?) COMPREPLY=".FIND."; return 0 ;;
        
          --find-path) COMPREPLY=".FIND_PATH."; return 0 ;;
        
          --how) COMPREPLY=".HOW."; return 0 ;;
        
          -?) COMPREPLY=".HOW."; return 0 ;;
        
          --list-count) COMPREPLY=".INT.1-."; return 0 ;;
        
          --load-code) COMPREPLY=".PATH."; return 0 ;;
        
          --open) COMPREPLY=".OPEN."; return 0 ;;
        
          -o) COMPREPLY=".OPEN."; return 0 ;;
        
          --output-script) COMPREPLY=".BOOL."; return 0 ;;
        
          --output-stdout) COMPREPLY=".BOOL."; return 0 ;;
        
          --path) COMPREPLY=".RELATIVE_PATH."; return 0 ;;
        
          -p) COMPREPLY=".RELATIVE_PATH."; return 0 ;;
        
          --user-must-approve) COMPREPLY=".BOOL."; return 0 ;;
        
          -q) COMPREPLY=".BOOL."; return 0 ;;
        
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
# echo "Updated: 2024-05-28 00:41:36 UTC"
