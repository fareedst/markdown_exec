# Demo configuring options
/ v2025-09-30
::: These Opts blocks set the color for all elements.
/ blue    fg_rgbh_00_00_FF
/ green   fg_rgbh_00_FF_00
/ indigo  fg_rgbh_4B_00_82
/ orange  fg_rgbh_FF_7F_00
/ red     fg_rgbh_FF_00_00
/ violet  fg_rgbh_94_00_D3
/ yellow  fg_rgbh_FF_FF_00
```opts :load_colors
exception_color_detail: fg_rgbh_1f_00_7f
exception_color_name: fg_rgbh_1f_00_00
execution_report_preview_frame_color: fg_rgbh_7f_1f_00
menu_bash_color: fg_rgbh_00_c0_c0
menu_block_color: fg_rgbh_47_ce_eb
menu_chrome_color: fg_rgbh_40_c0_c0
menu_divider_color: fg_rgbh_80_d0_c0
menu_edit_color: fg_rgbh_e0_e0_20
menu_history_color: fg_rgbh_e0_e0_20
menu_link_color: fg_rgbh_e0_e0_20
menu_load_color: fg_rgbh_e0_e0_20
menu_note_color: fg_rgbh_b0_b0_b0
menu_opts_color: fg_rgbh_1f_00_1f
menu_opts_set_color: fg_rgbh_7f_00_1f
menu_save_color: fg_rgbh_e0_e0_20
menu_task_color: fg_rgbh_1f_1f_1f
menu_ux_color: fg_rgbh_2f_c0_2f
menu_vars_color: fg_rgbh_1f_a0_1f
menu_vars_set_color: fg_rgbh_00_1f_1f
output_execution_label_name_color: fg_rgbh_00_1f_00
output_execution_label_value_color: fg_rgbh_00_1f_00
prompt_color_after_script_execution: fg_rgbh_00_1f_00
script_execution_frame_color: fg_rgbh_00_1f_7f
script_preview_frame_color: fg_rgbh_7f_1f_00
warning_color: fg_rgbh_1f_7f_00
```

/ more green, less blue
```opts :load_colors2
exception_color_detail: fg_rgbh_ff_00_7f
exception_color_name: fg_rgbh_ff_00_00
execution_report_preview_frame_color: fg_rgbh_7f_ff_00
menu_bash_color: fg_rgbh_00_c0_c0
menu_block_color: fg_rgbh_47_fe_bb
menu_chrome_color: fg_rgbh_40_c0_c0
menu_divider_color: fg_rgbh_80_d0_c0
menu_edit_color: fg_rgbh_e2_e2_20
menu_history_color: fg_rgbh_e4_e4_20
menu_link_color: fg_rgbh_e6_e6_20
menu_load_color: fg_rgbh_e8_e8_20
menu_note_color: fg_rgbh_b0_b0_b0
menu_opts_color: fg_rgbh_ff_00_ff
menu_opts_set_color: fg_rgbh_7f_00_ff
# menu_save_color: fg_rgbh_ea_ea_20
menu_save_color: fg_rgbh_ff_ff_20
menu_task_color: fg_rgbh_ff_ff_ff
menu_ux_color: fg_rgbh_df_c0_df
menu_vars_color: fg_rgbh_ff_a0_ff
menu_vars_set_color: fg_rgbh_00_ff_ff
output_execution_label_name_color: fg_rgbh_00_ff_00
output_execution_label_value_color: fg_rgbh_00_ff_00
prompt_color_after_script_execution: fg_rgbh_00_ff_00
script_execution_frame_color: fg_rgbh_00_ff_7f
script_preview_frame_color: fg_rgbh_7f_ff_00
warning_color: fg_rgbh_ff_7f_00
```

::: Divider color

::: Fenced code blocks of different types
Each block has a name. Its name is decorated according to the type of the block.
``` :Unspecified1
```
```unknown :Unknown1
```
```bash :Bash1
```
/ Chrome decoration
```edit :Edit-inherited-blocks
```
```history :History1
```
```link :Link1
```
```load :Load1
```
/ Note decoration
A Note
/ Opts decoration
```opts :Opts1
```
```port :Port1
```
/ Save decoration
```save :Save1
```
/ Task decoration
[ ] Task
/ UX decoration
```ux
format: UX-1
```
/ Vars decoration
```vars :Vars1
```