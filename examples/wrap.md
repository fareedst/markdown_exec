# Demo block wrapping

## Wrapped block

This block is wrapped by the `{outer*}` pair of blocks.
  Expect output: "outer-before", "single body", and "outer-after".
  ::: Select below to test a block wrapped by a named pair of blocks.
    ```bash :[single] +{outer}
    echo single body
    ```

## Nested wraps

This block is wrapped first by the `{outer*}` pair of blocks and then the `{inner*}` pair of blocks.
  Expect output: "outer-before", "inner-before", "nested body", "inner-after", and "outer-after".
  Blocks for the left-most included wrapper are first and last.
  ::: Select below to test a block wrapped by nested named pair of blocks.
    ```bash :[nested] +{outer} +{inner}
    echo nested body
    ```
  Expect output: "inner-before", "outer-before", "nested body", "outer-after", and "inner-after".
    ```bash :[inverted-nesting] +{inner} +{outer}
    echo inverted nesting
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

## Requiring additional Bash blocks

```bash :(inc1)
echo included1
```
```bash :inc2
echo included2
```
Main block without a name.
	Inc2 + Outer
		```bash +{outer} +inc2
		echo expecting11
		```
	Inc1 + Outer
		```bash +{outer} +(inc1)
		echo expecting12
		```
Main block with a name.
	Inc2 + Outer
		```bash :ex21 +{outer} +inc2
		echo expecting21
		```
	Inc1 + Outer
		```bash :ex22 +{outer} +(inc1)
		echo expecting22
		```

## Requiring additional Bash blocks from wrapper block

::: Does not work

Inc1 + wrap-with-req
	```bash :ex31 +{wrap-with-req}
	echo expecting31
	```

```bash :{wrap-with-req} +(inc1)
echo wrap-with-req-before
```

```bash :{wrap-with-req-after}
echo wrap-with-req-after
```

::: Debug Inherited Code
```opts
dump_blocks_in_file: true
dump_dependencies: true
dump_inherited_block_names: true
dump_inherited_dependencies: true
dump_menu_blocks: true
```

```opts :add_shell_code_labels
shell_code_label_format_above: "#  -^-"
shell_code_label_format_below: "#  -v-  +%{block_name}  -o-  %{document_filename}  -o-  %{time_now_date}  -v-"
```

```opts :(document_options)
execute_in_own_window: false
output_execution_report: false
output_execution_summary: false
pause_after_script_execution: true
line_decor_pre:
  - :color_method: :underline_italic
    :pattern: '"([^"]{0,64})"'
```
