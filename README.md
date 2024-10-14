# Milestone Action

[中文说明](README.zh-CN.md)

## Features

- Add milestone to merged PRs automatically.

## Planed Features

- [ ] Add milestone to closed issues that have a merged fix PR
- [ ] Create milestone by title, description and due date
- [ ] Close milestone by title or milestone number

## Usage

```yaml

name: Milestone Action
on:
  pull_request_target:
    types: [closed]

jobs:
  update-milestone:
    runs-on: ubuntu-latest
    name: Milestone Update
    steps:
      - name: Set Milestone
        uses: hustcer/milestone-action@main
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Inputs

To be updated ...

## License

Licensed under:

- MIT license ([LICENSE](LICENSE) or http://opensource.org/licenses/MIT)
