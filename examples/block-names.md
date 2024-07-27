## Demonstrate handling of special characters in block names
The hidden block "(success)" is required below. It prints "Success".
```bash :(success)
echo "Success"
```
Block names with all chars.
/ UTF-8
/   !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~
/   ¡¢£¤¥¦§¨©ª«¬®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ
::: Click below to trigger. If it prints "Success", the Link block was processed.
This block name uses the printable characters in the first 128 values. It is executable.
    ```link :!"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~
    block: (success)
    ```
This block name uses the printable characters in the second 128 values. It is executable.
    ```link :¡¢£¤¥¦§¨©ª«¬®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ
    block: (success)
    ```

## Block formatting
The un-named block should display correctly.
    ```link
    file: examples/linked2.md
    block: show_vars
    vars:
      page2_var_via_environment: for_page2_from_page1_via_current_environment
    ```
