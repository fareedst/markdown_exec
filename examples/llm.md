1. show practical examples for three important Bash commands.
2. the commands must rely only on resources created and deleted in the example

Let's create practical examples for three important Bash commands where all resources are created and deleted within the examples. The commands we'll use are `touch` (to create a file), `echo` (to write to a file), and `rm` (to delete a file).

### 1. `touch` - Create an Empty File

**Purpose**: `touch` is used to create an empty file or update the timestamp of an existing file.

**Example**: Create an empty file named `example.txt`.

```bash
touch example.txt
```

### 2. `echo` - Write to a File

**Purpose**: `echo` is used to display a line of text. Combined with redirection, it can write text to a file.

**Example**: Write "Hello, world!" to `example.txt`.

```bash
echo "Hello, world!" > example.txt
```

### 3. `rm` - Remove a File

**Purpose**: `rm` is used to remove files or directories.

**Example**: Delete the `example.txt` file.

```bash
rm example.txt
```

**Combined Script**: To see all these commands in action, you can create a script that executes them sequentially:

```bash
#!/bin/bash

# Create an empty file
touch example.txt

# Write text to the file
echo "Hello, world!" > example.txt

# Display the file content
cat example.txt

# Remove the file
rm example.txt
```

**Note**: After this script runs, `example.txt` is created, written to, displayed, and then deleted, ensuring that no external resources are used or left behind.