```bash :page1_show_vars
source bin/colorize_env_vars.sh
colorize_env_vars 'on page1' linked2var linked1var
```

```link :linked2
file: fixtures/linked2.md
vars:
  linked2var: from_linked1
```

```link :linked2_show_vars
file: fixtures/linked2.md
block: page2_show_vars
vars:
  linked2var: from_linked1
```
