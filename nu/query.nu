
# Description: Use graphql API to get the milestone of a closed PR for an issue,
#              or get the issues closed by a PR.
# API: https://api.github.com/graphql
# REF: https://docs.github.com/en/graphql/guides/forming-calls-with-graphql
# Usage:
#   query-issue-closer-by-graphql nushell/nushell 13991 <token>
#   query-issue-closer-by-graphql nushell/nushell 13966 <token>
#   query-issue-closer-by-graphql web-infra-dev/rsbuild 3780 <token>
#   query-pr-closing-issues nushell/nushell 13991 <token>

use common.nu [hr-line]

# Resolve the directory of this module at parse time, so that the `.gql` files can be
# located no matter what the current working directory or the entry script path is.
const GQL_DIR = path self .

export def query-issue-closer-by-graphql [
  repo: string,         # Github repository name
  issueNO: int,         # Issue number
  token: string         # Github access token
] {
  let owner = $repo | split row / | first
  let name = $repo | split row / | last
  let query = open -r ($GQL_DIR | path join 'issue.gql')
  let variables = {
    repo_name: $name,
    repo_owner: $owner,
    issue_number: $issueNO
  }

  let payload = { query: $query, variables: $variables } | to json
  let status = query-issue-status $issueNO $payload $token
  print 'Issue Status:'; hr-line; $status | reject events | table -ew 120 | print

  $status
}

# Abort with the actual GraphQL diagnostics instead of letting a missing `data`
# field surface later as an inscrutable column-not-found error.
def check-graphql-errors []: record -> nothing {
  let errors = $in | get -o errors
  if ($errors | is-not-empty) {
    print $'(ansi r)GraphQL Error:(ansi reset)'
    $errors | table -e | print
    error make { msg: $'GraphQL query failed: ($errors | get -o 0.message | default "unknown error")' }
  }
}

def query-issue-status [issueNO: int, payload: string, token: string] {
  let rename = {
    'author.login': 'author',
    'milestone.title': 'milestone',
    'repository.nameWithOwner': 'repo',
    'mergeCommit.abbreviatedOid': 'sha'
  }
  const QUERY_API = 'https://api.github.com/graphql'
  let HEADERS = ['Authorization' $'bearer ($token)']

  mut tries = 1
  mut result = {}
  mut closer = {}
  mut events = []
  mut milestone = '-'
  # Loop 5 times to find the milestone of the last closed PR
  loop {
    if $milestone != '-' or $tries > 5 { break }
    print $'Try to query milestone for issue (ansi p)($issueNO)(ansi reset) the (ansi p)($tries)(ansi reset) (if $tries == 1 { "time" } else { "times" }) ...'
    let response = http post --content-type application/json -H $HEADERS $QUERY_API $payload
    $response | check-graphql-errors
    $result = ($response | get data.repository.issueOrPullRequest)

    $events = $result.timeline.edges.node | where {|it| $it.stateReason? | is-not-empty }

    let $closers = $events | where {|it| $it.closer?.number? | is-not-empty }
      | select closer | flatten
      | select number milestone?.title? author.login repository.nameWithOwner mergeCommit?.abbreviatedOid? title
      | rename -c $rename

    $closer = if ($closers | is-empty) { {} } else { $closers | last }
    $milestone = $closer.milestone? | default '-'
    if $milestone != '-' { break }
    $tries += 1; sleep 3sec
  }

  { closed: $result.closed, closedAt: $result.closedAt, closedBy: $closer, events: $events }
}

# Query PR closing issues and their milestones by GraphQL
export def query-pr-closing-issues [
  repo: string,         # Github repository name
  prNO: int,            # PR number
  token: string         # Github access token
] {
  let owner = $repo | split row / | first
  let name = $repo | split row / | last
  let query = open -r ($GQL_DIR | path join 'pr.gql')
  let variables = {
    pr_number: $prNO,
    repo_name: $name,
    repo_owner: $owner,
  }

  let payload = { query: $query, variables: $variables } | to json
  const QUERY_API = 'https://api.github.com/graphql'
  let HEADERS = ['Authorization' $'bearer ($token)']

  let response = http post --content-type application/json -H $HEADERS $QUERY_API $payload

  $response | check-graphql-errors

  let result = $response | get data.repository.pullRequest

  let prMilestone = $result.milestone?.title? | default '-'
  let closingIssues = $result.closingIssuesReferences.edges
    | each {|edge|
        let node = $edge.node
        {
          number: $node.number,
          title: $node.title,
          state: $node.state,
          milestone: ($node.milestone?.title? | default '-'),
          milestoneNumber: ($node.milestone?.number? | default null)
        }
      }

  print $'(char nl)PR (ansi p)#($prNO)(ansi reset) closes ($closingIssues | length) issues:'
  if not ($closingIssues | is-empty) {
    hr-line; $closingIssues | table -ew 120 | print
  }

  { pr: $prNO, prMilestone: $prMilestone, closingIssues: $closingIssues }
}
