colorize_env_vars() {
  echo -e "- \033[1;32m${1}\033[0m"
  shift
  for var_name in "$@"; do
    echo -e "\033[0;33m${var_name}\033[0;31m:\033[0m ${!var_name}"
  done
}
