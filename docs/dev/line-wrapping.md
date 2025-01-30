# Demo wrapping long lines

MDE detects the screen's dimensions: height (lines) and width (characters)

Normal document text is displayed as disabled menu lines. The width of these lines is limited according to the screen's width.

::: Test Indented Lines

  Indented with two spaces, this line should wrap in an aesthetically pleasing way.

	Indented with a tab, this line should wrap in an aesthetically pleasing way.

# species genus family order class phylum kingdom domain
## species genus family order class phylum kingdom domain
@import bats-document-configuration.md
```opts :(document_opts)
divider4_center: false
heading1_center: true
heading2_center: false
screen_width: 48

menu_note_match: "^(?<indent>[ \t]*)(?<line>(?!/)(?<text>.*?)(?<trailing>[ \t]*))?$"

```