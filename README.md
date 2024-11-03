# Milestone Action

[中文说明](README.zh-CN.md)

## Features

- Add milestone to merged PRs automatically
- Add milestone to closed issues that have a merged PR fix automatically
- Create milestone by title, description and due date
- Close milestone by title or milestone number
- Delete milestone by title or milestone number

## Usage

Bind milestone to merged PR or closed issue that has a merged PR fix automatically:

```yaml

name: Milestone Action
on:
  issues:
    types: [closed]
  pull_request_target:
    types: [closed]

jobs:
  update-milestone:
    runs-on: ubuntu-latest
    name: Milestone Update
    steps:
      - name: Set Milestone for PR
        uses: hustcer/milestone-action@v2
        if: github.event.pull_request.merged == true
        with:
          action: bind-pr   # `bind-pr` is the default action
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      # Bind milestone to closed issue that has a merged PR fix
      - name: Set Milestone for Issue
        uses: hustcer/milestone-action@v2
        if: github.event.issue.state == 'closed'
        with:
          action: bind-issue
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

Create milestone by title, description and due date:

```yaml
- name: Create Milestone
  uses: hustcer/milestone-action@v2
  with:
    action: create
    title: v1.0
    due-on: 2025-05-01
    description: 'The first milestone of the project.'
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

Close milestone by title or milestone number:

```yaml
- name: Close Milestone
  uses: hustcer/milestone-action@v2
  with:
    action: close
    milestone: v1.0   # Milestone title or number
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

Delete milestone by title or milestone number:

```yaml
- name: Delete Milestone
  uses: hustcer/milestone-action@v2
  with:
    action: delete
    milestone: v1.0   # Milestone title or number
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Inputs

| Name         | Type    | Description                                                                                                             |
| ------------ | ------- | ----------------------------------------------------------------------------------------------------------------------- |
| action       | String  | Action to perform: create, close, delete, bind-pr, bind-issue, defaults to `bind-pr`                                            |
| title        | String  | Title of the milestone to create                                                                                        |
| due-on       | String  | Due date of the milestone (yyyy-mm-dd) to create                                                                        |
| description  | String  | Description of the milestone to create                                                                                  |
| milestone    | String  | Title or number of the milestone to close or delete, could also be used to specify the milestone title to bind to the PR or issue |
| force        | Boolean | If the PR or Issue already has a milestone just remove it and set to a new one if they are different                    |
| github-token | String  | The GitHub token to access the API for milestone management, defaults to `${{ github.token }}`                          |

### FAQ

1. How do I know which milestone to bind to a merged PR?

First, if the PR is closed without merging, the action will do nothing. After the PR being merged, the action will use the milestone you specified in the input, or fall back to guess a milestone to bind. If there is no opened milestone the action will stop. If there are multiple opened milestones, the action will bind to the one whose due date is closest to the PR merged date and fall back to the first one sorted by the milestone created date.

2. How do I know which milestone to bind to a closed issue?

The action will only add milestone to a closed issue that has a merged PR fix, Otherwise, the action will do nothing. And the issue will be bound to exactly the same milestone as the PR that fixed it.

## License

Licensed under:

- MIT license ([LICENSE](LICENSE) or http://opensource.org/licenses/MIT)
