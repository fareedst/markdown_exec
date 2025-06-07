# UX Block Init and Act Keys

The `init` and `act` keys determine which other key is read for processing during initialization and activation respectively.

## Algorithm

1. **Init Phase** (when document is loaded) per FCB.init_source:
   - If `init` is `false`: No initialization occurs
   - If `init` is a string: That string becomes the initial value
   - If `init` is `:allow`: First value from `allow` list is used
   - If `init` is `:echo`: Value from `echo` key is evaluated and returned
   - If `init` is `:exec`: Command from `exec` key is executed and stdout is returned
   - If `init` is not present: Defaults to first available in order:
     - `:allow` if `allow` exists
     - `:default` if `default` exists
     - `:echo` if `echo` exists
     - `:exec` if `exec` exists
     - `false` if none of the above exist

2. **Act Phase** (when block is activated) per FCB.act_source:
   - If `act` is `false`: Block cannot be activated
   - If `act` is `:allow`: User selects from `allow` list
   - If `act` is `:echo`: Value from `echo` key is evaluated and returned
   - If `act` is `:edit`: User is prompted for input
   - If `act` is `:exec`: Command from `exec` key is executed and stdout is returned
   - If `act` is not present: Defaults to:
     - If `init` is `false`:
       - First available in order: `:allow`, `:echo`, `:edit`, `:exec`
     - Otherwise:
       - `:allow` if `allow` exists
       - `:edit` if `allow` does not exist

## Examples

### Echo on Init, Exec on Act
```ux
name: DEPLOY_CONFIG
init: :echo
echo: "Deploying ${VERSION} to ${ENVIRONMENT}"
act: :exec
exec: "deploy.sh ${ENVIRONMENT} ${VERSION}"
```
Behavior:
- On init: Evaluates echo string "Deploying ${VERSION} to ${ENVIRONMENT}"
- On act: Executes deploy.sh with environment and version parameters

### Allow on Init, Edit on Act
```ux
name: ENVIRONMENT
init: :allow
allow:
  - development
  - staging
  - production
act: :edit
prompt: Select environment
```
Behavior:
- On init: Uses first allowed value (development)
- On act: Prompts user to select from allowed values

### Exec on Init, Echo on Act
```ux
name: CURRENT_DIR
init: :exec
exec: basename $(pwd)
act: :echo
echo: "Current directory: ${CURRENT_DIR}"
```
Behavior:
- On init: Executes basename command on current directory
- On act: Evaluates echo string with current directory value

### Allow on Both
```ux
name: API_KEY
init: :allow
allow:
  - ${PROD_API_KEY}
  - ${STAGING_API_KEY}
  - ${DEV_API_KEY}
act: :allow
require:
  - ENVIRONMENT
```
Behavior:
- On init: Uses first allowed API key
- On act: Shows menu of allowed API keys for selection

### Echo on Both
```ux
name: SHELL_VERSION
init: :echo
echo: $SHELL
act: :echo
echo: "Using shell: ${SHELL_VERSION}"
```
Behavior:
- On init: Gets shell value from environment
- On act: Evaluates echo string with current shell value 