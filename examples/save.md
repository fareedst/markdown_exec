# Demonstrate custom file names
```opts :(document_options) +[custom]
pause_after_script_execution: true  # for interactive demos
save_executed_script:         true  # demonstrate saved scripts
save_execution_output:        true  # demonstrate saved output
```

## Related MDE options
save_executed_script   |  Whether to save an executed script
save_execution_output  |  Save standard output of the executed script
saved_asset_format     |  Format for script and log file names
saved_asset_match      |  Regexp for script and log file names
saved_history_format   |  Format for each row displayed in history

### Add "DOMAIN" shell expansion. Include a wildcard as default to allow for matching when undefined.
::: Default
```opts
saved_asset_format: "%{prefix}%{join}%{time}%{join}%{filename}%{join}%{mark}%{join}%{blockname}%{join}%{exts}"
```
::: Custom
```opts :[custom]
# Add "DOMAIN" shell expansion. Include a wildcard as default to allow for matching when undefined.
saved_asset_format: "%{prefix}%{join}${DOMAIN:-*}%{join}%{time}%{join}%{filename}%{join}%{mark}%{join}%{blockname}%{join}%{exts}"
```
### Add "domain" capture group
::: Default
```opts
saved_asset_match: "^(?<prefix>.+)(?<join>_)(?<time>[0-9\\-]+)\\g'join'(?<filename>.+)\\g'join'(?<mark>~)\\g'join'(?<blockname>.+)\\g'join'(?<exts>\\..+)$"
```
::: Custom
```opts :[custom]
# Add "domain" capture group
saved_asset_match: "^(?<prefix>.+)(?<join>_)(?<domain>.*)\\g'join'(?<time>[0-9\\-]+)\\g'join'(?<filename>.+)\\g'join'(?<mark>~)\\g'join'(?<blockname>.+)\\g'join'(?<exts>\\..+)$"
```
### Add "domain" to history display
::: Default
```opts
saved_history_format: "%{time}  %{blockname}  %{exts}"
```
::: Custom
```opts :[custom]
# Add "domain" to history display
saved_history_format: "%{domain}  %{time}  %{blockname}  %{exts}"
```

## Append to Inherited Lines
::: Load the DOMAIN variable.
1. Set DOMAIN to "site.local"
```vars
DOMAIN: site.local
```

2. Set DOMAIN to "site.remote"
```vars
DOMAIN: site.remote
```

- Notice how the history changes according to the current DOMAIN.

## Saved files
::: Run this command to generate files for the script and the output of the execution.
```bash :test
echo "$(date -u)"
```
- Notice how the saved files increase by 2 with every execution.
