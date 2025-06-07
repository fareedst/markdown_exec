/ 1. Simple variable display and edit:
```ux
init: Guest
name: USER_NAME
prompt: Enter your name
```
/Behavior: Displays the USER_NAME variable. When clicked, prompts for input with "Enter your name" and defaults to "Guest" if no input is provided.
/
/2. Command output initialization:
```ux
name: CURRENT_DIR
init: :exec
exec: basename $(pwd)
transform: :chomp
```
/Behavior: Initializes CURRENT_DIR with the output of the `pwd` command when the document loads.
/
/3. Echo-based initialization:
```ux
name: SHELL_VERSION
init: :echo
echo: $SHELL
```
/Behavior: Sets SHELL_VERSION to the value of the $SHELL environment variable when the document loads.
/
/4. Selection from allowed values:
```ux
name: ENVIRONMENT
allow:
  - development
  - staging
  - production
prompt: Select environment
```
/Behavior: When activated, presents a menu to select from development, staging, or production environments.
/
/## Validation Examples
/
/5. Email validation:
```ux
name: USER_EMAIL
prompt: Enter email address
validate: '(?<local>[^@]+)@(?<domain>[^@]+)'
transform: '%{local}@%{domain}'
```
/Behavior: Validates input as an email address, capturing local and domain parts. The transform ensures proper formatting.
/
/6. Version number validation:
```ux
name: VERSION
prompt: Enter version number
validate: '(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)'
transform: '%{major}.%{minor}.%{patch}'
```
/Behavior: Ensures input follows semantic versioning format (e.g., 1.2.3).
/
@import bats-document-configuration.md