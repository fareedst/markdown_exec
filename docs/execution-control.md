# Execution Control Options

This document describes options that control how scripts are executed, including approval requirements, execution modes, and flow control.

## Overview

Execution control options allow you to:
- Require user approval before executing scripts
- Control where scripts execute (current terminal vs. new window)
- Pause execution flow for review
- Prevent accidental re-execution of the same block
- Display scripts before execution

These options provide safety and control mechanisms for script execution, especially useful when working with potentially destructive operations or when you need to review scripts before they run.

## Configuration Options

### `user-must-approve` / `-q`

- **Option**: `user_must_approve`
- **Long Name**: `--user-must-approve`
- **Short Name**: `-q`
- **Environment Variable**: `MDE_USER_MUST_APPROVE`
- **Argument**: `BOOL`
- **Default**: `false`
- **Description**: Requires user approval before executing a script

When enabled, displays the complete generated script (including all required dependencies) and prompts the user for confirmation before execution. This is a critical safety feature for reviewing scripts before they run.

**Usage:**
```bash
mde my-document.md --user-must-approve 1
mde my-document.md -q 1
```

**Examples:**
```bash
# Require approval for all executions
mde README.md -b deploy --user-must-approve 1

# Set via environment variable
export MDE_USER_MUST_APPROVE=1
mde README.md -b deploy

# In configuration file
# .mde.yml
user_must_approve: true
```

**Behavior:**
- The full script (including all required dependencies) is displayed
- User is prompted with "Process?" (configurable via `prompt_approve_block`)
- Execution only proceeds if user confirms (Yes/No)
- Works in both interactive menu mode and command-line mode
- When combined with `output_script`, the script is displayed regardless

**Related Options:**
- `output_script`: Display script before execution (doesn't require approval)
- `prompt_approve_block`: Customize the approval prompt text

### `execute-in-own-window` / `-w`

- **Option**: `execute_in_own_window`
- **Long Name**: `--execute-in-own-window`
- **Short Name**: `-w`
- **Environment Variable**: `MDE_EXECUTE_IN_OWN_WINDOW`
- **Argument**: `BOOL`
- **Default**: `false`
- **Description**: Execute script in own window

When enabled, executes the script in a new terminal window (iTerm on macOS) instead of the current terminal. Useful for long-running scripts or when you want to keep the main terminal free for other operations.

**Usage:**
```bash
mde my-document.md --execute-in-own-window 1
mde my-document.md -w 1
```

**Examples:**
```bash
# Execute in new window
mde README.md -b long-running-task -w 1

# Combine with approval
mde README.md -b deploy -q 1 -w 1

# Set via environment variable
export MDE_EXECUTE_IN_OWN_WINDOW=1
mde README.md -b deploy
```

**Requirements:**
- Requires `execute_command_format` to be configured (defaults to AppleScript for iTerm on macOS)
- Script and output files must be saved before execution (handled automatically)
- Window title includes timestamp, document name, and block name

**Window Title Format:**
The window title uses `execute_command_title_time_format` (default: `"%T"`) and includes:
- Timestamp (formatted)
- Document filename
- Block name

**Customization:**
For other terminal emulators or platforms, customize `execute_command_format` to use different commands or scripts.

**Related Options:**
- `execute_command_format`: AppleScript or command template for window execution
- `execute_command_title_time_format`: Time format for window title

### `output-script`

- **Option**: `output_script`
- **Long Name**: `--output-script`
- **Environment Variable**: `MDE_OUTPUT_SCRIPT`
- **Argument**: `BOOL`
- **Default**: `false`
- **Description**: Display script prior to execution

When enabled, displays the generated script (including all required dependencies) before execution, even if `user_must_approve` is disabled. Useful for debugging, reviewing what will be executed, or logging.

**Usage:**
```bash
mde my-document.md --output-script 1
```

**Examples:**
```bash
# Display script before execution
mde README.md -b deploy --output-script 1

# Combine with approval for review
mde README.md -b deploy --output-script 1 --user-must-approve 1

# Set via environment variable
export MDE_OUTPUT_SCRIPT=1
mde README.md -b deploy
```

**Behavior:**
- Script is displayed with frame markers (configurable via `script_preview_head` and `script_preview_tail`)
- Includes all required dependencies in execution order
- Execution proceeds automatically (unless `user_must_approve` is also enabled)
- Useful for debugging or understanding what will execute

**Related Options:**
- `user_must_approve`: Require approval after displaying script
- `script_preview_head`: Text displayed before script preview
- `script_preview_tail`: Text displayed after script preview
- `script_preview_frame_color`: Color for preview frame

### `debounce-execution`

- **Option**: `debounce_execution`
- **Environment Variable**: `MDE_DEBOUNCE_EXECUTION`
- **Argument**: `BOOL`
- **Default**: `true`
- **Description**: Whether to prompt before re-executing the same block multiple times

When enabled, prevents accidental re-execution of the same block by prompting for confirmation if you try to execute a block that was just executed. This helps prevent accidental duplicate executions.

**Usage:**
```bash
# Via environment variable (no CLI flag)
export MDE_DEBOUNCE_EXECUTION=0  # Disable
export MDE_DEBOUNCE_EXECUTION=1  # Enable (default)
```

**Examples:**
```bash
# Disable debouncing (allow immediate re-execution)
export MDE_DEBOUNCE_EXECUTION=0
mde README.md

# Enable debouncing (default behavior)
export MDE_DEBOUNCE_EXECUTION=1
mde README.md
```

**Behavior:**
- When enabled, if you select the same block that was just executed, you're prompted with "Repeat this block?" (configurable via `prompt_debounce`)
- Blocks executed from CLI (via `--block-name`) bypass debouncing
- Debounce state is reset when navigating back or selecting different menu options
- Only applies to interactive menu selections, not CLI-specified blocks

**Related Options:**
- `prompt_debounce`: Customize the debounce prompt text

### `pause-after-script-execution`

- **Option**: `pause_after_script_execution`
- **Long Name**: `--pause-after-script-execution`
- **Environment Variable**: `MDE_PAUSE_AFTER_SCRIPT_EXECUTION`
- **Argument**: `BOOL`
- **Default**: `false`
- **Description**: Whether to pause after manually executing a block and before the next menu

When enabled, pauses execution after a block completes and before displaying the next menu. Useful for reviewing execution results before continuing.

**Usage:**
```bash
mde my-document.md --pause-after-script-execution 1
```

**Examples:**
```bash
# Pause after execution
mde README.md -b deploy --pause-after-script-execution 1

# Set via environment variable
export MDE_PAUSE_AFTER_SCRIPT_EXECUTION=1
mde README.md -b deploy

# In configuration file
# .mde.yml
pause_after_script_execution: true
```

**Behavior:**
- After script execution completes, displays the prompt (configurable via `prompt_after_script_execution`, default: "\nContinue?")
- User must press Enter or respond to continue
- Useful for reviewing execution output before the menu reappears
- Works in interactive mode

**Related Options:**
- `prompt_after_script_execution`: Customize the pause prompt text
- `prompt_color_after_script_execution`: Color for the pause prompt

### `execute-command-format`

- **Option**: `execute_command_format`
- **Environment Variable**: `MDE_EXECUTE_COMMAND_FORMAT`
- **Default**: AppleScript template for iTerm
- **Description**: AppleScript to execute a command in a window

Template string used when `execute_in_own_window` is enabled. The default is an AppleScript that creates a new iTerm window and executes the script there.

**Usage:**
```bash
# Set via environment variable
export MDE_EXECUTE_COMMAND_FORMAT='your-custom-template'
```

**Default Template:**
The default template uses AppleScript to:
1. Create a new iTerm window
2. Set environment variables for script and output files
3. Change to the working directory
4. Set the window title
5. Execute the script with output redirected to a log file

**Customization:**
For other terminal emulators or platforms, customize this template to use different commands. The template supports format placeholders:
- `%{batch_index}`: Batch index
- `%{home}`: Working directory
- `%{output_filespec}`: Output file path
- `%{script_filespec}`: Script file path
- `%{started_at}`: Execution start time
- `%{document_filename}`: Document filename
- `%{block_name}`: Block name
- `%{rest}`: Additional arguments

**Related Options:**
- `execute_in_own_window`: Enable window execution
- `execute_command_title_time_format`: Time format for window title

### `execute-command-title-time-format`

- **Option**: `execute_command_title_time_format`
- **Environment Variable**: `MDE_EXECUTE_COMMAND_TITLE_TIME_FORMAT`
- **Default**: `"%T"`
- **Description**: Format for time in window title

Time format string used in the window title when `execute_in_own_window` is enabled. Uses Ruby `Time#strftime` format.

**Usage:**
```bash
# Set via environment variable
export MDE_EXECUTE_COMMAND_TITLE_TIME_FORMAT="%H:%M:%S"
```

**Examples:**
```bash
# 24-hour time
export MDE_EXECUTE_COMMAND_TITLE_TIME_FORMAT="%H:%M:%S"

# Full timestamp
export MDE_EXECUTE_COMMAND_TITLE_TIME_FORMAT="%Y-%m-%d %H:%M:%S"

# ISO 8601
export MDE_EXECUTE_COMMAND_TITLE_TIME_FORMAT="%FT%TZ"
```

**Common Format Codes:**
- `%H`: Hour (00-23)
- `%M`: Minute (00-59)
- `%S`: Second (00-59)
- `%Y`: Year (4 digits)
- `%m`: Month (01-12)
- `%d`: Day (01-31)
- `%T`: Time (equivalent to `%H:%M:%S`)
- `%F`: Date (equivalent to `%Y-%m-%d`)

## How It Works

### Execution Flow

1. **Script Generation**: The complete script is generated, including all required dependencies
2. **Display Check**: If `output_script` or `user_must_approve` is enabled, the script is displayed
3. **Approval Check**: If `user_must_approve` is enabled, user confirmation is required
4. **Execution Mode**: Script executes either:
   - In current terminal (default)
   - In new window (if `execute_in_own_window` is enabled)
5. **Post-Execution**: If `pause_after_script_execution` is enabled, execution pauses before menu

### Debouncing Logic

The debouncing mechanism tracks the last executed block:
- If the same block is selected again, user is prompted
- Blocks executed from CLI bypass debouncing
- Debounce state resets on navigation or different block selection

### Window Execution

When `execute_in_own_window` is enabled:
1. Script is saved to a temporary file
2. Output file path is determined
3. `execute_command_format` template is populated with values
4. Template is executed (typically AppleScript for iTerm)
5. New window opens and executes the script

## Usage Examples

### Safe Execution with Approval

```bash
# Require approval for all executions
mde README.md -b deploy --user-must-approve 1

# Or set globally
export MDE_USER_MUST_APPROVE=1
mde README.md -b deploy
```

### Review Script Before Execution

```bash
# Display script and require approval
mde README.md -b deploy --output-script 1 --user-must-approve 1
```

### Long-Running Scripts in New Window

```bash
# Execute in new window
mde README.md -b long-task --execute-in-own-window 1

# With approval
mde README.md -b long-task -q 1 -w 1
```

### Pause After Execution

```bash
# Pause to review results
mde README.md -b deploy --pause-after-script-execution 1
```

### Configuration File Example

```yaml
# .mde.yml
user_must_approve: true
output_script: true
pause_after_script_execution: true
execute_in_own_window: false
```

## Related Documentation

- [CLI Reference](cli-reference.md) - Command-line usage patterns
- [Block Execution Modes](block-execution-modes.md) - Batch, interactive, and default execution modes
- [Block Filtering](block-filtering.md) - Filtering and selecting blocks
- [Block Naming Patterns](block-naming-patterns.md) - How block names are parsed and matched

