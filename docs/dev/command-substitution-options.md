/ command substitution options to use different patterns
/
@import bats-document-configuration.md
/
```vars :(document_vars)
Common_Name: Tapanuli Orangutan
Species: Pongo tapanuliensis
```
/
::: Command substitution

The current value of environment variable `Common_Name` is displayed using two different prefixes.
The command `echo $SHLVL` is executed via command substitution, using two different prefixes.

| Prefix| Variable Expansion| Command Substitution
| -| -| -
| $| ${Common_Name}| $(echo $Species)
| @| @{Common_Name}| @(echo $Species)

::: Toggle between prefixes.

/| MDE Option| Value
/| -| -
/| command_substitution_regexp| &{command_substitution_regexp}
/| menu_ux_row_format| &{menu_ux_row_format}
/| variable_expansion_regexp| &{variable_expansion_regexp}

/ This block requires a hidden block.
```opts :prefix_$ +(prefix_$2)
command_substitution_regexp: '(?<expression>\$\((?<command>([^()]*(\([^()]*\))*[^()]*)*)\))'
```
```opts :(prefix_$2)
menu_ux_row_format: '%{name}=${%{name}}'
variable_expansion_regexp: '(?<expression>\${(?<variable>[A-Z0-9a-z_]+)})'
```

```opts :prefix_@
command_substitution_regexp: '(?<expression>@\((?<command>([^()]*(\([^()]*\))*[^()]*)*)\))'
menu_ux_row_format: '%{name}=@{%{name}}'
variable_expansion_regexp: '(?<expression>@{(?<variable>[A-Z0-9a-z_]+)})'
```

```opts :(both)
command_substitution_regexp: '(?<expression>[\$\@]\((?<command>([^()]*(\([^()]*\))*[^()]*)*)\))'
menu_ux_row_format: '%{name}=${%{name}}'
variable_expansion_regexp: '(?<expression>[\$\@]{(?<variable>[A-Z0-9a-z_]+)})'
```
/
/ Require the block that sets @ as the prefix.
```opts :(document_opts) +prefix_@
divider4_collapsible: false
heading1_center: false
heading2_center: false
heading3_center: false
menu_final_divider:
menu_for_saved_lines: false
menu_initial_divider:
menu_vars_set_format:
table_center: false
```