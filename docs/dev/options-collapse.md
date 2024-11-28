/ All are collapsible
/ Only H2 is collapsed by default
# H1.1
L1.1
## H2.1
L2.1
### H3.1
L3.1
::: D4.1
L4.1
/ Collapse all
#+ H1.2
L1.2
##+ H2.2
L2.2
###+ H3.2
L3.2
:::+ D4.2
L4.2
/ Expand all
#- H1.3
L1.3
##- H2.3
L2.3
###- H3.3
L3.3
:::- D4.3
L4.3
@import bats-document-configuration.md
```opts :(document_opts)
divider4_center: false
divider4_collapse: false
divider4_collapsible: true
heading1_center: false
heading1_collapse: false
heading1_collapsible: false
heading2_center: false
heading2_collapse: true
heading2_collapsible: true
heading3_center: false
heading3_collapse: false
heading3_collapsible: true

heading1_match: "^#(?<line>(?!#)(?<collapse>[+-~]?)(?<indent>[ \t]*)(?<text>.*?)(?<trailing>[ \t]*))?$"
menu_collapsible_symbol_collapsed: '(+)'
menu_collapsible_symbol_expanded: '(-)'
```