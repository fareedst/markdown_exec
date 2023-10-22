```bash :show_vars
source bin/colorize_env_vars.sh
colorize_env_vars '' STORE1
```

```vars :vars1
STORE1: 11
```

```vars :vars2 +show_vars
STORE1: 22
```

```bash :show_vars_v1 +vars1
source bin/colorize_env_vars.sh
colorize_env_vars '' STORE1
```
