This document demonstrates the automatic loading of options in a block with a reserved name.

@import example-document-opts.md
```opts :(document_opts)
menu_divider_format: "=> %{line} == %{line} <="
```

The divider below is named "Divider #1". Notice the "(document_opts)" block sets the "menu_divider_format" option to duplicate the divider name when it is displayed.
::: Divider #1
