# Demonstrate Setting Variables in the Inherited Lines

```link :select-a-folder +(select-a-folder)
eval: true
```
```bash :(select-a-folder)
echo "PT=$(osascript -e 'do shell script "echo " & quoted form of POSIX path of (choose folder with prompt "Please select a folder:")' 2>/dev/null)"
```

This table displays the value of variables in the context of the current inherited lines. At first, the variable is empty unless it exists in the current shell environment.

| Variable| Value
| -| -
| SPECIES| ${SPECIES}

## Current Inherited Lines

```view
View the current inherited lines.
```

The inherited lines can also be displayed automatically within the menu by enabling this option:

```opts
menu_with_context_code: true
```

## Setting Variables in the Inherited Lines

You can set environment variables in the inherited lines by adding shell expressions. For example, a line such as `SPECIES=Unknown` in the inherited lines defines a variable that can be used in the rest of the executed script.

Below are several ways to add such expressions to the inherited lines:

### Vars Block

This block (YAML) adds a variable and its value to the inherited lines:

```vars
SPECIES: Tapanuli Orangutan
```

### Link Block

This block (YAML) also adds a variable and its value to the inherited lines:

    ```link
    vars:
      SPECIES: Psychedelic Frogfish
    ```

### Link+Bash Blocks

::: Adding Code to the Inherited Lines

This Link block (YAML) appends the Bash code defined in the referenced block to the inherited lines:

    ```link :add-bash-code +[bash_species]
    ```
        ```bash :[bash_species] @disable
        SPECIES='Ruby Seadragon'
        ```

If necessary to extract environment variable values displayed in the menu, inherited lines are executed every time the menu displayed. Therefore, do add code that has unwanted side effects when executed multiple times.

::: Adding Evaluated Code Output to the Inherited Lines

This Link block (YAML) appends the output of the Bash code to the inherited lines. The Bash code is executed first to generate the output:

    ```link :add-evaluated-bash-code +[bash_species_code]
    eval: true
    ```
        ```bash :[bash_species_code] @disable
        echo "SPECIES='Illacme tobini (Millipede)'"
        ```

| Variable| Value
| -| -
| SPECIES| ${SPECIES}

@import example-document-opts.md
```opts :(document_opts)
execute_in_own_window: false
menu_with_context_code: false
output_execution_report: false
output_execution_summary: false
pause_after_script_execution: true
```