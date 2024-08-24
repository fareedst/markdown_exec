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

```opts :(disable_dump_*)
dump_blocks_in_file: false
dump_dependencies: false
dump_inherited_block_names: false
dump_inherited_dependencies: false
dump_inherited_lines: false
dump_menu_blocks: false
```

```opts :(document_options) +(disable_dump_*)
execute_in_own_window: false
menu_with_inherited_lines: false
output_execution_report: false
output_execution_summary: false
pause_after_script_execution: false
script_execution_head:
script_execution_tail:
user_must_approve: false

menu_note_color: 'plain'
script_execution_frame_color: 'plain'

```
