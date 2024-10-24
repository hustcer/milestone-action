
# Description: Use graphql API to get the milestone of a closed PR for an issue.
# API: https://api.github.com/graphql
# REF: https://docs.github.com/en/graphql/guides/forming-calls-with-graphql
# Usage:
#   query-issue-closer-by-graphql nushell/nushell 13991 <token>
#   query-issue-closer-by-graphql nushell/nushell 13966 <token>
#   query-issue-closer-by-graphql web-infra-dev/rsbuild 3780 <token>

export def query-issue-closer-by-graphql [
  repo: string,         # Github repository name
  issueNO: int,         # Issue number
  token: string         # Github access token
] {
  let owner = $repo | split row / | first
  let name = $repo | split row / | last
  let query = open -r nu/issue.gql
  let variables = {
    repo_name: $name,
    repo_owner: $owner,
    issue_number: $issueNO
  }

  const QUERY_API = 'https://api.github.com/graphql'
  let HEADERS = ['Authorization' $'bearer ($token)']
  let rename = {
    'author.login': 'author',
    'milestone.title': 'milestone',
    'repository.nameWithOwner': 'repo',
    'mergeCommit.abbreviatedOid': 'sha'
  }

  let payload = { query: $query, variables: $variables } | to json
  let result = http post --content-type application/json -H $HEADERS $QUERY_API $payload
    | get data.repository.issueOrPullRequest

  let events = $result.timeline.edges.node | filter {|it| $it.stateReason? | is-not-empty }

  let closer = $events | filter {|it| $it.closer?.number? | is-not-empty }
    | select closer | flatten
    | select number milestone?.title? author.login repository.nameWithOwner mergeCommit.abbreviatedOid title
    | rename -c $rename
    | last

  { closed: $result.closed, closedAt: $result.closedAt, closedBy: $closer, events: $events }
}
