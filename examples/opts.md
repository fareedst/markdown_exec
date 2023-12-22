# Demo configuring options

::: These Opts blocks set the color of a couple of menu options to demonstrate the live update of options.

```opts :opts1
menu_divider_color: yellow
menu_note_match: "^ *(?<line>.+?) *$"
menu_task_color: fg_rgb_255_63_255
```

```opts :opts2
menu_divider_color: red
menu_note_color: yellow
menu_note_match: "^\\+ +(?<line>.+?) *$"
menu_task_color: fg_rgb_127_127_255
```

```opts :(document_options)
menu_divider_color: green
menu_link_color: fg_rgbh_88_cc_66
menu_note_color: yellow
menu_note_match: "^\\s*(?<line>[^\\s/].*)\\s*$" # Pattern for notes in block selection menu; start with any char except '/'
```
