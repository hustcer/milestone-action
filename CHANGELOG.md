# Changelog
All notable changes to this project will be documented in this file.

## [2.3.0] - 2024-10-27

### Features

- Don't update the milestone if it was set and call without the `--force` option (#92)

## [2.2.0] - 2024-10-26

### Bug Fixes

- Don't set milestone if it's already been set with the right milestone (#82)

### Features

- Add output milestone number support for creating milestone (#87)
- Output closed milestone number (#89)
- Try to fix permission error by setting `pull-requests: write`

## [2.1.0] - 2024-10-25

### Bug Fixes

- Do not add invalid milestone to closed issues (#75)
- Fix milestone query for closed issue (#76)
- Fix milestone binding for closes issues when No close PR found (#78)
- Sleep 2sec for milestone query of closed issues (#80)

### Documentation

- Update README.md for action Inputs (#56)
- Add FAQ (#60)
- Add README.zh-CN.md (#61)

### Features

- Try to query issue closed by PR with `graphql`
- Use Github `graphql` API to query issue closer (#73)

### Miscellaneous Tasks

- Update action description

### Deps

- Upgrade `Nushell` to v0.99 (#65)

## [2.0.0] - 2024-10-20

### Features

- Create milestone by title, description and due date
- Close milestone by title or milestone number
- Add milestone to closed issues that have a merged PR fix automatically
- Add `--dry-run` for bind milestone to pr and issue support

## [1.0.0] - 2024-10-17

### Features

- Add milestone to merged PRs automatically
- Ignore closed PR that has not been merged (#30)
- Check previous milestone for `--force` flag, close #27 (#33)

# Changelog
All notable changes to this project will be documented in this file.
