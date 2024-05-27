Demonstrate loading inherited code via the command line.

Run this command to display the inherited code.
`mde --load-code examples/load1.sh examples/load_code.md display_variables`

```bash :display_variables
source bin/colorize_env_vars.sh
echo The current value of environment variables:
colorize_env_vars '' var1 var2
```
