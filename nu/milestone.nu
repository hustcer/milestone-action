#!/usr/bin/env nu
# Author: hustcer
# Created: 2024/06/09 20:33:15
# TODO:
#   [x] Support Windows, macOS, Linux
#   [x] Should run on local machine or Github runners
#   [x] Support dry run mode
#   [x] Create milestone by title, due_on, and description
#   [x] Close milestone by title or number
#   [x] Delete milestone by title or number
#   [x] Add milestone to issue that has been fixed by a PR
#   [x] Try to inherit milestone from closing issues
# Description: Scripts for Github milestone management.

use common.nu [ECODE, hr-line is-installed]
use query.nu [query-issue-closer-by-graphql, query-pr-closing-issues]

export-env {
  $env.config.table.mode = 'light'
  $env.config.color_config.leading_trailing_space_bg = { attr: n }
}

# Bind milestone to a merged PR.
export def 'milestone-bind-for-pr' [
  repo: string,                 # Github repository name
  --gh-token(-t): string,       # Github access token
  --milestone(-m): string,      # Milestone name
  --pr: string,                 # The PR number/url/branch of the PR that we want to add milestone.
  --force(-f),                  # Force update milestone even if the milestone is already set.
  --dry-run,                    # Dry run, only print the milestone that would be set.
  --inherit-from-issue = true,  # Try to inherit milestone from closing issues. Defaults to true.
] {
  check-gh
  if ($gh_token | is-not-empty) { $env.GH_TOKEN = $gh_token }
  let IGNORED_PR_STATUS = [CLOSED]
  # PR state Could be MERGED, OPEN, CLOSED.
  let prState = gh pr view $pr --repo $repo --json 'state' | from json | get state
  if ($prState in $IGNORED_PR_STATUS) {
    print $'PR (ansi p)($pr)(ansi reset) is in state (ansi p)($prState)(ansi reset), will be ignored.'
    return
  }
  let token = resolve-gh-token
  let selected = if ($milestone | is-empty) { guess-milestone-for-pr $repo $pr $token $inherit_from_issue } else { $milestone }
  let prevMilestone = gh pr view $pr --repo $repo --json 'milestone' | from json | get milestone?.title? | default '-'
  # No explicit removal is needed on the force path: the REST PATCH below overwrites
  # whatever milestone is currently set.
  let ignoreSet = not $force and $prevMilestone != '-'
  if $prevMilestone == $selected or $ignoreSet {
    print $'(char nl)Milestone for PR (ansi p)($pr)(ansi reset) in repo (ansi p)($repo)(ansi reset) was already set to (ansi p)($prevMilestone)(ansi reset), will be ignored.'
    return
  }
  print $'(char nl)Setting milestone to (ansi p)($selected)(ansi reset) for PR (ansi p)($pr)(ansi reset) in repository (ansi p)($repo)(ansi reset) ...'
  # Using REST API to avoid GraphQL deprecation warnings for Projects (classic)
  if not $dry_run {
    let prNumber = $pr | str replace '#' '' | into int
    let success = set-milestone-via-rest-api $repo $prNumber $selected 'pr'
    if not $success {
      error make { msg: $'Failed to set milestone for PR ($pr)' }
    }
  }
}

# Bind milestone to a completed issue.
export def 'milestone-bind-for-issue' [
  repo: string,             # Github repository name
  --gh-token(-t): string,   # Github access token
  --milestone(-m): string,  # Milestone name
  --issue: int,             # The Issue number that we want to add milestone.
  --force(-f),              # Force update milestone even if the milestone is already set.
  --dry-run,                # Dry run, only print the milestone that would be set.
] {
  check-gh
  if ($gh_token | is-not-empty) { $env.GH_TOKEN = $gh_token }
  let IGNORED_ISSUE_STATUS = [OPEN]
  # Issue state Could be OPEN, CLOSED(with stateReasons: COMPLETED, NOT_PLANNED, REOPENED).
  let issueState = gh issue view $issue --repo $repo --json 'state' | from json | get state
  let stateReason = gh issue view $issue --repo $repo --json 'stateReason' | from json | get stateReason
  let shouldIgnore = ($issueState in $IGNORED_ISSUE_STATUS) or ($stateReason == 'NOT_PLANNED')
  if $shouldIgnore {
    print $'Issue (ansi p)($issue)(ansi reset) is Not (ansi p)COMPLETED(ansi reset), will be ignored.'
    return
  }
  let token = resolve-gh-token
  let selected = if ($milestone | is-empty) { query-issue-closer-by-graphql $repo $issue $token | get closedBy?.milestone? | default '-' } else { $milestone }
  let prevMilestone = gh issue view $issue --repo $repo --json 'milestone' | from json | get milestone?.title? | default '-'
  if $selected == '-' {
    # Nothing to bind. `--force` deliberately does NOT strip the existing milestone here:
    # failing to infer a replacement is no reason to throw away one somebody set by hand.
    print $'No milestone found for issue (ansi p)($issue)(ansi reset) in repository (ansi p)($repo)(ansi reset).'
    if $force and $prevMilestone != '-' {
      print $'Keeping the existing milestone (ansi p)($prevMilestone)(ansi reset): (ansi p)--force(ansi reset) has no replacement to apply.'
    }
    return
  }
  # No explicit removal is needed on the force path: the REST PATCH below overwrites
  # whatever milestone is currently set.
  let ignoreSet = not $force and $prevMilestone != '-'
  if $prevMilestone == $selected or $ignoreSet {
    print $'(char nl)Milestone for Issue (ansi p)($issue)(ansi reset) in repo (ansi p)($repo)(ansi reset) was already set to (ansi p)($prevMilestone)(ansi reset), will be ignored.'
    return
  }
  print $'(char nl)Setting milestone to (ansi p)($selected)(ansi reset) for Issue (ansi p)($issue)(ansi reset) in repository (ansi p)($repo)(ansi reset) ...'
  # Using REST API to avoid GraphQL deprecation warnings for Projects (classic)
  if not $dry_run {
    let success = set-milestone-via-rest-api $repo $issue $selected 'issue'
    if not $success {
      error make { msg: $'Failed to set milestone for Issue ($issue)' }
    }
  }
}

# Guess milestone by the merged date of the PR and the information of open milestones.
# If inherit_from_issue is true, try to get milestone from closing issues first.
export def guess-milestone-for-pr [
  repo: string,
  pr: string,
  token: string,
  inherit_from_issue: bool = true
] {
  # Try to inherit milestone from closing issues
  if $inherit_from_issue {
    print $'(char nl)Trying to inherit milestone from closing issues for PR (ansi p)#($pr)(ansi reset)...'
    try {
      let prData = query-pr-closing-issues $repo ($pr | into int) $token
      let closingIssues = $prData.closingIssues

      if not ($closingIssues | is-empty) {
        # Get unique milestones from closing issues (excluding empty ones)
        let issueMilestones = $closingIssues
          | where milestone != null and milestone != '-'
          | get milestone
          | uniq

        # If all issues have the same milestone, use it
        if ($issueMilestones | length) == 1 {
          let inherited = $issueMilestones | first
          print $'(char nl)(ansi g)✓(ansi reset) Inherited milestone (ansi p)($inherited)(ansi reset) from closing issues.'
          return $inherited
        } else if ($issueMilestones | length) > 1 {
          print $'(char nl)(ansi y)⚠(ansi reset) Closing issues have different milestones: ($issueMilestones | str join ", "), falling back to date-based detection.'
        } else {
          print $'(char nl)(ansi y)⚠(ansi reset) Closing issues have no milestone set, falling back to date-based detection.'
        }
      }
    } catch { |err|
      print $'(ansi y)⚠(ansi reset) Failed to query closing issues: ($err.msg), falling back to date-based detection.'
    }
  }

  # Fall back to date-based milestone detection
  print $'(char nl)Using date-based milestone detection for PR (ansi p)#($pr)(ansi reset)...'
  # Query github open milestone list by gh. `state=open` is intentional here:
  # date-based detection should only ever consider milestones still open.
  let milestones = gh api -X GET $'/repos/($repo)/milestones' -f state=open --paginate | from json
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
  let mergedAt = try {
    gh pr view $pr --repo $repo --json 'mergedAt' | from json | get mergedAt | into datetime
  } catch { (date now | into datetime) }
  let guess = $milestones | where due_on >= $mergedAt | sort-by due_on created_at
  if false { hr-line -c grey66; $guess | print; hr-line -c grey66 }
  let milestone = if ($guess | is-empty) {
    print 'No milestone found due after the PR merged. Falling back to the earliest-created milestone.'
    $milestones | sort-by created_at | first
  } else { $guess | first }
  $milestone.title
}

# Guess milestone for an issue by the commit message of the last closed PR.
export def guess-milestone-for-issue [
  repo: string,          # Github repository name
  issueNO: string,       # Issue number
] {
  let pr = http get $'https://github.com/($repo)/issues/($issueNO)'
    | query web --query 'span[data-issue-and-pr-hovercards-enabled]'
    | get 0 | to text
    | str trim | lines | str join
    | parse --regex '#(?<pr>\d+)'
    | get pr | last

  mut milestone =  gh pr view --repo $repo $pr --json 'milestone'
    | from json
    | get milestone?.title?
    | default -

  mut tries = 1
  # Loop 5 times to find the milestone of the last closed PR
  loop {
    if $milestone != '-' or $tries > 5 { break }
    print $'Try to guess milestone for issue (ansi p)($issueNO)(ansi reset) closed by PR (ansi p)($pr)(ansi reset) ...'
    $tries += 1; sleep 3sec
    $milestone = (gh pr view --repo $repo $pr --json 'milestone'
      | from json
      | get milestone?.title?
      | default -)
  }
  let result = { milestone: $milestone, fixPR: $pr }
  print $'Milestone (ansi p)($result.milestone)(ansi reset) was guessed for issue (ansi p)($issueNO)(ansi reset) and fixed by PR (ansi p)($result.fixPR)(ansi reset).'
  $result
}

# Create milestone for a repository by title, due_on, and description.
export def create-milestone [
  repo: string,               # Github repository name
  title: string,              # Milestone title
  --due-on(-d): string,       # Milestone due date, format: yyyy-mm-dd
  --description(-D): string,  # Milestone description
  --gh-token(-t): string,     # Github access token
] {
  check-gh
  const STD_TIME = '%Y-%m-%dT%H:%M:%SZ'
  # A milestone without a title is always a mistake, and the Github API would happily
  # create one from whatever placeholder we passed, so fail loudly instead.
  if ($title | str trim | is-empty) {
    print $'(ansi r)Error:(ansi reset) A non-empty `title` is required by the `create` action.'
    exit $ECODE.INVALID_PARAMETER
  }
  if ($gh_token | is-not-empty) { $env.GH_TOKEN = $gh_token }
  # Always `-f` (raw-field), never `-F`: `-F` applies "magic type conversion", so a purely
  # numeric title such as `2026` would be sent as a JSON number and rejected by the API with
  # `422 Invalid request. For 'properties/title', 2026 is not a string.`
  let dueOnArg = if ($due_on | is-empty) { [] } else { [-f $'due_on=($due_on | into datetime | format date $STD_TIME)'] }
  let descArg = if ($description | is-empty) { [] } else { [-f $'description=($description)'] }
  let result = gh api -X POST $'/repos/($repo)/milestones' -f $'title=($title)' ...$dueOnArg ...$descArg
  let milestone = $result | from json
  print $'Milestone (ansi p)($milestone.title)(ansi reset) with NO. (ansi p)($milestone.number)(ansi reset) was created successfully.'
  set-action-output 'milestone-number' $milestone.number
}

# Close milestone for a repository by title or number.
export def close-milestone [
  repo: string,               # Github repository name
  milestone: string,          # Milestone name or number
  --gh-token(-t): string,     # Github access token
] {
  check-gh
  if ($gh_token | is-not-empty) { $env.GH_TOKEN = $gh_token }
  let milestoneId = resolve-milestone-id $repo $milestone
  let result = gh api -X PATCH $'/repos/($repo)/milestones/($milestoneId)' -f $'state=closed'
  let milestone = $result | from json
  print $'Milestone (ansi p)($milestone.title)(ansi reset) with NO. (ansi p)($milestone.number)(ansi reset) was closed successfully.'
  set-action-output 'milestone-number' $milestone.number
}

# Delete milestone for a repository by title or number.
export def delete-milestone [
  repo: string,               # Github repository name
  milestone: string,          # Milestone name or number
  --gh-token(-t): string,     # Github access token
] {
  check-gh
  if ($gh_token | is-not-empty) { $env.GH_TOKEN = $gh_token }
  let milestoneId = resolve-milestone-id $repo $milestone
  let result = gh api -X DELETE $'/repos/($repo)/milestones/($milestoneId)'
  let response = $result | from json
  print $'Milestone with NO. (ansi p)($milestoneId)(ansi reset) was deleted successfully.'
  $response | table -ew 120 | print
}

# Write a key/value pair to $env.GITHUB_OUTPUT when running inside Github Actions.
# Outside Actions (local `just`, manual debugging) the variable is absent, so this is a no-op.
def set-action-output [key: string, value: any] {
  if ($env.GITHUB_OUTPUT? | is-not-empty) {
    $'($key)=($value)(char nl)' | save --append $env.GITHUB_OUTPUT
  }
}

# Only plain ASCII digits count: `\d` in Rust regex matches the whole Unicode Nd
# category, so '１２３' would otherwise be treated as a milestone number.
def is-int [] {
  let value = $in | str trim
  if ($value | is-empty) { return false }
  $value =~ '^[0-9]+$'
}

# Resolve the token used for the direct GraphQL calls. On a runner GH_TOKEN/GITHUB_TOKEN is
# always set, but locally (`just dr` / `just di`) neither is, and forwarding the resulting null
# into a `string` positional aborts the run with a type error. Fall back to the gh CLI's own
# credential so the documented local dry-run workflow keeps working.
def resolve-gh-token []: nothing -> string {
  let fromEnv = $env.GH_TOKEN? | default $env.GITHUB_TOKEN? | default ''
  if ($fromEnv | is-not-empty) { return $fromEnv }
  do -i { gh auth token | complete } | default {} | get -o stdout | default '' | str trim
}

def check-gh [] {
  if not (is-installed 'gh') {
    print 'gh command not found, please install it first, see: https://cli.github.com/.'
    exit $ECODE.MISSING_BINARY
  }
}

# List every milestone of a repository, open and closed alike.
# `state=all` is required because the REST API defaults to `state=open`, and
# `--paginate` because a single page only holds 30 milestones.
def list-milestones [repo: string] {
  gh api -X GET $'/repos/($repo)/milestones' -f state=all --paginate | from json
}

# Resolve a milestone reference - a number or a title - to its milestone number.
# Exits with INVALID_PARAMETER when the reference is empty or matches no milestone,
# so `close` and `delete` report the same diagnostics for the same input.
def resolve-milestone-id [repo: string, milestone: string]: nothing -> int {
  if ($milestone | str trim | is-empty) {
    print $'(ansi r)Error:(ansi reset) A non-empty `milestone` title or number is required.'
    exit $ECODE.INVALID_PARAMETER
  }
  # An all-digit value always wins as a number, so a milestone whose *title* is all digits
  # can only be addressed by its number. Documented in the README input tables.
  if ($milestone | is-int) { return ($milestone | into int) }
  let found = list-milestones $repo | where title == $milestone
  if ($found | is-empty) {
    print $'(ansi r)Error:(ansi reset) Milestone (ansi p)($milestone)(ansi reset) not found in repository (ansi p)($repo)(ansi reset).'
    exit $ECODE.INVALID_PARAMETER
  }
  $found.0.number
}

# Get milestone number by title using REST API
def get-milestone-number [
  repo: string,
  milestone_title: string
] {
  let found = list-milestones $repo | where title == $milestone_title
  if ($found | is-empty) {
    print $'(ansi r)Error:(ansi reset) Milestone (ansi p)($milestone_title)(ansi reset) not found in repository (ansi p)($repo)(ansi reset).'
    return null
  }
  $found | first | get number
}

# Set milestone for PR or Issue using REST API (avoiding GraphQL deprecation warnings)
def set-milestone-via-rest-api [
  repo: string,
  number: int,              # PR or Issue number
  milestone_title: string,
  type: string = 'pr'       # 'pr' or 'issue'
] {
  # Get milestone number by title
  let milestone_number = get-milestone-number $repo $milestone_title
  if ($milestone_number | is-empty) {
    error make { msg: $'Milestone "($milestone_title)" not found' }
  }

  # Use REST API to update PR/Issue
  # Note: In GitHub API, both PRs and Issues use the /issues endpoint for updates
  try {
    gh api -X PATCH $'/repos/($repo)/issues/($number)' -f $'milestone=($milestone_number)' | ignore
    return true
  } catch { |err|
    print $'(ansi r)Error:(ansi reset) Failed to set milestone: ($err.msg)'
    return false
  }
}

# Milestone action entry point.
export def milestone-action [
  action: string,               # Action to perform, could be create, close, or bind-pr.
  repo: string,                 # Github repository name
  --gh-token(-t): string,       # Github access token
  --milestone(-m): string = '', # Milestone title or number
  --title: string = '',         # Milestone title to create
  --due-on(-d): string,         # Milestone due date, format: yyyy-mm-dd
  --description(-D): string,    # Milestone description
  --pr: string,                 # The PR number/url/branch of the PR that we want to add milestone.
  --issue: string,              # The Issue number that we want to add milestone.
  --force(-f),                  # Force update milestone even if the milestone is already set.
  --dry-run,                    # Dry run, only print the milestone that would be set.
  --inherit-from-issue = true,  # Try to inherit milestone from closing issues. Defaults to true.
] {
  match $action {
    close => { close-milestone $repo $milestone --gh-token $gh_token },
    delete => { delete-milestone $repo $milestone --gh-token $gh_token },
    create => { create-milestone $repo $title --due-on $due_on -D $description -t $gh_token },
    bind-pr => { milestone-bind-for-pr $repo -t $gh_token -m $milestone --pr $pr --force=$force --dry-run=$dry_run --inherit-from-issue=$inherit_from_issue },
    bind-issue => { milestone-bind-for-issue $repo -t $gh_token -m $milestone --issue ($issue | into int) --force=$force --dry-run=$dry_run },
    _ => {
      print $'(ansi r)Error:(ansi reset) Invalid action (ansi p)($action)(ansi reset), should be one of bind-pr, bind-issue, create, close or delete.'
      exit $ECODE.INVALID_PARAMETER
    },
  }
}

alias main = milestone-action
