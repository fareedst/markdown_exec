## Demonstrate handling of special characters in block names

::: Click below to trigger. If it prints "1","2","3","4", the Link blocks were required.
Long block names can be required by a Bash block.
    ```bash :calling-block +long_block_name_12345678901234567890123456789012345678901234567890 +(long_block_name_12345678901234567890123456789012345678901234567890) +[long_block_name_12345678901234567890123456789012345678901234567890]
    echo '1'
    ```
Long block names can be used in Link blocks.
    ```link
    block: long_block_name_12345678901234567890123456789012345678901234567890
    ```
    ```link
    block: "(long_block_name_12345678901234567890123456789012345678901234567890)"
    ```
    ```link
    block: "[long_block_name_12345678901234567890123456789012345678901234567890]"
    ```

    Do not call these blocks directly.
        ```bash :long_block_name_12345678901234567890123456789012345678901234567890
        echo '2'
        ```
        ```bash :(long_block_name_12345678901234567890123456789012345678901234567890)
        echo '3'
        ```
        ```bash :[long_block_name_12345678901234567890123456789012345678901234567890]
        echo '4'
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
The hidden block "(success)" is required above. It prints "Success".
```bash :(success)
echo "Success"
```

```opts :(document_options)
execute_in_own_window: false
output_execution_report: false
output_execution_summary: false
pause_after_script_execution: true
```
