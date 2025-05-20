# Menu pagination indent

| Option| Value
| -| -
| select_page_height| &{select_page_height}
| screen_width| &{screen_width}

/ An Opts block
::: Indented with 2 spaces
  ```opts
  option1: 1
  option2: 2
  option3: 3
  option4: 4
  ```
::: Indented with 4 spaces
    ```opts
    option1: 1
    option2: 2
    option3: 3
    option4: 4
    ```
::: Indented with 1 tab
	```opts
	option1: 1
	option2: 2
	option3: 3
	option4: 4
	```

/ A shell block
::: Indented with 2 spaces
  ```
  : 1
  : 2
  : 3
  : 4
  ```
::: Indented with 4 spaces
    ```
    : 1
    : 2
    : 3
    : 4
    ```
::: Indented with 1 tab
	```
	: 1
	: 2
	: 3
	: 4
	```

| Variable| Value
| -| -
| VARIABLE| ${VARIABLE}

/ An UX block
::: Indented with 2 spaces
  ```ux
  init: false
  echo:
    VARIABLE1: 1
    VARIABLE2: 2
    VARIABLE3: 3
    VARIABLE4: 4
  name: VARIABLE1
  ```
::: Indented with 4 spaces
    ```ux
    init: false
    echo:
      VARIABLE1: 1
      VARIABLE2: 2
      VARIABLE3: 3
      VARIABLE4: 4
    name: VARIABLE1
    ```
::: Indented with 1 tab
	```ux
	init: false
	echo:
	  VARIABLE1: 1
	  VARIABLE2: 2
	  VARIABLE3: 3
	  VARIABLE4: 4
	name: VARIABLE1
	```


| Variable| Value
| -| -
| VARIABLE1| ${VARIABLE1}
| VARIABLE2| ${VARIABLE2}

/ A VARS block
::: Indented with 2 spaces
  ```vars
  VARIABLE1: 1
  VARIABLE2: 2
  VARIABLE3: 3
  VARIABLE4: 4
  ```
::: Indented with 4 spaces
    ```vars
    VARIABLE1: 1
    VARIABLE2: 2
    VARIABLE3: 3
    VARIABLE4: 4
    ```
::: Indented with 1 tab
	```vars
	VARIABLE1: 1
	VARIABLE2: 2
	VARIABLE3: 3
	VARIABLE4: 4
	```

@import bats-document-configuration.md
```opts :(document_opts)
screen_width: 48
select_page_height: 12
```