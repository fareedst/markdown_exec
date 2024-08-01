# This document demonstrates the indentation of blocks and text

Indentation is either leading spaces or tabs.
Tabs are interpreted as 4 spaces.

## Related MDE options
fenced_start_and_end_regex   |  Matches the start and end of a fenced code block
fenced_start_extended_regex  |  Match the start of a fenced block
heading1_match               |  MDE_HEADING1_MATCH
heading2_match               |  MDE_HEADING2_MATCH
heading3_match               |  MDE_HEADING3_MATCH
menu_divider_match           |  Pattern for topics/dividers in block selection menu
menu_note_match              |  Pattern for notes in block selection menu
menu_task_match              |  Pattern for tasks

::: Flush divider, text, block, and comment
Text
```bash
echo 'This is a very long string to force line wrapping in the interface.'
 # comment indented 1 space
```
/ Comment

  ::: Indented (2 spaces) text, block, and comment
  Text
  ```bash
  echo 'This is a very long string to force line wrapping in the interface.'
  # comment indented 1 space
  ```
  / Comment

	::: Indented (1 tab) text, block, and comment
	Text
	```bash
	echo 'This is a very long string to force line wrapping in the interface.'
	 # comment indented 1 space
	```
	/ Comment


This is a concise guide for using Bash commands to find and list recent files in a Linux system. The commands are safe to use and can help you quickly locate recently modified or accessed files.

1. **List Recently Modified Files**:
   You can use the `ls` command with sorting options to list recently modified files in the current directory.

   ```bash
   ls -lt
   ```

2. **Using `stat` for File Details**:
   To get detailed information about file modifications, access, and change, use the `stat` command.

   Example for a specific file:
   ```bash
   stat .
   ```

3. **Find Files**:
   A. **Find Files Modified in the Last N Days**:
      The `find` command is useful for searching files modified within a specific number of days.

      For example, to find files modified in the last 7 days:
      ```bash
      find . -type f -mtime -7
      ```

   B. **Display Files Accessed Recently**:
      Similarly, you can list files that were accessed recently using the `find` command.

      1. To list files accessed in the last 3 days:
         ```bash
         find . -type f -atime -3
         ```

      2. **Advanced Search with `find`**:
         Combine `find` with other commands for advanced searching. For instance, to list and sort files by modification time:

         ```bash
         find . -type f -mtime -7 -exec ls -lt {} +
         ```

These commands provide a basic way to manage and track file modifications and access on your system. They are particularly useful for system administration and file management tasks.

```link :Link1
```
   ::: Indented (4 spaces) Link block
   ```link :Link2
   ```

```opts :Opts1
```

   ::: Indented (4 spaces) Opts block
   ```opts :Opts2
   ```

```port :Port1
```

   ::: Indented (4 spaces) Port block
   ```port :Port2
   ```

```vars :Vars1
```

   ::: Indented (4 spaces) Vars block
   ```vars :Vars2
   ```
