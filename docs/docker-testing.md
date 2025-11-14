# Docker Testing Environment

This document describes how to use the Docker testing environment for `markdown_exec`.

## Overview

The `Dockerfile.ruby-3.3-spec` provides a complete testing environment with:
- Ruby 3.3 on Debian Bookworm
- All build dependencies
- Git submodules initialized (BATS testing framework)
- Development tools and aliases
- Pre-configured BATS test setup

## Building the Image

```bash
docker build -f Dockerfile.test -t markdown-exec-test .
```

You can specify a different Git branch to test:

```bash
docker build -f Dockerfile.test --build-arg GIT_BRANCH=develop -t markdown-exec-test .
```

## Running Tests

### Run all BATS tests

```bash
docker run --rm markdown-exec-test bats test/
```

### Run specific test file

```bash
docker run --rm markdown-exec-test bats test/options.bats
```

### Run with verbose output

```bash
docker run --rm markdown-exec-test batsv test/
```

The container includes the `batsv` alias for verbose BATS output.

## Interactive Development

### Enter the container interactively

```bash
docker run --rm -it markdown-exec-test bash
```

Once inside, you have access to:
- `bats` - BATS test runner (available in PATH)
- `batsv` - Verbose BATS runner (alias)
- `be` - Bundle exec alias
- `bmde` - Bin/bmde alias
- `ll` - Enhanced ls alias

### Mount local directory for development

To work with your local code changes:

```bash
docker run --rm -it -v "$(pwd)":/markdown_exec markdown-exec-test bash
```

**Note:** The container clones the repo by default. When mounting your local directory, you may need to adjust paths or rebuild dependencies.

## Running Minitest

```bash
docker run --rm markdown-exec-test bundle exec rake minitest
```

## Container Details

- **Working Directory**: `/markdown_exec`
- **Base Image**: `ruby:3.3-bookworm`
- **BATS Location**: `/markdown_exec/test/bats/bin/bats` (symlinked to `/usr/local/bin/bats`)
- **Test Helpers**: Located in `/markdown_exec/test/test_helper/`

## Troubleshooting

### Submodules not initialized

If you encounter issues with BATS submodules, the Dockerfile should handle this automatically. If problems persist:

```bash
docker run --rm -it markdown-exec-test bash
cd /markdown_exec
git submodule update --init --recursive
```

### Missing test files

The container creates required directories and test files. If tests fail due to missing files, check that the Dockerfile build completed successfully.

### Running tests with local changes

For testing local changes without rebuilding:

1. Build the base image once
2. Use volume mounting to overlay your local code
3. Re-run bundle install if dependencies changed:

```bash
docker run --rm -it -v "$(pwd)":/markdown_exec markdown-exec-test bash
bundle install
bats test/
```

