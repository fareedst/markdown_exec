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
  echo "2.8.1"
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
            
              --debug) COMPREPLY="f"; return 0 ;;
            
              -d) COMPREPLY="f"; return 0 ;;
            
              --dump-blocks-in-file) COMPREPLY="f"; return 0 ;;
            
              --dump-delegate-object) COMPREPLY="f"; return 0 ;;
            
              --dump-dependencies) COMPREPLY="f"; return 0 ;;
            
              --dump-inherited-block-names) COMPREPLY="f"; return 0 ;;
            
              --dump-inherited-dependencies) COMPREPLY="f"; return 0 ;;
            
              --dump-inherited-lines) COMPREPLY="f"; return 0 ;;
            
              --dump-menu-blocks) COMPREPLY="f"; return 0 ;;
            
              --dump-selected-block) COMPREPLY="f"; return 0 ;;
            
              --execute-in-own-window) COMPREPLY="f"; return 0 ;;
            
              -w) COMPREPLY="f"; return 0 ;;
            
              --filename) COMPREPLY="."; return 0 ;;
            
              -f) COMPREPLY="."; return 0 ;;
            
              --find) COMPREPLY="''"; return 0 ;;
            
              -?) COMPREPLY="''"; return 0 ;;
            
              --find-path) COMPREPLY="''"; return 0 ;;
            
              --how) COMPREPLY="''"; return 0 ;;
            
              -?) COMPREPLY="''"; return 0 ;;
            
              --list-blocks-eval) COMPREPLY="''"; return 0 ;;
            
              --list-blocks-message) COMPREPLY="oname"; return 0 ;;
            
              --list-blocks-type) COMPREPLY="0"; return 0 ;;
            
              --list-count) COMPREPLY="32"; return 0 ;;
            
              --format) COMPREPLY="text"; return 0 ;;
            
              --load-code) COMPREPLY="''"; return 0 ;;
            
              -l) COMPREPLY="''"; return 0 ;;
            
              --open) COMPREPLY="''"; return 0 ;;
            
              -o) COMPREPLY="''"; return 0 ;;
            
              --output-script) COMPREPLY="f"; return 0 ;;
            
              --output-stdout) COMPREPLY="t"; return 0 ;;
            
              --path) COMPREPLY="."; return 0 ;;
            
              -p) COMPREPLY="."; return 0 ;;
            
              --pause-after-script-execution) COMPREPLY="f"; return 0 ;;
            
              --user-must-approve) COMPREPLY="f"; return 0 ;;
            
              -q) COMPREPLY="f"; return 0 ;;
            
              --display-level) COMPREPLY="1"; return 0 ;;
            
      esac
    fi
  fi

  # current word is an option name or start of
  # present matching option names
  #
  if [[ ${cur} == -* ]] ; then
    opts=("--block-name" "--config" "--debug" "--dig" "--dump-blocks-in-file" "--dump-delegate-object" "--dump-dependencies" "--dump-inherited-block-names" "--dump-inherited-dependencies" "--dump-inherited-lines" "--dump-menu-blocks" "--dump-selected-block" "--execute-in-own-window" "--exit" "--filename" "--find" "--find-path" "--help" "--history" "--how" "--list-blocks" "--list-blocks-eval" "--list-blocks-message" "--list-blocks-type" "--list-count" "--list-default-env" "--list-default-yaml" "--list-docs" "--format" "--list-recent-output" "--list-recent-scripts" "--load-code" "--mine" "--open" "--output-script" "--output-stdout" "--path" "--pause-after-script-execution" "--probe" "--publish-document-file-mode" "--publish-document-file-name" "--pwd" "--run-last-script" "--sift" "--tab-completions" "--user-must-approve" "--version" "--display-level")
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
        
          --dump-blocks-in-file) COMPREPLY=".BOOL."; return 0 ;;
        
          --dump-delegate-object) COMPREPLY=".BOOL."; return 0 ;;
        
          --dump-dependencies) COMPREPLY=".BOOL."; return 0 ;;
        
          --dump-inherited-block-names) COMPREPLY=".BOOL."; return 0 ;;
        
          --dump-inherited-dependencies) COMPREPLY=".BOOL."; return 0 ;;
        
          --dump-inherited-lines) COMPREPLY=".BOOL."; return 0 ;;
        
          --dump-menu-blocks) COMPREPLY=".BOOL."; return 0 ;;
        
          --dump-selected-block) COMPREPLY=".BOOL."; return 0 ;;
        
          --execute-in-own-window) COMPREPLY=".BOOL."; return 0 ;;
        
          -w) COMPREPLY=".BOOL."; return 0 ;;
        
          --filename) COMPREPLY=".RELATIVE_PATH."; return 0 ;;
        
          -f) COMPREPLY=".RELATIVE_PATH."; return 0 ;;
        
          --find) COMPREPLY=".FIND."; return 0 ;;
        
          -?) COMPREPLY=".FIND."; return 0 ;;
        
          --find-path) COMPREPLY=".FIND_PATH."; return 0 ;;
        
          --how) COMPREPLY=".HOW."; return 0 ;;
        
          -?) COMPREPLY=".HOW."; return 0 ;;
        
          --list-blocks-eval) COMPREPLY=".EVAL."; return 0 ;;
        
          --list-blocks-message) COMPREPLY=".MESSAGE."; return 0 ;;
        
          --list-blocks-type) COMPREPLY=".TYPE."; return 0 ;;
        
          --list-count) COMPREPLY=".INT.1-."; return 0 ;;
        
          --format) COMPREPLY=".FORMAT."; return 0 ;;
        
          --load-code) COMPREPLY=".PATH."; return 0 ;;
        
          -l) COMPREPLY=".PATH."; return 0 ;;
        
          --open) COMPREPLY=".OPEN."; return 0 ;;
        
          -o) COMPREPLY=".OPEN."; return 0 ;;
        
          --output-script) COMPREPLY=".BOOL."; return 0 ;;
        
          --output-stdout) COMPREPLY=".BOOL."; return 0 ;;
        
          --path) COMPREPLY=".RELATIVE_PATH."; return 0 ;;
        
          -p) COMPREPLY=".RELATIVE_PATH."; return 0 ;;
        
          --pause-after-script-execution) COMPREPLY=".BOOL."; return 0 ;;
        
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
