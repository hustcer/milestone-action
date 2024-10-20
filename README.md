# Milestone Action

[中文说明](README.zh-CN.md)

## Features

- Add milestone to merged PRs automatically
- Add milestone to closed issues that have a merged PR fix automatically
- Create milestone by title, description and due date
- Close milestone by title or milestone number

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

## Inputs

To be updated ...

## License

Licensed under:

- MIT license ([LICENSE](LICENSE) or http://opensource.org/licenses/MIT)
