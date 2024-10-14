# Author: hustcer
# Create: 2024/06/09 18:05:20
# Description:
#   Some helper task for milestone-action.
# Ref:
#   1. https://github.com/casey/just
#   2. https://www.nushell.sh/book/

set shell := ['nu', '-c']

# The export setting causes all just variables
# to be exported as environment variables.

set export := true
set dotenv-load := true

# If positional-arguments is true, recipe arguments will be
# passed as positional arguments to commands. For linewise
# recipes, argument $0 will be the name of the recipe.

set positional-arguments := true

# Just commands aliases
alias r := release

# Use `just --evaluate` to show env vars

# Used to handle the path separator issue
NU_DIR := parent_directory(`(which nu).path.0`)
MILESTONE_ACTION_PATH := parent_directory(justfile())
_query_plugin := if os_family() == 'windows' { 'nu_plugin_query.exe' } else { 'nu_plugin_query' }

# To pass arguments to a dependency, put the dependency
# in parentheses along with the arguments, just like:
# default: (sh-cmd "main")

# List available commands by default
default:
  @just --list --list-prefix "··· "

# Release a new version for `hustcer/milestone-action`
release *OPTIONS:
  @overlay use {{ join(MILESTONE_ACTION_PATH, 'nu', 'common.nu') }}; \
    overlay use {{ join(MILESTONE_ACTION_PATH, 'nu', 'release.nu') }}; \
    git-check --check-repo=1 {{MILESTONE_ACTION_PATH}}; \
    make-release {{OPTIONS}}

# Set milestone for PR in dry-run mode
dry-run *OPTIONS:
  @overlay use {{ join(MILESTONE_ACTION_PATH, 'nu', 'milestone.nu') }}; \
  milestone-update --dry-run {{OPTIONS}}

# Plugins need to be registered only once after nu v0.61
_setup:
  @register -e json {{ join(NU_DIR, _query_plugin) }}
