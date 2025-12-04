# Automated tests

## Shell blocks

```bash :bash1
echo "bash1!"
```

## Link Vars

| inputs to MDE| expected output
| -| -
| '[VARIABLE1]'| ' VARIABLE1: 1'
| '[VARIABLE1]' '(echo-VARIABLE1)'| ' VARIABLE1: 1   VARIABLE1: 1'

```bash :(echo-VARIABLE1)
for var_name in "VARIABLE1"; do
  # echo -e "\033[0;33m${var_name}\033[0;31m:\033[0m ${!var_name}"
  echo -e "${var_name}: ${!var_name}"
done
```
```link :[VARIABLE1]
block: (echo-VARIABLE1)
vars:
  VARIABLE1: 1
```

## Nested wraps

| inputs to MDE| expected output
| -| -
| '[single]'| ' single-body'
| '[inverted-nesting]'| ' inner-before outer-before single-body outer-after inner-after'

```bash :[single] +{outer}
echo single-body
```
  Expect output: "outer-before", "inner-before", "nested body", "inner-after", and "outer-after".
```bash :[nested] +{outer} +{inner}
echo nested-body
```
```bash :[inverted-nesting] +{inner} +{outer}
echo inverted-nesting
```
```bash :{inner}
echo inner-before
```
```bash :{inner-after}
echo inner-after
```
```bash :{outer}
echo outer-before
```
```bash :{outer-after}
echo outer-after
```

@import specs-import.md

/ Import `{wrap1}` blocks. 
```bash :[test-wrap-from-import] +{wrap-from-import}
echo "test-wrap-from-import"
```

/ Include a wrapped block.
```bash :[test-require-wrapped-block] +[single]
echo "test-require-wrapped-block"
```

```opts :(disable_dump_*)
dump_blocks_in_file: false
dump_dependencies: false
dump_inherited_block_names: false
dump_inherited_dependencies: false
dump_context_code: false
dump_menu_blocks: false
```

@import bats-document-configuration.md
```opts :(document_opts) +(disable_dump_*)
menu_note_color: 'plain'
menu_with_exit: true
menu_with_context_code: false
```
