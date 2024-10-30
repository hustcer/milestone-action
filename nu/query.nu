
# Description: Use graphql API to get the milestone of a closed PR for an issue.
# API: https://api.github.com/graphql
# REF: https://docs.github.com/en/graphql/guides/forming-calls-with-graphql
# Usage:
#   query-issue-closer-by-graphql nushell/nushell 13991 <token>
#   query-issue-closer-by-graphql nushell/nushell 13966 <token>
#   query-issue-closer-by-graphql web-infra-dev/rsbuild 3780 <token>

use common.nu [hr-line]

export def query-issue-closer-by-graphql [
  repo: string,         # Github repository name
  issueNO: int,         # Issue number
  token: string         # Github access token
] {
  let owner = $repo | split row / | first
  let name = $repo | split row / | last
  let pwd = $env.FILE_PWD? | default 'nu'
  let query = open -r $'($pwd)/issue.gql'
  let variables = {
    repo_name: $name,
    repo_owner: $owner,
    issue_number: $issueNO
  }

  let payload = { query: $query, variables: $variables } | to json
  let status = query-issue-status $issueNO $payload $token
  print 'Issue Status:'; hr-line; $status | reject events | table -e | print

  $status
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
    print $'Try to query milestone for issue (ansi p)($issueNO)(ansi reset) the (ansi p)($tries)(ansi reset) time ...'
    $result = (http post --content-type application/json -H $HEADERS $QUERY_API $payload
      | get data.repository.issueOrPullRequest)

    $events = $result.timeline.edges.node | filter {|it| $it.stateReason? | is-not-empty }

    let $closers = $events | filter {|it| $it.closer?.number? | is-not-empty }
      | select closer | flatten
      | select number milestone?.title? author.login repository.nameWithOwner mergeCommit.abbreviatedOid title
      | rename -c $rename

    $tries += 1; sleep 3sec
    $closer = if ($closers | is-empty) { {} } else { $closers | last }
    $milestone = $closer.milestone? | default '-'
  }

  { closed: $result.closed, closedAt: $result.closedAt, closedBy: $closer, events: $events }
}
