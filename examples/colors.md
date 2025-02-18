# Demo configuring options

::: These Opts blocks set the color for all elements.

<https://en.wikipedia.org/wiki/Complementary_colors#/media/File:RGB_color_wheel.svg>

/ ff0000 red - exception text
/ ff7f00 orange - warning text
/ ffff00 yellow - notification text
/ 7fff00 chartreuse green - output frame
/ 00ff00 green - prompt
/ 00ff7f spring green - input frame
/ 00ffff cyan - menu text
/ 007fff azure - menu frame
/ 0000ff blue
/ 7f00ff violet - opts frame
/ ff00ff magenta - opts text
/ ff007f rose - exception frame

```opts :load_colors
exception_color_detail: fg_rgbh_1f_00_7f
exception_color_name: fg_rgbh_1f_00_00
execution_report_preview_frame_color: fg_rgbh_7f_1f_00
menu_bash_color: fg_rgbh_00_c0_c0
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

```opts :load_colors2
exception_color_detail: fg_rgbh_ff_00_7f
exception_color_name: fg_rgbh_ff_00_00
execution_report_preview_frame_color: fg_rgbh_7f_ff_00
menu_bash_color: fg_rgbh_00_c0_c0
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

::: Example blocks
```
```
```bash :Bash1
```
```edit :Edit1
```
```history :History1
```
```link :Link1
```
```load :Load1
```
```opts :Opts1
```
```port :Port1
```
```save :Save1
```
```vars :Vars1
```
[ ] Task1

/ blue;    fg_rgbh_00_00_FF
/ green;   fg_rgbh_00_FF_00
/ indigo;  fg_rgbh_4B_00_82
/ orange;  fg_rgbh_FF_7F_00
/ red;     fg_rgbh_FF_00_00
/ violet;  fg_rgbh_94_00_D3
/ yellow;  fg_rgbh_FF_FF_00
