```bash :page2_show_vars
source bin/colorize_env_vars.sh
colorize_env_vars 'on page2' linked2var linked1var
```

```link :linked1
file: fixtures/linked1.md
vars:
  linked1var: from_linked2
```

```link :linked1_show_vars
file: fixtures/linked1.md
block: page1_show_vars
vars:
  linked1var: from_linked2
```
