```bash :(defaults)
: ${VAULT:=default}
```
```bash :show_vars +(defaults)
source bin/colorize_env_vars.sh
colorize_env_vars '' VAULT
```
```vars :set
VAULT: 11
```
```vars :set_with_show +show_vars
VAULT: 22
```
```bash :(hidden)
colorize_env_vars '' NOTHING
```
```bash :show_with_set +set
source bin/colorize_env_vars.sh
colorize_env_vars '' VAULT
```