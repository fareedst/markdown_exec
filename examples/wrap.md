# Demo block wrapping

::: This block is wrapped by the `{outer*}` pair of blocks.

```bash :single +{outer}
echo single body - wrapped by outer
```

::: This block is wrapped first by the `{outer*}` pair of blocks
::: and nested inside, the `{inner*}` pair of blocks.

```bash :nested +{outer} +{inner}
echo nested body - wrapped by outer and then inner
```

::: This pair of hidden blocks are the `{inner*}` set.
```bash :{inner}
echo inner-before
```

```bash :{inner-after}
echo inner-after
```

::: This pair of hidden blocks are the `{outer*}` set.

```bash :{outer}
echo outer-before
```

```bash :{outer-after}
echo outer-after
```
