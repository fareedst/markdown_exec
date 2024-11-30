# Demonstrate data blocks

@import example-document-opts.md
```opts :(document_opts)
pause_after_script_execution: true
```

## Create a data file by requiring a YAML block.
::: YAML into a file
/ YAML block that loads data into a file.
```yaml :(test1) >test1.yml
a: species
b: genus
```
This is a Bash block that
- requires a hidden YAML block (that creates a file), and
- displays the file.
```bash +(test1)
echo "- The data file created"
ls -al *.yml
echo -e "\n- Contents of the file"
cat -n test1.yml
echo -e "\n- Remove the data file"
rm test1.yml
```

## Load data by requiring a yaml block.
::: YAML into a shell variable
/ YAML block that loads data into a variable.
```yaml :(test2) >$test2
c: family
d: order
```
This is a Bash block that
- requires a hidden YAML block (that sets a variable), and
- displays the variable.
```bash +(test2)
echo 'data:'
echo "$test2"
```

## Visible YAML block that is not executable.
::: Non-interactive data
```yaml
e: class
f: phylum
```

# Related MDE options
block_stdin_scan  | Match to place block body into a file or a variable
block_stdout_scan | Match to place block body into a file or a variable
