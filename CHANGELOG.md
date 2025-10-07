# Changelog
All notable changes to this project will be documented in this file.

## [2.10] - 2025-10-07

### Features

- Try to inherit milestone from closing issues (#129)

### Miscellaneous Tasks

- Export guess-milestone-for-pr custom command (#124)

### Deps

- Upgrade Nu to v0.107 (#120)

## [2.9] - 2025-07-26

### Bug Fixes

- Fix getting Nu binary path for Nushell 0.106

### Deps

- Upgrade Nu to 0.106 and pin `hustcer/setup-nu` to v3.20 (#118)

## [2.8] - 2025-06-11

### Miscellaneous Tasks

- Upgrade `Nu` to 0.105 and pin `hustcer/setup-nu` to v3.19 (#117)

## [2.7] - 2025-03-22

### Features

- Add DeepSeek Code review support by `hustcer/deepseek-review`

### Deps

- Upgrade `Nu` to **v0.103** (#114)
- Upgrade `Nu` to v0.102 (#113)

### Refactor

- Refactor `compare-ver` common custom command (#111)

## [2.6.0] - 2025-01-03

### Bug Fixes

- Fix add milestone to issues that closed by auto-merge PRs (#110)

### Deps

- Upgrade Nu to v0.101 (#108)

## [2.5.0] - 2024-11-16

### Bug Fixes

- Fix delete milestone

### Features

- Sleep 3sec for issue's milestone query (#97)
- Add delete milestone by title or number support (#98)
- Add CI workflow to create, close and delete a milestone (#100)

### Miscellaneous Tasks

- Add `cspell` spelling check hook for `lefthook` (#103)
- Update `Nushell` to v0.100 (#106)

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
