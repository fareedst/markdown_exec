# Demo block nicknames

```opts :(document_opts)
pause_after_script_execution: true
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
echo 'This block has a nickname: [A].'
echo The full block is displayed in the menu.
```

### Nicknames in documents
::: Execute this block that requires the block above by its nickname.
```bash :[B] +[A]
echo 'This block has a nickname: [B].'
echo 'This block requires block [A].'
```

### Nicknames from the command line
Block `[A]` is called from the command line.
```bash
mde examples/nickname.md '[A]'
```

## Blocks with hidden names
### There is a hidden block here.
::: This block has a hidden name: (C).
::: This block does not appear in the menu.
::: This block requires the block above by its nickname.
```bash :(C) +[A]
echo 'This block has a hidden name: (C).'
echo This block is hidden from the menu.
echo 'This block requires block [A].'
```

### Hidden names from the command line
Block `(C)` is called from the command line.
```bash
mde examples/nickname.md '(C)'
```

### Block without a name
::: This block does not have a name.
::: It requires hidden block (D).
```bash +(D)
echo "Block without a name"
```
::: This block has a hidden name: (D).
```bash :(D)
echo "Block D"
```
