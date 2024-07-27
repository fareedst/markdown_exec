# Demonstrate requiring blocks
```opts :(document_options) +(custom) +[custom]
menu_divider_color: red     # color to indicate failure
```
```opts :(custom)
menu_divider_color: green   # color to indicate success
```
## Automatic documents options
::: If this text is green, the required Opts block was processed; if this text is red, the required Opts block was NOT processed hidden, name: "(custom)"

## Click this named block to test
::: Click below to trigger. If this text starts with "+++", the required Opts block was processed; name: "custom"
    ```opts :custom
    menu_divider_format: "+++ %{line}"   # format to indicate success
    ```

## Click this nicknamed block to test
::: Click below to trigger. If this text starts with "!!!", the Opts block was processed; name: "[custom]"
This block has a nickname "[custom]". It is executable.
    ```opts :[custom]
    menu_divider_format: "!!! %{line}"   # format to indicate success
    ```

## Click this unnamed block to test
::: Click below to trigger. If this text starts with "@@@", the required Opts block was processed; unnamed
    ```opts
    menu_divider_format: "@@@ %{line}"   # format to indicate success
    ```
