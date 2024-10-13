#!/usr/bin/env nu
# Author: hustcer
# Created: 2024/06/09 20:33:15
# TODO:
#   [x] Support Windows, macOS, Linux
#   [x] Should run on local machine or Github runners
# Description: Scripts for setting up Bend environment

use common.nu [ECODE, hr-line is-installed]

export-env {
  $env.config.table.mode = 'light'
  $env.config.color_config.leading_trailing_space_bg = { attr: n }
}

export def 'milestone-update' [
  repo: string,             # Github repository name
  --gh-token(-t): string,   # Github access token
  --milestone(-m): string,  # Milestone name
  --pr: string,             # The PR number/url/branch of the PR that we want to add milestone.
  --force(-f),              # Force update milestone even if the milestone is already set.
] {
  if not (is-installed 'gh') {
    print 'gh command not found, please install it first, see: https://cli.github.com/.'
    exit $ECODE.MISSING_BINARY
  }
  if ($gh_token | is-not-empty) { $env.GH_TOKEN = $gh_token }
  let selected = if ($milestone | is-empty) { guess-milestone $repo $pr } else { $milestone }
  if $force { gh pr edit $pr --repo $repo --remove-milestone }
  print $'Setting milestone to ($selected) for PR ($pr)...'
  gh pr edit $pr --repo $repo --milestone $selected
}

# Guess milestone by the merged date of the PR and the infomation of open milestones.
def guess-milestone [repo: string, pr: string] {
  # Query github open milestone list by gh
  let milestones = gh api -X GET $'/repos/($repo)/milestones' --paginate | from json
    | select number title due_on html_url
  if ($milestones | is-empty) {
    print 'No open milestones found.'
    exit $ECODE.CONDITION_NOT_SATISFIED
  }
  print 'Open milestones:'; hr-line
  $milestones | print
  let milestones = $milestones | upsert due_on {|it|
      if ($it.due_on | is-empty) { (date now) - 1day } else {
        $it.due_on | into datetime
      }
    }
  let mergedAt = gh pr view $pr --repo $repo --json 'mergedAt'
    | from json | get mergedAt | into datetime
  let milestone = $milestones | where due_on >= $mergedAt | sort-by due_on | first
  let milestone = if ($milestone | is-empty) {
    print 'No milestone found due after the PR merged. Fall back to the latest milestone.'
    $milestones | sort-by due_on | first
  } else { $milestone }
  $milestone.title
}

alias main = milestone-update
