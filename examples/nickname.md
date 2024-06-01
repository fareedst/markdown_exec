# Demo block nicknames

```opts :(document_options)
save_executed_script: true
```

## Blocks with no name
::: This block has no name.
::: The code block is displayed.

```bash
echo This block has no name.
```

## Blocks with nicknames
::: The code block is displayed.
::: The nickname can be used to require the block.

```bash :[A]
echo This block has a nickname.
echo The full block is displayed in the menu.
```

### Nicknames in documents
::: Execute this block that requires the block above by its nickname.
```bash :[B] +[A]
echo This block has a nickname.
echo It requires the block above by its nickname.
```

### Nicknames from the command line
Block `[A]` is called from the command line.
```bash
mde examples/nickname.md '[A]'
```

## Blocks with hidden names
::: Nothing is displayed in the menu.
::: There is a hidden block here.
::: This block requires the block above by its nickname.
```bash :(C) +[A]
echo This block is hidden from the menu.
```

### Hidden names from the command line
Block `(C)` is called from the command line.
```bash
mde examples/nickname.md '(C)'
```
