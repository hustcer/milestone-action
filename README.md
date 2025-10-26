# Milestone Action

[中文说明](README.zh-CN.md)

## Features

- Automatically add milestones to merged PRs
- Automatically add milestones to closed issues with merged PR fixes
- Create milestones with title, description, and due date
- Close milestones by title or milestone number
- Delete milestones by title or milestone number

## Usage

Automatically associate milestones with merged PRs or closed issues that has a merged PR fix:

```yaml
name: Milestone Action
on:
  issues:
    types: [closed]
  pull_request_target:
    types: [closed]

# Required permissions for the action to work
permissions:
  issues: write
  contents: write
  pull-requests: write

jobs:
  update-milestone:
    runs-on: ubuntu-latest
    name: Milestone Update
    steps:
      - name: Set Milestone for PR
        uses: hustcer/milestone-action@v2
        if: github.event.pull_request.merged == true
        with:
          action: bind-pr # `bind-pr` is the default action
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
    milestone: v1.0 # Milestone title or number
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

Delete milestone by title or milestone number:

```yaml
- name: Delete Milestone
  uses: hustcer/milestone-action@v2
  with:
    action: delete
    milestone: v1.0 # Milestone title or number
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Inputs

| Name               | Type    | Description                                                                                                                            |
| ------------------ | ------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| action             | String  | Action to perform: create, close, delete, bind-pr, bind-issue, defaults to `bind-pr`                                                   |
| title              | String  | Title of the milestone to create                                                                                                       |
| due-on             | String  | Due date of the milestone (yyyy-mm-dd) to create                                                                                       |
| description        | String  | Description of the milestone to create                                                                                                 |
| milestone          | String  | Title or number of the milestone to close or delete; can also be used to specify the milestone title to associate with the PR or issue |
| force              | Boolean | If the PR or issue already has a milestone, simply remove it and assign a new one if they differ                                       |
| inherit-from-issue | Boolean | Try to inherit milestone from closing issues for bind-pr action. Defaults to `true`                                                    |
| github-token       | String  | The GitHub token to access the API for milestone management, defaults to `${{ github.token }}`                                         |

### FAQ

1. How can I determine which milestone to associate with a merged PR?

First, if the PR is closed without being merged, the action will take no effect. Once the PR is merged, the milestone is determined using the following priority order:

- **Priority 1:** If you explicitly specify a milestone in the input, that milestone will be used.
- **Priority 2:** If `inherit-from-issue` is enabled (default), the action will check if the PR closes any issues. If all closing issues have the same milestone, the PR will inherit that milestone.
- **Priority 3:** If no milestone is inherited from issues, the action will use date-based detection. If multiple open milestones exist, the action will bind to the one with the due date closest to the PR's merge date; if no such milestone exists, it will default to the earliest-created milestone based on creation date.

**Example:** If Issue #1 has milestone "1.0.0" and PR #2 closes Issue #1, then PR #2 will automatically get milestone "1.0.0" when merged.

2. How can I determine which milestone to associate with a closed issue?

The action will only add a milestone to a closed issue that has been resolved by a merged PR. Otherwise, the action will do nothing. The issue will then be assigned to the same milestone as the PR that fixed it.

3. Can I disable milestone inheritance from issues?

Yes, you can set `inherit-from-issue: false` in the action inputs to disable this feature. When disabled, the action will only use date-based milestone detection or the explicitly specified milestone.

## License

Licensed under:

- MIT license ([LICENSE](LICENSE) or http://opensource.org/licenses/MIT)
