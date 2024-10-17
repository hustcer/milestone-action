#!/usr/bin/env nu
# Author: hustcer
# Created: 2024/06/09 20:33:15
# TODO:
#   [x] Support Windows, macOS, Linux
#   [x] Should run on local machine or Github runners
#   [x] Support dry run mode
#   [ ] Create milestone by title, due_on, and description
#   [ ] Close milestone by title or number
#   [ ] Add milestone to issue that has been fixed by a PR
# Description: Scripts for Github milestone management.

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
  --dry-run(-d),            # Dry run, only print the milestone that would be set.
] {
  check-gh
  if ($gh_token | is-not-empty) { $env.GH_TOKEN = $gh_token }
  let IGNORED_PR_STATUS = [CLOSED OPEN]
  # Could be MERGED, OPEN, CLOSED.
  let prState = gh pr view $pr --repo $repo --json 'state' | from json | get state
  if ($prState in $IGNORED_PR_STATUS) {
    print $'PR (ansi p)($pr)(ansi reset) is in state (ansi p)($prState)(ansi reset), will be ignored.'
    return
  }
  let selected = if ($milestone | is-empty) { guess-milestone $repo $pr } else { $milestone }
  if $force {
    let prevMilestone = gh pr view $pr --repo $repo --json 'milestone' | from json | get milestone?.title? | default '-'
    let shouldRemove = $prevMilestone != $selected
    if $dry_run and $shouldRemove {
      print $'(char nl)Would remove milestone for PR (ansi p)($pr)(ansi reset) in repository (ansi p)($repo)(ansi reset) ...'
    } else if $shouldRemove {
      gh pr edit $pr --repo $repo --remove-milestone
    } else {
      print $'(char nl)Milestone for PR (ansi p)($pr)(ansi reset) in repo (ansi p)($repo)(ansi reset) was already set to (ansi p)($prevMilestone)(ansi reset), will be ignored.'
    }
  }
  print $'(char nl)Setting milestone to (ansi p)($selected)(ansi reset) for PR (ansi p)($pr)(ansi reset) in repository (ansi p)($repo)(ansi reset) ...'
  # FIXME: GraphQL: Resource not accessible by integration (updatePullRequest)
  if not $dry_run {
    gh pr edit $pr --repo $repo --milestone $selected
  }
}

# Guess milestone by the merged date of the PR and the infomation of open milestones.
def guess-milestone [repo: string, pr: string] {
  # Query github open milestone list by gh
  let milestones = gh api -X GET $'/repos/($repo)/milestones' --paginate | from json
    | select number title due_on created_at html_url
  if ($milestones | is-empty) {
    print 'No open milestones found.'
    exit $ECODE.CONDITION_NOT_SATISFIED
  }
  print 'Open milestones:'; hr-line
  $milestones | table -w 120 | print
  let milestones = $milestones | upsert due_on {|it|
      # + 1day to avoid the case that the PR is merged on the due date of the milestone.
      if ($it.due_on | is-empty) { (date now) - 1day } else { ($it.due_on | into datetime) + 1day }
    }
  let mergedAt = gh pr view $pr --repo $repo --json 'mergedAt'
    | from json | get mergedAt | into datetime
  let guess = $milestones | where due_on >= $mergedAt | sort-by due_on
  let milestone = if ($guess | is-empty) {
    print 'No milestone found due after the PR merged. Fall back to the latest milestone.'
    $milestones | sort-by -r due_on created_at | first
  } else { $guess | first }
  $milestone.title
}

# Guess milestone for an issue by the commit message of the last closed PR.
export def guess-milestone-for-issue [
  repo: string,          # Github repository name
  issueNO: string,       # Issue number
] {
  let pr = gh api $'/repos/($repo)/issues/($issueNO)/timeline'
    | from json
    | where event == closed
    | filter { $in.commit_id | is-not-empty }
    | get 0.commit_url
    | gh api $in
    | from json
    | get commit.message
    | lines
    | first
    | parse --regex '\(#(?<pr>\d+)\)'
    | get pr.0

  let milestone =  gh pr view --repo $repo $pr --json 'milestone'
    | from json
    | get milestone?.title?
    | default -
  { milestone: $milestone, fixPR: $pr }
}

# Create milestone for a repository by title, due_on, and description.
export def create-milestone [
  repo: string,               # Github repository name
  title: string,              # Milestone title
  --due-on(-d): string,       # Milestone due date, format: yyyy/mm/dd
  --description(-D): string,  # Milestone description
  --gh-token(-t): string,     # Github access token
] {
  check-gh
  const STD_TIME = '%Y-%m-%dT%H:%M:%SZ'
  if ($gh_token | is-not-empty) { $env.GH_TOKEN = $gh_token }
  let dueOnArg = if ($due_on | is-empty) { [] } else { [-F $'due_on=($due_on | into datetime | format date $STD_TIME)'] }
  let descArg = if ($description | is-empty) { [] } else { [-F $'description=($description)'] }
  let result = gh api -X POST $'/repos/($repo)/milestones' -F $'title=($title)' ...$dueOnArg ...$descArg
  let milestone = $result | from json
  print $'Milestone (ansi p)($milestone.title)(ansi reset) with NO. (ansi p)($milestone.number)(ansi reset) was created successfully.'
}

# Close milestone for a repository by title or number.
export def close-milestone [
  repo: string,               # Github repository name
  milestone: string,          # Milestone name or number
  --gh-token(-t): string,     # Github access token
] {
  check-gh
  if ($gh_token | is-not-empty) { $env.GH_TOKEN = $gh_token }
  let milestoneId = if ($milestone | is-int) { $milestone } else {
    let milestones = gh api $'/repos/($repo)/milestones' | from json
    let milestone = $milestones | where title == $milestone
    if ($milestone | is-empty) {
      print 'Milestone not found.'; exit $ECODE.INVALID_PARAMETER
    }
    $milestone.0.number
  }
  let result = gh api -X PATCH $'/repos/($repo)/milestones/($milestoneId)' -F $'state=closed'
  let milestone = $result | from json
  print $'Milestone (ansi p)($milestone.title)(ansi reset) with NO. (ansi p)($milestone.number)(ansi reset) was closed successfully.'
}

def is-int [] {
  $in | str trim | str replace -ar '\d' '' | is-empty
}

def check-gh [] {
  if not (is-installed 'gh') {
    print 'gh command not found, please install it first, see: https://cli.github.com/.'
    exit $ECODE.MISSING_BINARY
  }
}

alias main = milestone-update
