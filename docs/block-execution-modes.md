# Block Execution Modes

This document explains how blocks can be configured to execute in different modes: batch mode, interactive mode, or the default document mode.

## Overview

Markdown Exec supports three execution modes for code blocks, plus a disable option:

1. **Default Mode**: Uses `document_play_bin` (default: `play`) - standard execution
2. **Batch Mode**: Uses `play_bin_batch` (default: `play`) - for non-interactive batch execution
3. **Interactive Mode**: Uses `play_bin_interactive` (default: `play_interactive`) - for interactive execution
4. **Disabled**: Blocks matching `block_disable_match` are marked as disabled and cannot be executed

## Configuration Options

### Block Batch Match

- **Option**: `block_batch_match`
- **Environment Variable**: `MDE_BLOCK_BATCH_MATCH`
- **Default**: `'@batch'`
- **Description**: Pattern to match blocks that should be executed in batch mode

Blocks whose start line matches this pattern will be executed using the `play_bin_batch` binary instead of the default `document_play_bin`.

### Block Interactive Match

- **Option**: `block_interactive_match`
- **Environment Variable**: `MDE_BLOCK_INTERACTIVE_MATCH`
- **Default**: `'@interactive'`
- **Description**: Pattern to match blocks that should be executed in interactive mode

Blocks whose start line matches this pattern will be executed using the `play_bin_interactive` binary.

### Block Disable Match

- **Option**: `block_disable_match`
- **Environment Variable**: `MDE_BLOCK_DISABLE_MATCH`
- **Default**: `'@disable'`
- **Description**: Pattern to match blocks that should be disabled (not executable)

Blocks whose start line matches this pattern will be marked as disabled in the menu and cannot be executed. This is useful for documentation blocks, examples, or blocks that should be visible but not runnable.

### Execution Binaries

The following options control which binary is used for each execution mode:

#### Document Play Bin

- **Option**: `document_play_bin`
- **Environment Variable**: `MDE_DOCUMENT_PLAY_BIN`
- **Default**: `'play'`
- **Description**: Binary used for default block execution mode

This is the default binary used when a block doesn't match any special execution mode pattern.

#### Play Bin Batch

- **Option**: `play_bin_batch`
- **Environment Variable**: `MDE_PLAY_BIN_BATCH`
- **Default**: `'play'`
- **Description**: Binary used for batch mode block execution

This binary is used when a block matches the `block_batch_match` pattern.

#### Play Bin Interactive

- **Option**: `play_bin_interactive`
- **Environment Variable**: `MDE_PLAY_BIN_INTERACTIVE`
- **Default**: `'play_interactive'`
- **Description**: Binary used for interactive mode block execution

This binary is used when a block matches the `block_interactive_match` pattern.

## How It Works

### Execution Mode Selection

The execution mode is determined by checking the block's start line against these patterns in the following order:

1. First, check if the start line matches `block_interactive_match`
   - If matched → use `play_bin_interactive`
2. Then, check if the start line matches `block_batch_match`
   - If matched → use `play_bin_batch`
3. Otherwise → use `document_play_bin` (default)

This logic is implemented in `lib/hash_delegator.rb` in the `compile_execute_and_trigger_reuse` method (lines 1586-1596).

### Block Disabling

Block disabling is handled separately during menu filtering. If a block's start line matches `block_disable_match`, the block is marked as disabled (`TtyMenu::DISABLE`) and will appear in the menu but cannot be executed. This check happens in `lib/filter.rb` in the `apply_other_filters` method (lines 130-132).

**Note**: Disabled blocks are still visible in the menu but are shown as non-selectable/disabled. This is different from hidden blocks (which use `block_name_hide_custom_match` and are completely hidden from the menu).

## Usage Examples

### Batch Mode

To mark a block for batch execution, include `@batch` in the block's start line:

```bash :example-batch @batch
echo "This block will execute in batch mode"
echo "It uses play_bin_batch instead of document_play_bin"
```

### Interactive Mode

To mark a block for interactive execution, include `@interactive` in the block's start line:

```bash :example-interactive @interactive
echo "This block will execute in interactive mode"
echo "It uses play_bin_interactive"
```

### Disabled Blocks

To mark a block as disabled (visible but not executable), include `@disable` in the block's start line:

```bash :example-disabled @disable
echo "This block is visible but cannot be executed"
echo "It will appear in the menu but be marked as disabled"
```

### Custom Patterns

You can customize the patterns via configuration:

```opts
block_batch_match: '@batch-mode'
block_interactive_match: '@interactive-mode'
block_disable_match: '@skip'
```

Then use the custom markers:

```bash :custom-batch @batch-mode
echo "Custom batch marker"
```

```bash :custom-interactive @interactive-mode
echo "Custom interactive marker"
```

```bash :custom-disabled @skip
echo "Custom disabled marker"
```

### Custom Execution Binaries

You can also customize which binaries are used for each mode:

```opts
document_play_bin: 'play'
play_bin_batch: 'play_batch'
play_bin_interactive: 'play_interactive'
```

## Related Configuration

All options in this group work together:

- **Pattern Matching Options**:
  - `block_interactive_match`: Pattern for interactive mode (checked first)
  - `block_batch_match`: Pattern for batch mode (checked second)
  - `block_disable_match`: Pattern for disabled blocks (checked during filtering)

- **Binary Selection Options**:
  - `document_play_bin`: Binary for default mode (default: `play`)
  - `play_bin_batch`: Binary for batch mode (default: `play`)
  - `play_bin_interactive`: Binary for interactive mode (default: `play_interactive`)

## Related Documentation

- [Block Filtering](block-filtering.md) - Filtering options including `block_name_hide_custom_match`, `hide_blocks_by_name`
- [Execution Control](execution-control.md) - Execution control options including `user_must_approve`, `execute_in_own_window`
- [Block Naming Patterns](block-naming-patterns.md) - How block names are parsed
- [CLI Reference](cli-reference.md) - Command-line usage

