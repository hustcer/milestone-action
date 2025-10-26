# Milestone Action

## 功能

- 自动为已合并的 PR 添加里程碑
- 自动为已合并修复PR的关闭 issue 添加里程碑
- 通过标题、描述和截止日期创建里程碑
- 通过标题或里程碑编号关闭里程碑
- 通过标题或里程碑编号删除里程碑

## 使用方法

自动为已合并的 PR 或为已合并修复PR的关闭 issue 添加里程碑：

```yaml
name: Milestone Action
on:
  issues:
    types: [closed]
  pull_request_target:
    types: [closed]

# Action 正常工作所需的权限
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

通过标题、描述和截止日期创建里程碑：

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

通过标题或里程碑编号关闭里程碑：

```yaml
- name: Close Milestone
  uses: hustcer/milestone-action@v2
  with:
    action: close
    milestone: v1.0 # 里程碑标题或编号
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

通过标题或里程碑编号删除里程碑：

```yaml
- name: Delete Milestone
  uses: hustcer/milestone-action@v2
  with:
    action: delete
    milestone: v1.0 # Milestone title or number
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## 输入参数

| 名称               | 类型    | 描述                                                                                   |
| ------------------ | ------- | -------------------------------------------------------------------------------------- |
| action             | String  | 要执行的操作, 可能的值未：create, close, delete, bind-pr, bind-issue，默认为 `bind-pr` |
| title              | String  | 要创建的里程碑标题                                                                     |
| due-on             | String  | 要创建的里程碑的截止日期（yyyy-mm-dd）                                                 |
| description        | String  | 要创建的里程碑描述信息                                                                 |
| milestone          | String  | 要关闭或删除的里程碑标题或编号，也可用于指定要绑定到 PR 或 issue 的里程碑标题          |
| force              | Boolean | 如果 PR 或 Issue 已有里程碑，且与新的不同，则移除旧的并设置新的                        |
| inherit-from-issue | Boolean | 对于 bind-pr 操作，尝试从关闭的 issues 继承里程碑。默认为 `true`                       |
| github-token       | String  | 用于访问 API 进行里程碑管理的 GitHub Token，默认为 `${{ github.token }}`               |

### 常见问题

1. 如何知道要将哪个里程碑绑定到已合并的 PR？

首先，如果 PR 未合并就关闭，将不会对其执行任何操作。PR 合并后，里程碑按照以下优先级顺序确定：

- **优先级 1:** 如果您在输入中明确指定了里程碑，将使用该里程碑。
- **优先级 2:** 如果启用了 `inherit-from-issue`（默认启用），action 会检查 PR 关闭的所有 issues。如果所有关闭的 issues 都有相同的里程碑，PR 将继承该里程碑。
- **优先级 3:** 如果没有从 issues 继承到里程碑，将使用基于日期的检测。如果有多个打开的里程碑，将优先绑定到截止日期最接近 PR 合并日期的里程碑，如果没有找到，则回退到最近创建的里程碑。

**示例：** 如果 Issue #1 有里程碑 "1.0.0"，PR #2 关闭了 Issue #1，那么 PR #2 合并时将自动获得里程碑 "1.0.0"。

2. 如何知道要将哪个里程碑绑定到已关闭的 issue？

该Action只会为有已合并 PR 修复的已关闭 issue 添加里程碑，否则不会执行任何操作。Issue 将被绑定到与修复它的 PR 完全相同的里程碑，这也意味着如果 PR 绑定里程碑失败也会导致 Issue 绑定里程碑失败。

3. 可以禁用从 issues 继承里程碑的功能吗？

可以，您可以在 action 的输入中设置 `inherit-from-issue: false` 来禁用此功能。禁用后，action 将只使用基于日期的里程碑检测或明确指定的里程碑。

## 许可

Licensed under:

- MIT license ([LICENSE](LICENSE) or http://opensource.org/licenses/MIT)
