# Block Scanning Pattern Options

This document describes the configuration options that control how markdown_exec scans block content for special patterns and directives.

## Overview

Block scanning patterns are regex patterns used to extract special information from fenced code blocks. These patterns identify:
- Call names in block start lines
- Required dependencies in block bodies
- Stdin/stdout redirections
- Default block types
- Format strings for special block types

## Configuration Options

### block_calls_scan

- **Option**: `block_calls_scan`
- **Environment Variable**: `MDE_BLOCK_CALLS_SCAN`
- **Default**: `"%\\([^\\)]+\\)"`
- **Description**: Regex pattern to extract call names from block start lines (e.g., %call_name)

This pattern is used to extract call names from the fenced code block start line. When a block has a call name like `%my_call`, this pattern matches it and extracts `my_call` for use in block execution and dependency tracking.

**Example:**
```markdown
```bash :my_block %my_call
echo "This block has a call name"
```
```

The pattern `%\\([^\\)]+\\)` matches `%my_call` and extracts `my_call` as the call name.

### block_required_scan

- **Option**: `block_required_scan`
- **Environment Variable**: `MDE_BLOCK_REQUIRED_SCAN`
- **Default**: `"\\+\\S+"`
- **Description**: Regex pattern to scan block body for required dependencies (e.g., +blockname)

This pattern scans the block body content to identify required dependencies. When a block contains text like `+dependency_name`, it indicates that the block depends on another block named `dependency_name`.

**Example:**
```markdown
```bash :my_block
# This block requires another block
+setup_block
+config_block
echo "Running after dependencies"
```
```

The pattern `\\+\\S+` matches `+setup_block` and `+config_block`, indicating these blocks must be executed before `my_block`.

### block_stdin_scan

- **Option**: `block_stdin_scan`
- **Environment Variable**: `MDE_BLOCK_STDIN_SCAN`
- **Default**: `"<(?<full>(?<type>\\$)?(?<name>[A-Za-z_\\-\\.\\w]+))"`
- **Description**: Regex pattern to scan block body for stdin redirection (e.g., <variable or <$variable)

This pattern identifies stdin redirection directives in block content. It matches patterns like `<variable` or `<$variable` to indicate that the block should read from a variable or file.

**Example:**
```markdown
```bash :my_block
# Read from a variable
<$input_data
process_data
```
```

The pattern matches `<input_data` or `<$input_data` and extracts the variable name for stdin redirection.

### block_stdout_scan

- **Option**: `block_stdout_scan`
- **Environment Variable**: `MDE_BLOCK_STDOUT_SCAN`
- **Default**: `">(?<full>(?<type>\\$)?(?<name>[A-Za-z_\\-\\.\\w]+))"`
- **Description**: Match to place block body into a file or a variable

This pattern identifies stdout redirection directives in block content. It matches patterns like `>variable` or `>$variable` to indicate where the block's output should be directed.

**Example:**
```markdown
```bash :my_block
# Write output to a variable
generate_data >output_var
```
```

The pattern matches `>output_var` or `>$output_var` and extracts the variable name for stdout redirection.

### block_type_default

- **Option**: `block_type_default`
- **Environment Variable**: `MDE_BLOCK_TYPE_DEFAULT`
- **Default**: `bash`
- **Description**: Default shell type for blocks when no type is specified in the fenced code block

When a fenced code block doesn't specify a type (e.g., just ` ``` ` instead of ` ```bash `), this option determines the default shell type to use for execution.

**Example:**
```markdown
```
echo "This uses the default shell type"
```
```

If `block_type_default` is set to `bash`, this block will be executed as a bash script.

**Valid values:**
- `bash` - Bash shell (default)
- `sh` - POSIX shell
- `fish` - Fish shell

### block_type_port_set_format

- **Option**: `block_type_port_set_format`
- **Environment Variable**: `MDE_BLOCK_TYPE_PORT_SET_FORMAT`
- **Default**: `": ${%{key}:=%{value}}"`
- **Description**: Format string for generating shell variable assignments from PORT block content

This format string is used when processing PORT-type blocks to generate shell commands that set environment variables. The format uses placeholders:
- `%{key}` - The variable name
- `%{value}` - The variable value

**Example:**
```markdown
```port
PATH HOME USER
```
```

With the default format `": ${%{key}:=%{value}}"`, this would generate:
```bash
: ${PATH:=/usr/bin:/bin}
: ${HOME:=/home/user}
: ${USER:=username}
```

The format uses shell parameter expansion syntax (`${VAR:=default}`) to set variables with default values if they're not already set.

## How It Works

### Scanning Process

1. **Start Line Scanning**: When a fenced code block is parsed, `block_calls_scan` is applied to the start line to extract call names.

2. **Body Content Scanning**: After parsing the block body, the following patterns are applied:
   - `block_required_scan` - Scans for dependency markers
   - `block_stdin_scan` - Scans for stdin redirection
   - `block_stdout_scan` - Scans for stdout redirection

3. **Type Determination**: If no type is specified in the fenced code block delimiter, `block_type_default` is used.

4. **PORT Block Processing**: For PORT-type blocks, `block_type_port_set_format` is used to generate shell variable assignment commands.

### Execution Order

1. Block start line is parsed for call names
2. Block body is scanned for required dependencies
3. Block body is scanned for stdin/stdout redirections
4. Block type is determined (from delimiter or default)
5. For PORT blocks, format string is applied to generate commands

## Usage Examples

### Custom Call Pattern

To use a different call pattern (e.g., `@call_name` instead of `%call_name`):

```yaml
block_calls_scan: "@\\([^\\)]+\\)"
```

### Custom Required Dependency Pattern

To use a different dependency marker (e.g., `requires:blockname`):

```yaml
block_required_scan: "requires:(\\S+)"
```

### Custom Default Shell Type

To use `sh` as the default instead of `bash`:

```yaml
block_type_default: sh
```

### Custom PORT Format

To use a different format for PORT blocks (e.g., simple assignment):

```yaml
block_type_port_set_format: "export %{key}=%{value}"
```

This would generate:
```bash
export PATH=/usr/bin:/bin
export HOME=/home/user
export USER=username
```

## Related Configuration

These options work together with:

- **Block Naming Patterns** (`block_name_match`, `block_name_nick_match`, etc.) - Control how block names are extracted
- **Block Execution Modes** (`block_batch_match`, `block_interactive_match`) - Control how blocks are executed
- **Block Filtering** (`exclude_by_name_regex`, `select_by_name_regex`) - Control which blocks are included/excluded

## Technical Details

### Pattern Matching

All scan patterns use Ruby regex syntax. Special characters must be escaped:
- `\\(` for literal `(`
- `\\)` for literal `)`
- `\\+` for literal `+`
- `\\$` for literal `$`

### Named Capture Groups

Some patterns use named capture groups:
- `block_stdin_scan` captures `full`, `type`, and `name`
- `block_stdout_scan` captures `full`, `type`, and `name`

These capture groups allow the code to extract specific parts of the matched pattern.

### Default Values

The default patterns are designed to match common conventions:
- `%call_name` for call names
- `+dependency` for required dependencies
- `<variable` for stdin redirection
- `>variable` for stdout redirection

## Related Documentation

- [Block Naming Patterns](block-naming-patterns.md) - How block names are parsed and matched
- [Block Execution Modes](block-execution-modes.md) - How blocks are executed
- [Block Filtering](block-filtering.md) - How blocks are filtered and selected
- [CLI Reference](cli-reference.md) - Command-line usage

