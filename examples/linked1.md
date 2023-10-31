# Demo document linking

::: * This is document 1 *
::: This document links to a matching document to demonstrate navigation between documents.

::: This Bash block displays the value of variables "page1_var_via_environment" and "page2_var_via_environment"

```bash :show_vars
source bin/colorize_env_vars.sh
colorize_env_vars 'vars for page2' PAGE2_VAR_VIA_INHERIT page2_var_via_environment
colorize_env_vars 'vars for page3' PAGE3_VAR_VIA_INHERIT page3_var_via_environment
```

::: This Link block
::: 1. requires a block that sets environment variable PAGE2_VAR_VIA_INHERIT,
::: 2. navigates to document 2, and
::: 3. executes block "show_vars" to display the imported PAGE2_VAR_VIA_INHERIT.

```bash :(vars2)
PAGE2_VAR_VIA_INHERIT=for_page2_from_page1_via_inherited_code_file
```

```link :linked2_import_vars +(vars2)
file: examples/linked2.md
block: show_vars
vars:
  page2_var_via_environment: for_page2_from_page1_via_current_environment
```