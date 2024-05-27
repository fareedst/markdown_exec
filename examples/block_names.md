Demonstrate display of block names and requiring blocks.

This block is listed by its name `A`.
It requires block `[C]`.
Executing it outputs `1`, `3`.
```bash :A +[C]
echo "1"
```

This block is listed according to its content `echo "2"`.
It requires blocks `A`, `[C]`.
Executing it outputs `1`, `2`, `3`.
It cannot be addressed/required.
```bash +A
echo "2"
```

This block is listed according to its content `echo "3"` and addressed by its nick name `[C]`.
It requires no blocks.
Executing it outputs `3`.
```bash :[C]
echo "3"
```
