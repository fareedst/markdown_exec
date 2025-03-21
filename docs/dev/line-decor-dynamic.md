/ Demonstrate dynamic color names
/ line_decor_pre is performed before line_decor_main and line_decor_post
%Species%
@import bats-document-configuration.md
```opts :(document_opts)
line_decor_pre:
  # bold italicized bright yellow text on light yellow background
  - :color_method: :ansi_1__3__38_2_200_200_33__48_2_60_60_32__22_23_0
    :pattern: '%([^_]{0,64})%'
```