# Demo document linking

::: * This is document 1 *
::: This document links to a matching document to demonstrate navigation between documents.

::: This Bash block displays the value of variables "linked1var" and "linked2var"

```bash :page1_show_vars
source bin/colorize_env_vars.sh
colorize_env_vars 'on page1' linked1var linked2var
```

::: This Link block sets variable "linked2var" and navigates to document 2.

```link :linked2
file: examples/linked2.md
vars:
  linked2var: from_linked1
```

::: This Link block sets variable "linked2var", navigates to document 2, and executes block "page2_show_vars".

```link :linked2_show_vars
file: examples/linked2.md
block: page2_show_vars
vars:
  linked2var: from_linked1
```
