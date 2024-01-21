This document demonstrates the automatic loading of options in a block with a reserved name.

```opts :(document_options)
menu_divider_format: "=> %{line} == %{line} <="
```

The divider below is named "Divider #1". Notice the "(document_options)" block sets the "menu_divider_format" option to duplicate the divider name when it is displayed.
::: Divider #1
