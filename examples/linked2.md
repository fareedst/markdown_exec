# Demo document linking

::: * This is document 2 *
::: This document links to a matching document to demonstrate navigation between documents.

::: This Bash block displays the value of variables "linked1var" and "linked2var"

```bash :page2_show_vars
source bin/colorize_env_vars.sh
colorize_env_vars 'on page2' linked1var linked2var
```

::: This Link block sets variable "linked1var" and navigates to document 1.

```link :linked1
file: examples/linked1.md
vars:
  linked1var: from_linked2
```

::: This Link block sets variable "linked1var", navigates to document 1, and executes block "page1_show_vars".

```link :linked1_show_vars
file: examples/linked1.md
block: page1_show_vars
vars:
  linked1var: from_linked2
```
