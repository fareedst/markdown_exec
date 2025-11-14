# CLI Reference

Quick reference for command-line usage of MarkdownExec. For detailed option documentation, see the specialized guides linked below.

## Overview

MarkdownExec provides both interactive and command-line modes for executing code blocks from markdown documents. Most options can be specified via:
- Command-line flags (e.g., `--filename`, `-f`)
- Environment variables (e.g., `MDE_FILENAME`)
- Configuration files (`.mde.yml`)

## Basic Usage

```bash
# Interactive mode - process README.md in current directory
mde

# Process a specific markdown file
mde my-document.md

# Execute a specific block directly (non-interactive)
mde my-document.md my-block-name

# Execute a specific block using option flag
mde my-document.md --block-name my-block-name
mde my-document.md -b my-block-name
```

## File and Document Selection

### `filename` / `-f`

- **Option**: `filename`
- **Long Name**: `--filename`
- **Short Name**: `-f`
- **Environment Variable**: `MDE_FILENAME`
- **Default**: None

Specifies which markdown file to process. Can be a relative path to a markdown file.

**Usage:**
```bash
mde --filename my-document.md
mde -f my-document.md
mde my-document.md  # Positional argument (position 0)
```

**Note**: If a filename is provided as a positional argument (first argument without a flag), it's automatically treated as the filename.

### `path` / `-p`

- **Option**: `path`
- **Long Name**: `--path`
- **Short Name**: `-p`
- **Environment Variable**: `MDE_PATH`
- **Default**: `"."`

Specifies the directory path where markdown documents are located.

**Usage:**
```bash
mde --path /path/to/documents
mde -p ./docs
mde /path/to/documents  # Positional argument if directory exists
```

### `block-name` / `-b`

- **Option**: `block_name`
- **Long Name**: `--block-name`
- **Short Name**: `-b`
- **Environment Variable**: `MDE_BLOCK_NAME`
- **Default**: None

Specifies which code block to execute directly, bypassing the interactive menu.

**Usage:**
```bash
mde my-document.md --block-name my-block
mde my-document.md -b my-block
mde my-document.md my-block  # Positional argument (position 1)
```

**Note**: If a block name is provided as a positional argument (second argument), it's automatically treated as the block name. Use `.` as the block name to force menu display.

### `hide-shebang`

- **Option**: `hide_shebang`
- **Long Name**: `--hide-shebang` / `--no-hide-shebang`
- **Environment Variable**: `MDE_HIDE_SHEBANG`
- **Default**: `true`

Controls whether shebang lines (lines starting with `#!`) are hidden from document output. When enabled (default), shebang lines are extracted from input files during processing and not displayed as part of the document. This is useful when markdown files include shebang lines for direct execution (e.g., `#!/usr/bin/env mde`) but you don't want them to appear in the rendered document.

**Usage:**
```bash
# Hide shebang lines (default behavior)
mde my-document.md
mde my-document.md --hide-shebang
MDE_HIDE_SHEBANG=true mde my-document.md

# Show shebang lines in output
mde my-document.md --no-hide-shebang
MDE_HIDE_SHEBANG=false mde my-document.md
```

**Note**: The option applies to both the main document and any imported files (via `@import` directives). Shebang lines are detected and filtered during the cached nested read process.

## Discovery Commands

### `list-blocks`

- **Option**: `list_blocks`
- **Long Name**: `--list-blocks`

Displays all available code blocks in the specified document(s). Useful for discovering what blocks are available without entering interactive mode.

**Usage:**
```bash
mde my-document.md --list-blocks
```

### `list-docs`

- **Option**: `list_docs`
- **Long Name**: `--list-docs`

Lists all markdown documents found in the current directory (or specified path).

**Usage:**
```bash
mde --list-docs
mde --path /path/to/docs --list-docs
```

### `find` / `?`

- **Option**: `find`
- **Long Name**: `--find`
- **Short Name**: `?`

Searches for a keyword or pattern across markdown documents, block names, and file contents. Displays matching results and allows selection.

**Usage:**
```bash
mde --find "search-term"
mde ? "search-term"
mde "search-term"  # Positional argument if file doesn't exist
```

### `open` / `o`

- **Option**: `open`
- **Long Name**: `--open`
- **Short Name**: `o`

Similar to `find`, but automatically presents a selection menu and opens the user's choice. Combines search and open in one step.

**Usage:**
```bash
mde --open "search-term"
mde -o "search-term"
```

## Save Options

### `save-executed-script`

- **Option**: `save_executed_script`
- **Long Name**: `--save-executed-script`
- **Environment Variable**: `MDE_SAVE_EXECUTED_SCRIPT`
- **Default**: `false`

When enabled, saves the generated script to a file before execution. Scripts are saved with timestamps and metadata for later review or replay.

**Usage:**
```bash
mde my-document.md --save-executed-script 1
```

**Saved Script Location:**
- Default folder: `logs/` (configurable via `saved_script_folder`)
- Filename format: `mde_TIMESTAMP_DOCUMENT~BLOCK.sh` (configurable via `saved_asset_format`)

### `save-execution-output`

- **Option**: `save_execution_output`
- **Long Name**: `--save-execution-output`
- **Environment Variable**: `MDE_SAVE_EXECUTION_OUTPUT`
- **Default**: `false`

When enabled, saves the standard output (stdout) from script execution to a file. Useful for logging execution results.

**Usage:**
```bash
mde my-document.md --save-execution-output 1
```

## Utility Commands

### `help` / `-h`

- **Option**: `help`
- **Long Name**: `--help`
- **Short Name**: `-h`

Displays the help message with usage information and available options.

**Usage:**
```bash
mde --help
mde -h
```

### `version` / `-v`

- **Option**: `version`
- **Long Name**: `--version`
- **Short Name**: `-v`

Displays the current version of MarkdownExec.

**Usage:**
```bash
mde --version
mde -v
```

### `debug` / `-d`

- **Option**: `debug`
- **Long Name**: `--debug`
- **Short Name**: `-d`
- **Environment Variable**: `MDE_DEBUG`
- **Default**: `false`

Enables debug output, providing detailed information about internal operations, option parsing, and execution flow. Useful for troubleshooting.

**Usage:**
```bash
mde my-document.md --debug 1
mde my-document.md -d 1
```

### `config`

- **Option**: `config`
- **Long Name**: `--config`
- **Default**: `"."`

Specifies the path to a configuration file (`.mde.yml`). Configuration files allow you to set default options for a project or directory.

**Usage:**
```bash
mde --config /path/to/.mde.yml
mde --config .
```

**Note**: Configuration files are automatically loaded from the current directory (`.mde.yml`) if they exist. Use `--config` to specify a different location.

### `exit` / `x`

- **Option**: `exit`
- **Long Name**: `--exit`
- **Short Name**: `x`

Exits the application immediately. Useful in scripts or when you want to exit without processing.

**Usage:**
```bash
mde --exit
mde -x
```

### `load-code` / `l`

- **Option**: `load_code`
- **Long Name**: `--load-code`
- **Short Name**: `l`
- **Environment Variable**: `MDE_LOAD_CODE`

Loads code from an external file into the document context. The loaded code is treated as inherited lines that can be referenced by blocks.

**Usage:**
```bash
mde my-document.md --load-code /path/to/code.sh
mde my-document.md -l /path/to/code.sh
```

## Common Usage Patterns

### Quick Execution

```bash
# Execute a specific block directly
mde README.md deploy

# With approval (see execution-control.md for details)
mde README.md deploy --user-must-approve 1
```

### Interactive Development

```bash
# Open document in interactive mode
mde README.md

# Open with specific block pre-selected
mde README.md --block-name .

# Search and open
mde --open "setup"
```

### Script Management

```bash
# Save scripts and output
mde README.md -b deploy --save-executed-script 1 --save-execution-output 1
```

### Discovery and Exploration

```bash
# List available documents
mde --list-docs

# List blocks in a document
mde README.md --list-blocks

# Search for content
mde --find "database"
```

## Configuration

### Environment Variables

All options can be set via environment variables using the `MDE_` prefix:

```bash
export MDE_FILENAME=README.md
export MDE_SAVE_EXECUTED_SCRIPT=1
export MDE_DEBUG=1

mde -b deploy
```

### Configuration Files

Create a `.mde.yml` file in your project directory to set default options:

```yaml
# .mde.yml
save_executed_script: true
user_must_approve: true
output_script: true
saved_script_folder: logs
```

## Related Documentation

- [Execution Control](execution-control.md) - Detailed execution control options (approval, window execution, pausing, debouncing)
- [Block Execution Modes](block-execution-modes.md) - Batch, interactive, and default execution modes
- [Block Filtering](block-filtering.md) - Filtering and selecting blocks
- [Block Naming Patterns](block-naming-patterns.md) - How block names are parsed and matched
- [Block Scanning Patterns](block-scanning-patterns.md) - How block content is scanned for patterns
- [Import Options](import-options.md) - @import directive configuration
- [UX Blocks](ux-blocks.md) - Interactive form blocks

