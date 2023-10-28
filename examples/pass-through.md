Pass-through arguments after "--" to the executed script.

A block can expect arguments to receive all arguments to MDE after "--".

For `mde examples/pass-through.md output_arguments -- 123`,
this block outputs:

        ARGS: 123

::: This block will output any arguments after "--" in the command line.

```bash :output_arguments
echo "ARGS: $*"
```
