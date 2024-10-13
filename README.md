# Milestone Action

[中文说明](README.zh-CN.md)

[![Setup-Bend@Dev](https://github.com/hustcer/setup-bend/actions/workflows/basic.yml/badge.svg)](https://github.com/hustcer/setup-bend/actions/workflows/basic.yml)

This GitHub Action will setup a [Bend](https://github.com/HigherOrderCO/Bend) environment for you. It should work on Github `macos`, `ubuntu`, and `Windows` runners.

## Usage

### Basic

It's quite simple to use `hustcer/setup-bend`, just follow the example below:

```yaml
steps:
  - name: Checkout
    uses: actions/checkout@v4.1.7

  - name: Setup Bend
    uses: hustcer/setup-bend@v1

  - name: Check Bend Version
    run: |
        bend --version

```

Or, check the [test.yaml](https://github.com/hustcer/setup-bend/blob/main/.github/workflows/test.yml) example.

In rare circumstances you might get rate limiting errors, if this happens you can set the `GITHUB_TOKEN` environment variable.

```yaml
- uses: hustcer/setup-bend@v1
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Inputs

Currently no input required

## License

Licensed under:

- MIT license ([LICENSE](LICENSE) or http://opensource.org/licenses/MIT)
