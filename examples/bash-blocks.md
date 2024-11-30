# Demonstrate requiring shell blocks
## Requiring a named block
::: Select below to trigger. If it prints "species", "genus", the required block was processed.
The un-named block prints "species" and requires block "genus".
    ```bash +genus
    echo "species"
    ```
::: Select below to trigger. If it prints "genus", the block was processed.
The named block prints "genus".
    ```bash :genus
    echo "genus"
    ```

## Requiring a block with a nickname and a hidden block
::: Select below to trigger. If it prints "family", "order", "class" the required blocks were processed.
The named block prints "family" and requires blocks "[order]" and "(class)".
    ```bash :family +[order] +(class)
    echo "family"
    ```
The nick-named block "[order]" is required above. It prints "order".
    ```bash :[order]
    echo "order"
    ```
The hidden block "(class)" is required above. It prints "class".
    ```bash :(class)
    echo "class"
    ```

## Requiring a before-and-after block pair
The hidden block "{phylum-domain}", prints "phylum".
    ```bash :{phylum-domain}
    echo "phylum"
    ```
The hidden block "{phylum-domain-after}", prints "domain".
    ```bash :{phylum-domain-after}
    echo "domain"
    ```
The hidden block "(biology)" prints "biology".
    ```bash :(biology)
    echo "biology"
    ```
::: Select below to trigger. If it prints "biology", "phylum", "kingdom", "domain", and "taxonomy" the required blocks were processed.
The named block prints "kingdom" and requires blocks wrapper blocks "{phylum-domain}" and "{phylum-domain-after}".
Notice the wrapper blocks are exclusive to the single block with the requirement.
    ```bash :kingdom +{phylum-domain} +(biology) +(taxonomy)
    echo "kingdom"
    ```
The hidden block "(taxonomy)" prints "taxonomy".
    ```bash :(taxonomy)
    echo "taxonomy"
    ```

@import example-document-opts.md
```opts :(document_opts)
execute_in_own_window: false
output_execution_report: false
output_execution_summary: false
pause_after_script_execution: true
```