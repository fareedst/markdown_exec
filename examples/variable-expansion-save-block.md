```vars :sample-configuration
NAME: name01
```
	- NAME: ${NAME}

```link :enter-variable-value +(enter-variable-value)
exec: true
```
```bash :(enter-variable-value)
echo >&2 "NAME [$NAME]?: "
read -r response
echo "NAME=$(printf "%q" "${response:-$NAME}")"
```

```history :list_ec2_instance_configuration_files
directory: test
filename_pattern: '^(?<name>.*)$'
glob: '*.sh'
view: '%{name}'
```

```load :load_configuration_document_from_directory
directory: test
glob: '*.sh'
```

```save :save_stack_file_names
directory: test
glob: "${NAME}.sh"
```

```bash :loggable-action
echo `date -u`
```
```opts :(document_opts)
save_executed_script: true
save_execution_output: true

# Add "NAME" named group to default shell expansion.
# Include a wildcard as default to allow for matching when undefined.
saved_asset_format: "%{prefix}%{join}${NAME:-*}%{join}%{time}%{join}%{filename}%{join}%{mark}%{join}%{blockname}%{join}%{exts}"

# Add "name" capture group to default expression
saved_asset_match: "^(?<prefix>.+)(?<join>_)(?<name>.*)\\g'join'(?<time>[0-9\\-]+)\\g'join'(?<filename>.+)\\g'join'(?<mark>~)\\g'join'(?<blockname>.+)\\g'join'(?<exts>\\..+)$"

# Add "name" capture group to default format
saved_history_format:         "%{name}  %{time}  %{blockname}  %{exts}"
```