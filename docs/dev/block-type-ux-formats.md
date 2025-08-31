Demonstrate UX block appearance according to its state.

A simple variable declaration.
```ux
init: value1
name: VAR1
```

A selection from predefined options.
```ux
act: :allow
allow:
  - value2
name: VAR2
```

A computed value using command substitution.
```ux
act: :echo
echo: '`ls Gemfile`'
name: VAR3
```

An editable computed value.
```ux
act: :edit
echo: '`ls Gemfile`'
name: VAR4
```

A command execution with formatted output.
```ux
act: :exec
exec: ls Gemfile
name: VAR5
```

A read-only value.
```ux
exec: ls Gemfile
name: VAR6
readonly: true
```
@import bats-document-configuration.md
```opts :(document_opts)
menu_ux_row_format: 'DEFAULT %{name} = ${%{name}}'
menu_ux_row_format_allow: 'ALLOW %{name} = ${%{name}}'
menu_ux_row_format_echo: 'ECHO %{name} = ${%{name}}'
menu_ux_row_format_edit: 'EDIT %{name} = ${%{name}}'
menu_ux_row_format_exec: 'EXEC %{name} = ${%{name}}'
menu_ux_row_format_readonly: 'READONLY %{name} = ${%{name}}'
# menu_ux_color_readonly: fg_bg_rgbh_df_df_00_14_18_1c
menu_ux_color_allow: fg_rgbh_6f_00_7f
menu_ux_color_echo: fg_rgbh_3f_00_7f
menu_ux_color_edit: fg_rgbh_1f_00_7f
menu_ux_color_exec: fg_rgbh_1f_40_7f
menu_ux_color_readonly: fg_rgbh_1f_00_9f
```