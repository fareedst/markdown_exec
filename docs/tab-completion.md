# Tab Completion

This document describes how to install and use tab completion for MarkdownExec.

## Install tab completion

Append a command to load the completion script to your shell configuration file. `mde` must be executable for the command to be composed correctly.

```bash
echo "source $(mde --pwd)/bin/tab_completion.sh" >> ~/.bash_profile
```

## Behavior

Press tab for completions appropriate to the current input.
`mde <...> <prior word> <current word><TAB>`

Completions are calculated based on the current word and the prior word. 
1. If the current word starts with `-`, present matching options, eg `--version` for the current word `--v`.
2. Else, if the current word is empty and the prior word is an option that takes an argument, present the type of the argument, eg `.BOOL.` for the option `--user-must-approve`.
3. Else, if the current word is the type of argument, from the rule above, present the default value for the option. e.g. `1` for the type `.BOOL.` for the option `--user-must-approve`.
4. Else, if the current word is non-empty, list matching files and folders.

## Example Completions

In the table below, tab is indicated by `!`
| Input | Completions |
| :--- | :--- |
| `mde !` | local files and folders |
| `mde -!` | all options |
| `mde --!` | all options |
| `mde --v!` | `mde --version` |
| `mde --user-must-approve !` | `mde --user-must-approve .BOOL.`|
| `mde --user-must-approve .BOOL.!` | `mde --user-must-approve 1` |

## Related Documentation

- [CLI Reference](cli-reference.md) - Complete command-line reference
- [Getting Started](getting-started.md) - Quick start guide

