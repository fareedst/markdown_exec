# Demo configuring options
## H2
### H3

::: These Opts blocks set the color of a couple of menu options to demonstrate the live update of options.

```opts
# color scheme 1
menu_divider_color: yellow
menu_note_match: "^ *(?<line>.+?) *$"
menu_task_color: fg_rgb_255_63_255
```

```opts
# color scheme 2
menu_divider_color: red
menu_note_color: yellow
menu_note_match: "^\\+ +(?<line>.+?) *$"
menu_task_color: fg_rgb_127_127_255
```

@import example-document-opts.md
```opts :(document_opts)
menu_divider_color: green
menu_link_color: fg_rgbh_88_cc_66
menu_note_color: yellow

menu_note_match: "^\\s*(?<line>[^\\s/].*)\\s*$" # Pattern for notes in block selection menu; start with any char except '/'
```

note 1
note 2 ends with /
 / note 3 starts with /
note 4

::: These options toggle the dump of debug information.

```opts
dump_blocks_in_file: true      # Dump BlocksInFile (stage 1)
dump_delegate_object: true     # Dump @delegate_object
dump_context_code: true     # Dump inherited lines
dump_menu_blocks: true         # Dump MenuBlocks (stage 2)
dump_selected_block: true      # Dump selected block
```

```opts
dump_blocks_in_file: false     # Dump BlocksInFile (stage 1)
dump_delegate_object: false    # Dump @delegate_object
dump_context_code: false    # Dump inherited lines
dump_menu_blocks: false        # Dump MenuBlocks (stage 2)
dump_selected_block: false     # Dump selected block
```
