# Exercise options that control blocks of shell code
::: Specified block (shell) type
- Bash
	```bash :bash +[show-shell-version]
	echo "genus"
	```
- Fish
	```fish :fish +[show-shell-version]
	echo "genus"
	```
- Sh
	```sh :sh +[show-shell-version]
	echo "family"
	```

::: Unspecified block type
Option `bash_only`: When `true`, display and disable blocks that do not have a shell type.
	```opts
	bash_only: true
	```
	```opts
	bash_only: false
	```

This block has no (shell) type. It will execute as the default shell type.
	``` :block-with-no-shell-type
	echo "species"
	```
	It will not appear if `bash_only` is `true`.

This block has no (shell) type. It will execute as the default shell type.
	``` :[show-shell-version]
	# Initialize the shell_type variable
	shell_type="unknown"

	parent_shell=$(ps -o comm= -p $$)

	# Check for Sh
	if [ "$parent_shell" = "sh" ]; then
      shell_type="sh"
	# Check if we're in Fish shell
	elif command -v fish >/dev/null 2>&1 && fish -c 'exit' >/dev/null 2>&1; then
	    shell_type="fish"
	# Check for Bash
	elif [ -n "$BASH_VERSION" ]; then
	    shell_type="bash"
	# Check for Zsh
	elif [ -n "$ZSH_VERSION" ]; then
	    shell_type="zsh"
	# Check for tcsh
	elif [ -n "$tcsh" ]; then
	    shell_type="tcsh"
	# Check for ksh
	elif [ -n "$KSH_VERSION" ]; then
	    shell_type="ksh"
	# If none of the above, assume it's sh
	else
	    case "$0" in
	        *sh) shell_type="sh" ;;
	    esac
	fi

	# Print the result
	# echo "Detected shell: $shell_type"

	# For Fish shell, we need to use 'set' instead of '='
	if [ "$shell_type" = "fish" ]; then
	    fish -c "set -g detected_shell $shell_type"
	else
	    detected_shell=$shell_type
	fi

	# Verify the variable is set (this will work in sh and bash)
	# echo "Shell type saved in variable: $detected_shell"

	# For Fish, we need to use a separate command to display the variable
	if [ "$shell_type" = "fish" ]; then
	    fish -c "echo \"Shell type saved in variable: \$detected_shell\""
	fi

	echo "detected_shell: $detected_shell"
	```
	It will not appear if `bash_only` is `true`.

@import bats-document-configuration.md
```opts :(document_options)
bash_only: false
```
