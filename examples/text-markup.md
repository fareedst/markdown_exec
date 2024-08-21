# Demonstrate Decoration of Text

## LINE_DECOR_MAIN
These are the Main decorations predefined:

- **_Bold-Underline_**
- **~Bold-Italic~**
- **Bold**
- __Bold__
- *Underline*
- _~Underline-Italic~_
- ~~Strikethrough~~
- `code`

## LINE_DECOR_PRE
These decorations are performed before Main, allowing for overrides without redefining Main.

### Override Bold Underline
This **_text_** is bold and underlined by default.
::: Select below to trigger. If it changes to yellow, the option was processed.
    ```opts :[bold-underline]
    line_decor_pre:
      - :color_method: :yellow
        :pattern: '\*\*_([^_]{0,64})_\*\*'
    ```
This **_text_** is yellow when the rule takes precedence over the Main decorations.

## LINE_DECOR_POST
These decorations are performed after the Main decorations.
This !!text!! is not decorated by default.
::: Select below to trigger. If it changes to green, the option was processed.
    ```opts :[green]
    line_decor_post:
      - :color_method: :green
        :pattern: '!!([^!]{0,64})!!'
    ```

## MDE Non-standard Markdown Configuration
- `_text_`: A single underscore delimeter is a standard way of underlining text. Because this occurs in code often, this decoration is not a default for MDE.

## Precedence
The order decorations are processed affects results.
A Bold delimiter `__` has to be processed before the Underline delimeter `_`. If reversed, bold `text` appears as underlined `_text_`.

# Related MDE Options
line_decor_main  |  Line-oriented text decoration (Main)
line_decor_post  |  Line-oriented text decoration (Post)
line_decor_pre   |  Line-oriented text decoration (Pre)
menu_note_match  |  Pattern for notes in block selection menu

```opts :(document_options)
line_decor_post:
  - :color_method: blue
    :pattern: '!([^!]{0,64})!blue!'
  - :color_method: green
    :pattern: '!([^!]{0,64})!green!'
  - :color_method: red
    :pattern: '!([^!]{0,64})!red!'
```
