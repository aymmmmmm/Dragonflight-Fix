# 发版流程

> 优先级：P2
> 最后更新：2026-06-01

## 概览

Dragonflight-Fix 是纯 Lua/XML 客户端插件，由游戏直接加载，**无构建步骤、无 CI/CD**（仓库内无 `.github/`、`.pkgmeta`、任何 `*.yml`/`*.yaml`）。发版完全手工：改版本号 → 提交 → 打语义化 git tag → 推送 → 在 GitHub 建 Release。分发渠道为 GitHub，非 CurseForge。

版本号采用两段式语义化 tag（`v2.0` / `v2.1` …）。当前仓库已有 tag：`v2.0`、`v2.1`；远端 `origin = https://github.com/aymmmmmm/Dragonflight-Fix.git`，分支 `main`（另有 `dev`）。

## 关键文件

| 文件 | 作用 |
| --- | --- |
| `Dragonflight-Fix.toc` | 第 6 行 `## Version: 2.1` —— **发版号唯一权威来源** |
| `core/core.lua` | 第 23 行 `DFUI.DBversion = "2.0"` —— 与发版号解耦的另一标识（见下） |
| `.gitattributes` | `export-ignore` 规则，把开发资料踢出 release/源码 zip |
| `.gitignore` | 忽略 `*.bak`/`*.swp`/`*~`/`Thumbs.db`/`.DS_Store` |

## 核心实现

### 发版号唯一来源：`.toc ## Version:`

`Dragonflight-Fix.toc:6` 的 `## Version: 2.1` 是发版号的唯一权威值。运行期通过 `DFUI:GetInfoOrCons("version")`（`core/core.lua:33-34`，内部调 `GetAddOnMetadata(name, "Version")`）读出，显示在 GUI「关于」面板的「插件版本」行（`modules/gui/info.lua:43-44`）。

### `DFUI.DBversion` 与发版号解耦

`core/core.lua:23` 定义 `DFUI.DBversion = "2.0"`，是一个独立于发版号的字符串常量：

- 它在 GUI「关于」面板单独显示为「数据库版本」行（`modules/gui/info.lua:45-46`），与上面的「插件版本」是两个不同字段。当前实证：插件版本 `2.1`（来自 `.toc`），数据库版本 `2.0`（来自 `DFUI.DBversion`）—— 二者不同，即为解耦的直接证据。
- 它**只用于显示**，未参与任何 SavedVariables 版本比对/迁移逻辑。配置迁移由 `DFUI:SyncProfiles()`（结构 diff 自动合并/清理，`core/core.lua` 内）承担，跨命名空间一次性迁移另由 `migrate()` 处理。`DFUI.DBversion` 不在这些路径里被读取（全仓引用点仅 `core/core.lua:23` 赋值 + `modules/gui/info.lua:46` 显示）。
- **发版时不要改 `DFUI.DBversion`** —— 它不随发版号走，改它无功能收益且会与「关于」面板既有展示语义错位。

### `export-ignore`：开发资料不进发布 zip

`.gitattributes` 内容：

```
art/** export-ignore
*.bak export-ignore
```

- 用 `art/**`（递归匹配目录下所有文件）而非 `art/`（目录形不匹配文件，无效）。作用是把 `art/` 下的 AI 设计参考图从 GitHub source archive / `git archive` 产出的 zip 中剔除，**文件仍保留在仓库**，clone 不受影响（注释见 `.gitattributes:1-2`）。
- `*.bak export-ignore` 同理把备份文件踢出 zip；`.gitignore` 则从源头阻止 `*.bak` 被提交。

### 手工发版 SOP

无脚本，逐步手工执行：

1. 改 `Dragonflight-Fix.toc:6` 的 `## Version:` 为新版本号。
2. `git commit`（约定 message 形如 `chore(release): 升级至 vX.Y`）。
3. `git tag -a vX.Y -m "..."` 打附注 tag。
4. `git push origin main --follow-tags` 推送提交与 tag。
5. 在 GitHub 建 Release（`gh release create vX.Y ...` 或网页手动建）。

## 已知坑或限制

- **`gh` CLI 需先 `gh auth login`**（交互式），未登录无法用 `gh release create`。首批 v2.0/v2.1 的 Release 由用户在网页手动创建（凭据/浏览器登录均未走通）。是否能在本机非交互发版 —— **待实证**。
- **v2.0 的源码 zip 仍含 `art/`**：该 tag 对应提交早于 `.gitattributes` 落地，回溯 tag 沿用历史 attributes，属固有现象，对历史版本无害，**不要改写历史/force-push** 去修。
- 回溯 tag 名（`vX.Y`）与该 tag 时点 `.toc` 内的版本字符串可能小幅不一致，属预期，不追溯改写。
- 无 CI 即无自动化校验：tag 与 `.toc ## Version:` 是否对齐、Release 是否漏建，全靠人工，发版前需逐项核对。
