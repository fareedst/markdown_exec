Demonstrate loading inherited code via the command line.

Run this command to display the inherited code.
`mde --load-code docs/dev/load1.sh docs/dev/load_code.md`

| Variable| Value
| -| -
| var1| ${var1}
| var2| ${var2}
@import bats-document-configuration.md
```opts :(document_opts)
menu_for_saved_lines: false
screen_width: 80
table_center: false
```