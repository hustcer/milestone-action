# Milestone Action

[![Setup-Bend@Dev](https://github.com/hustcer/setup-bend/actions/workflows/basic.yml/badge.svg)](https://github.com/hustcer/setup-bend/actions/workflows/basic.yml)

本 GitHub Action 将为你配置一个 [Bend](https://github.com/HigherOrderCO/Bend) 开发环境。适用于 Github `macos`, `ubuntu` 和 `Windows` 工作流运行时镜像。


## 使用

### 基础使用

使用 `hustcer/setup-bend` 非常简单，只需要按照下面示例即可：

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

或者也可以参考下本仓库的 [test.yaml](https://github.com/hustcer/setup-bend/blob/main/.github/workflows/test.yml) 例子。

在极少数情况下，你可能会看到速率限制之类的错误。如果发生这种情况，你可以通过设置 `GITHUB_TOKEN` 环境变量来避免该问题：

```yaml
- uses: hustcer/setup-bend@v1
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### 输入

目前本 Action 不需要任何输入

## 许可

Licensed under:

- MIT license ([LICENSE](LICENSE) or http://opensource.org/licenses/MIT)
