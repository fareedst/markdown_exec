This is Page 0

@import import1.md

```opts :(document_options)
user_must_approve: true
```

::: Page 0 code blocks

```bash :page0_block1 +(page0_block2) +(page1_block2)
echo "page 0 block 1 visible"
# requires page 0 block 2
# imports page 1
# requires page 1 block 2
```

```bash :(page0_block2)
echo "page 0 block 2 hidden"
```

::: Control display of code blocks

```opts :hide_imported_blocks
menu_include_imported_blocks: false
```

```opts :show_imported_blocks
menu_include_imported_blocks: true
```

::: Control display of notes

```opts :hide_imported_notes
menu_include_imported_notes: false
```

```opts :show_imported_notes
menu_include_imported_notes: true
```

```link :page_1
file: examples/import1.md
```
