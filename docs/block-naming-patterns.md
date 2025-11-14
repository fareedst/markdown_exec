# Block Naming Patterns

This document explains how block names are parsed, matched, and used for filtering and display in markdown_exec.

## Overview

Markdown Exec uses several regex patterns to identify and categorize block names:

1. **Block Name Extraction**: `block_name_match` - extracts the name from the fenced code block start line
2. **Block Visibility**: `block_name_hide_custom_match` - control which blocks appear in menus
3. **Block Types**: `block_name_hidden_match`, `block_name_nick_match`, `block_name_wrapper_match` - identify special block naming patterns

## Configuration Options

### Block Name Match

- **Option**: `block_name_match`
- **Environment Variable**: `MDE_BLOCK_NAME_MATCH`
- **Default**: `":(?<title>\\S+)( |$)"`
- **Description**: Regex pattern to extract the block name from the fenced code block start line

This pattern is used to parse the block name from lines like:
```bash
```bash :my-block-name
```

The default pattern matches a colon followed by a name (captured in the `title` group). The pattern must include a named capture group (typically `title`) to extract the block name.

**Example matches:**
- `:example` → extracts `example`
- `:my-block-name` → extracts `my-block-name`
- `:test_block` → extracts `test_block`

### Block Name Hidden Match

- **Option**: `block_name_hide_custom_match`
- **Environment Variable**: `MDE_BLOCK_NAME_HIDE_CUSTOM_MATCH`
- **Default**: `"^-.+-$"`
- **Description**: Regex pattern for block names that should be hidden from the menu

Blocks whose names match this pattern will be hidden from the block selection menu when `hide_blocks_by_name` is enabled. The default pattern matches names that start and end with hyphens (e.g., `-hidden-`, `-internal-`).

**Example matches:**
- `-hidden-` → hidden from menu
- `-internal-block-` → hidden from menu
- `visible-block` → shown in menu

### Block Name Hidden Match

- **Option**: `block_name_hidden_match`
- **Environment Variable**: `MDE_BLOCK_NAME_HIDE_CUSTOM_MATCH`
- **Default**: `"^\\(.*\\)$"`
- **Description**: Regex pattern for block names that should be included in the menu

Blocks whose names match this pattern will be explicitly included in the menu, even if they might otherwise be filtered. The default pattern matches names in parentheses (e.g., `(document_opts)`, `(document_vars)`).

**Example matches:**
- `(document_opts)` → included in menu
- `(document_vars)` → included in menu
- `(config)` → included in menu

**Note**: This works in conjunction with other filtering options. When `include_name` is true in the filter evaluation, the block is shown in the menu.

### Block Name Nick Match

- **Option**: `block_name_nick_match`
- **Environment Variable**: `MDE_BLOCK_NAME_NICK_MATCH`
- **Default**: `"^\\[.*\\]$"`
- **Description**: Regex pattern for block nicknames (alternative names not displayed in menu)

Blocks whose names match this pattern are treated as having nicknames. The nickname is an alternative identifier that is not displayed in the menu but can be used for references and dependencies. The default pattern matches names in square brackets (e.g., `[alias]`, `[short-name]`).

**Example matches:**
- `[alias]` → treated as nickname
- `[short]` → treated as nickname
- `regular-name` → not a nickname

**Usage**: Nicknames are useful when you want to reference a block by a shorter name internally, but display a different name in the menu.

### Block Name Wrapper Match

- **Option**: `block_name_wrapper_match`
- **Environment Variable**: `MDE_BLOCK_NAME_WRAPPER_MATCH`
- **Default**: `"^{.+}$"`
- **Description**: Regex pattern for block names that act as wrappers (include other blocks)

Blocks whose names match this pattern are treated as wrapper blocks that can include or wrap other blocks. The default pattern matches names in curly braces (e.g., `{wrapper}`, `{container}`).

**Example matches:**
- `{wrapper}` → treated as wrapper
- `{container}` → treated as wrapper
- `regular-block` → not a wrapper

**Usage**: Wrapper blocks are used in dependency resolution and block composition. When a block name matches this pattern in a dependency specification (e.g., `+{wrapper}`), it's treated as a wrapper rather than a regular dependency.

### Block Name (CLI Option)

- **Option**: `block_name`
- **Long Name**: `--block-name`
- **Short Name**: `-b`
- **Environment Variable**: `MDE_BLOCK_NAME`
- **Description**: Name of block to execute

This is a CLI option that allows you to directly specify which block to execute, bypassing the interactive menu selection.

**Usage:**
```bash
mde document.md -b my-block-name
mde document.md --block-name example-block
```

## How It Works

### Name Extraction Process

1. When a fenced code block is encountered, the start line is matched against `block_name_match`
2. If a match is found, the `title` capture group is extracted as the block name
3. The extracted name is stored as the block's primary identifier

### Filtering Process

The filtering logic in `lib/filter.rb` evaluates blocks in this order:

1. **Custome Hidden Name Check**: If `hide_blocks_by_name` is enabled and the name matches `block_name_hide_custom_match`, the block is hidden
2. **Hidden Name Check**: If the name matches `block_name_hidden_match`, the block is hidden
3. **Wrapper Name Check**: If the name matches `block_name_wrapper_match`, it's marked as a wrapper
4. **Final Decision**: The `evaluate_filters` method combines these flags to determine menu visibility

### Special Name Types

- **Nicknames**: Matched by `block_name_nick_match`, used for internal references but not displayed
- **Wrappers**: Matched by `block_name_wrapper_match`, used in dependency resolution
- **Custom Hidden**: Matched by `block_name_hide_custom_match`, excluded from menus
- **Hidden**: Matched by `block_name_hidden_match`, excluded from menus

## Usage Examples

### Basic Block Naming

```bash :example-block
echo "This block is named 'example-block'"
```

The name `example-block` is extracted using `block_name_match` pattern.

### Hidden Blocks

```bash :-internal-
echo "This block is hidden from the menu"
```

The name `-internal-` matches `block_name_hide_custom_match` and will be hidden when `hide_blocks_by_name` is enabled.

### Included Blocks (Document Configuration)

```opts :(document_opts)
# Configuration options
clear_screen_for_select_block: false
```

The name `(document_opts)` matches `block_name_hidden_match` and will be hidden from the menu.

### Nickname Blocks

```bash :[alias]
echo "This block has a nickname"
```

The name `[alias]` matches `block_name_nick_match` and is treated as a nickname.

### Wrapper Blocks

```bash :{wrapper}
echo "This is a wrapper block"
```

The name `{wrapper}` matches `block_name_wrapper_match` and is treated as a wrapper.

### Custom Patterns

You can customize the patterns to match your naming conventions:

```opts
# Match block names starting with "internal_"
block_name_hide_custom_match: '^internal_.*'

# Match block names in double parentheses
block_name_hidden_match: '^\\(\\(.*\\)\\)$'

# Match block names starting with "@"
block_name_nick_match: '^@.*'

# Match block names in angle brackets
block_name_wrapper_match: '^<.+>$'
```

## Related Configuration

- `hide_blocks_by_name`: Enable/disable hiding blocks based on name patterns
- `block_name`: CLI option to directly specify a block to execute
- Block filtering options: `exclude_by_name_regex`, `select_by_name_regex`

## Related Documentation

- [Block Filtering](block-filtering.md) - Other block filtering mechanisms
- [Block Execution Modes](block-execution-modes.md) - Execution mode patterns
- [Block Scanning Patterns](block-scanning-patterns.md) - How block content is scanned
- [Import Options](import-options.md) - How imported blocks are named
- [CLI Reference](cli-reference.md) - Command-line usage

