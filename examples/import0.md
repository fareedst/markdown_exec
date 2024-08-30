This is Page 0. It serves to demonstrate how options control the display of imported blocks and notes.

::: "import1.md" is imported here.

@import import1.md

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

::: Imported `{wrap1}` blocks. 
```bash :test-wrap1 +{wrap1}
echo "test wrap1"
```

::: Imported and Overloaded `{wrap2}` blocks. 
```bash :test-wrap2 +{wrap2}
echo "test wrap2 - overloaded"
```
```bash :{wrap2}
echo "wrap2 before - overloaded"
```
```bash :{wrap2-after}
echo "wrap2 after- overloaded"
```
	Local wrapped blocks, before or after the principal block, generate the same output.
	__Output__
		wrap2 before
		wrap2 before - overloaded
		test wrap2 - overloaded
		wrap2 after
		wrap2 after- overloaded
