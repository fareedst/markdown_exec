/ v2025-12-07
/---

# App configuration

## CLI loading of app configuration

A file is read into the app configuration using the `--config` command line option.

## Per-document app configuration

An OPTS block that is automatically loaded when the document is loaded, modifies the app configuration.

## Activated block effect on app configuration

An OPTS block that is activated by the user modifies the app configuration.

/---

# Context code

The context code is empty when the app starts.

## CLI loading of context code

A file is loaded as the context code using the `--load-code` command line option.

## Automatic blocks

Some blocks are automatically processed when the document is loaded.

A VARS block that is automatically loaded when the document is loaded, is appended to the context code.  Display variables set per the app configuration.

A UX block that is automatically loaded, is appended to the context code.  Display variables set per the app configuration.

A shell block that is automatically loaded is appended to the context code.

## Activated VARS block

The variables named, converted to shell code to set to the corresponding values, are appended to the context code.
The app's environment is also updated with the specified variables and values.

## Activated UX block

Variables named, converted to shell code to set to the corresponding values, are appended to the context code.
The app's environment is also updated with the specified variables and values.

## Activated shell block

The activated and required shell blocks marked as context are appended to the context code.

/---

# Transient code

The transient code is empty between block activations.

## Activated shell block

The required blocks, the transient code for this block, are executed in a shell script and its output is displayed and logged.

/---

# Shell script composition

The shell script is composed of the context code followed by the transient code. The context code will include variables or context code in the required blocks.

## Script output

The output of the executed script (STDOUT and STDERR) is displayed in the console and logged to a file.

/---

## Shell block activation

The activated and required shell blocks, not marked as context by default, are are the transient code.
The script is composed and executed.
Display shell output per the app configuration.
