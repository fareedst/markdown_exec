# UX Block Test Cases

This document contains test cases for all possible combinations of `init` and `act` behaviors.

## Test Cases

### 1. Explicit Init and Act

#### 1.1 Init: allow, Act: allow
```ux
name: ENVIRONMENT
init: :allow
allow:
  - development
  - staging
  - production
act: :allow
```
Behavior:
- Init: Uses first allowed value (development)
- Act: Shows menu of allowed values

#### 1.2 Init: allow, Act: echo
```ux
name: ENVIRONMENT
init: :allow
allow:
  - development
  - staging
  - production
act: :echo
echo: "Selected environment: ${ENVIRONMENT}"
```
Behavior:
- Init: Uses first allowed value (development)
- Act: Evaluates echo string with current value

#### 1.3 Init: allow, Act: edit
```ux
name: ENVIRONMENT
init: :allow
allow:
  - development
  - staging
  - production
act: :edit
prompt: "Select environment"
```
Behavior:
- Init: Uses first allowed value (development)
- Act: Prompts for input

#### 1.4 Init: allow, Act: exec
```ux
name: ENVIRONMENT
init: :allow
allow:
  - development
  - staging
  - production
act: :exec
exec: "echo 'Deploying to ${ENVIRONMENT}'"
```
Behavior:
- Init: Uses first allowed value (development)
- Act: Executes command with current value

### 2. Default Init (no init key)

#### 2.1 Default Init (allow), Act: allow
```ux
name: ENVIRONMENT
allow:
  - development
  - staging
  - production
act: :allow
```
Behavior:
- Init: Uses first allowed value (development)
- Act: Shows menu of allowed values

#### 2.2 Default Init (default), Act: allow
```ux
name: ENVIRONMENT
default: development
act: :allow
```
Behavior:
- Init: Uses default value (development)
- Act: Shows menu of allowed values

#### 2.3 Default Init (echo), Act: allow
```ux
name: CURRENT_DIR
echo: $(pwd)
act: :allow
```
Behavior:
- Init: Evaluates echo command
- Act: Shows menu of allowed values

#### 2.4 Default Init (exec), Act: allow
```ux
name: CURRENT_DIR
exec: basename $(pwd)
act: :allow
```
Behavior:
- Init: Executes command
- Act: Shows menu of allowed values

### 3. Default Act (no act key)

#### 3.1 Init: allow, Default Act
```ux
name: ENVIRONMENT
init: :allow
allow:
  - development
  - staging
  - production
```
Behavior:
- Init: Uses first allowed value (development)
- Act: Shows menu of allowed values (defaults to :allow)

#### 3.2 Init: false, Default Act
```ux
name: ENVIRONMENT
init: false
allow:
  - development
  - staging
  - production
echo: "Current: ${ENVIRONMENT}"
```
Behavior:
- Init: No initialization
- Act: Shows menu of allowed values (defaults to :allow)

### 4. Special Cases

#### 4.1 Init: false, Act: false
```ux
name: READONLY_VAR
init: false
act: false
```
Behavior:
- Init: No initialization
- Act: Cannot be activated

#### 4.2 Init: string, Act: allow
```ux
name: VERSION
init: "1.0.0"
act: :allow
allow:
  - "1.0.0"
  - "1.0.1"
  - "1.1.0"
```
Behavior:
- Init: Uses string value "1.0.0"
- Act: Shows menu of allowed values

#### 4.3 No Init, No Act
```ux
name: ENVIRONMENT
allow:
  - development
  - staging
  - production
```
Behavior:
- Init: Uses first allowed value
- Act: Shows menu of allowed values (defaults to :allow)

#### 4.4 No Init, No Act, No Allow
```ux
name: USER_INPUT
prompt: "Enter value"
```
Behavior:
- Init: No initialization (defaults to false)
- Act: Prompts for input (defaults to :edit) 