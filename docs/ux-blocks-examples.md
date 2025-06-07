# UX Block Examples

This file contains a collection of unique UX block examples from the documentation.

## Basic Examples

### Simple Variable Display and Edit
```ux
init: Guest
name: USER_NAME
prompt: Enter your name
```

### Command Output Initialization
```ux
name: CURRENT_DIR
init: :exec
exec: basename $(pwd)
transform: :chomp
```

### Echo-based Initialization
```ux
name: SHELL_VERSION
init: :echo
echo: $SHELL
```

### Selection from Allowed Values
```ux
name: ENVIRONMENT
allow:
  - development
  - staging
  - production
prompt: Select environment
```

## Validation Examples

### Email Validation
```ux
name: USER_EMAIL
prompt: Enter email address
validate: '(?<local>[^@]+)@(?<domain>[^@]+)'
transform: '%{local}@%{domain}'
```

### Version Number Validation
```ux
name: VERSION
prompt: Enter version number
validate: '(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)'
transform: '%{major}.%{minor}.%{patch}'
```

## Complex Examples

### Git Branch Selection with Validation
```ux
name: BRANCH_NAME
init: ":exec"
exec: "git branch --format='%(refname:short)'"
validate: "^(?<type>feature|bugfix|hotfix)/(?<ticket>[A-Z]+-\d+)-(?<desc>.+)$"
transform: "${type}/${ticket}-${desc}"
prompt: "Select or enter branch name"
```

### Environment Configuration with Dependencies
```ux
name: DATABASE_URL
require:
  - ENVIRONMENT
  - DB_HOST
  - DB_PORT
format: "postgresql://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
```

### Multi-step Configuration
```ux
name: DEPLOY_CONFIG
require:
  - ENVIRONMENT
  - VERSION
init: ":echo"
echo: "Deploying ${VERSION} to ${ENVIRONMENT}"
act: ":exec"
exec: "deploy.sh ${ENVIRONMENT} ${VERSION}"
```

### Conditional Initialization
```ux
name: API_KEY
init: ":allow"
allow:
  - ${PROD_API_KEY}
  - ${STAGING_API_KEY}
  - ${DEV_API_KEY}
require:
  - ENVIRONMENT
```

### Formatted Output with Validation
```ux
name: PHONE_NUMBER
prompt: "Enter phone number"
validate: "(?<country>\d{1,3})(?<area>\d{3})(?<number>\d{7})"
transform: "+${country} (${area}) ${number}"
format: "Phone: ${PHONE_NUMBER}"
```

### Command Output with Transformation
```ux
name: GIT_STATUS
init: ":exec"
exec: "git status --porcelain"
validate: "(?<status>[AMDR])\s+(?<file>.+)"
transform: "${status}: ${file}"
format: "Changes: ${GIT_STATUS}"
``` 