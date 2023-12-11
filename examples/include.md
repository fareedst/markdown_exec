```bash :(one)
echo block "one"
```

```bash :two +(one)
echo block "two" requires one
```

```bash :(three) +two +(one)
echo block "three" requires two and one
```

```bash :four +(three)
echo block "four" requires three
```

```bash :trigger_unmet_dependency +(unmet)
echo block "five" requires an unmet dependency
```
