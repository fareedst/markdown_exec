# Demo document linking

::: * This is document 3 *
::: This document is linked from another document to demonstrate code transfer.

::: This Bash block displays the value of variables "PAGE3_VAR_VIA_INHERIT" and "page3_var_via_environment"

```bash :show_vars
source bin/colorize_env_vars.sh
colorize_env_vars 'vars for page2' PAGE2_VAR_VIA_INHERIT page2_var_via_environment
colorize_env_vars 'vars for page3' PAGE3_VAR_VIA_INHERIT page3_var_via_environment
```
