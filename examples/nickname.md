# Demo block nicknames

::: This block has no name.
::: The code block is displayed.

```bash
echo Unnamed block
```

::: These blocks use nicknames.
::: The code blocks are displayed.
::: The nicknames can be used for requiring blocks.

```bash :[A]
echo From the required block \#2
```

::: Execute this block that requires the block above.

```bash :[B] +[A]
echo From the parent block \#1
```
