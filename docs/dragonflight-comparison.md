# 三个 Dragonflight WoW UI 插件仓库深度对比分析

> 初版日期：2026-03-25 | 更新日期：2026-04-05
> 基于 GitHub 远程仓库克隆 + 本地代码实际分析

## Context

从**代码架构**和**功能覆盖**两个维度，深度对比以下三个 Dragonflight 风格 WoW UI 插件仓库。

| 仓库 | 作者 | 版本 | 定位 |
|------|------|------|------|
| [dragonflight-fix](https://github.com/aymmmmmm/dragonflight-fix) | aymmmmmm | ~~v1.3.3-fix~~ → **v2.0.0** | 中文本地化修复版，基于 DragonflightUI-Reforged |
| [-DragonflightReloaded](https://github.com/paokkerkir/-DragonflightReloaded) | paokkerkir | v2.3.5 | Reloaded 版本，功能完整 |
| [-Dragonflight3](https://github.com/Flaxic-LUA/-Dragonflight3) | Guzruul (Flaxic-LUA) | Beta | 全新重写，工业级架构 |

---

## 一、代码架构对比

### 1.1 项目规模（实测数据）

| 维度 | dragonflight-fix | DragonflightReloaded | Dragonflight3 |
|------|-----------------|---------------------|---------------|
| Lua 文件数 | ~~38~~ → **51** | 43 | **124** |
| Lua 代码行数 | ~~16,623~~ → **25,112** | 19,573 | **46,885** |
| Lua 代码大小 | ~~732 KB~~ → **1,160 KB** | 765 KB | **2,424 KB** |
| .toc 加载文件数 | ~~31~~ → **57**（含 GUI） | 60 | 92+ |
| 项目总大小 | ~~37 MB~~ → **75 MB** | 41 MB | **70 MB** |

**变化**：dragonflight-fix 代码量增长 **51%**（+8,489 行），已超过 DragonflightReloaded，接近 Dragonflight3 的一半。

### 1.2 核心架构模式

```
┌─────────────────────────────────────────────────────────────────────┐
│                         架构层级对比                                 │
├──────────────────┬──────────────────┬───────────────────────────────┤
│ dragonflight-fix │ Reloaded         │ Dragonflight3                 │
│ (v2.0.0 DFUI)   │ (DFRL)           │ (DF)                          │
├──────────────────┼──────────────────┼───────────────────────────────┤
│ core/ (6文件)    │ core/ (6文件)    │ core/ (7文件)                 │
│  error/core/     │  error/core/     │  namespace/env/polyfill/      │
│  tools/statusbar │  tools/statusbar │  init/slash/compat            │
│  compat/first    │  compat/first    │                               │
│                  │                  │                               │
│ libs/ (5个)      │ libs/ (3个)      │ libs/ (8个独立库)             │
│  libtipscan      │  libtipscan      │  events/cast/tipscan/spell/   │
│  libspell        │  libspell        │  debuff/healcomm/health/guid  │
│  libdebuff       │  libdebuff       │                               │
│  libguid ★       │                  │                               │
│  libevents ★     │                  │                               │
│                  │                  │                               │
│ data/ (3文件)    │ data/ (2文件)    │ tables/ (含迁移系统)          │
│  tables          │  tables+debuffs  │ + tools/ (9文件)              │
│  debuffs         │                  │                               │
│  talents_desc ★  │                  │                               │
│                  │                  │                               │
│ modules/         │ modules/         │ mods/ (92个Lua文件)           │
│ (37个Lua文件)    │ (37个Lua文件)    │ + mixins/ + locale/           │
├──────────────────┼──────────────────┼───────────────────────────────┤
│ 命名空间: DFUI ★ │ 命名空间: DFRL   │ 命名空间: DF                  │
│ SavedVars: 4个   │ SavedVars: 4个   │ SavedVars: 5个                │
│ 加载: .toc直列   │ 加载: .toc直列   │ 加载: XML分层清单             │
└──────────────────┴──────────────────┴───────────────────────────────┘
```

★ = v2.0.0 新增

### 1.3 关键架构差异

| 特性 | fix (DFUI v2.0.0) | Reloaded (DFRL) | Dragonflight3 (DF) |
|------|-----|----------|---------------|
| 命名空间 | **DFUI** ★（已从 DFRL 重命名） | DFRL | DF |
| 模块注册 | `DFUI:NewMod()` | `DFRL:NewMod()` | `DF:NewModule(name, priority, fn)` + 触发条件 |
| 配置 API | `DFUI:GetTempDB/SetTempDB` | `DFRL:GetTempDB/SetTempDB` | `DF_Profiles` + 版本迁移链 (v1→v2→v3) |
| 回调系统 | `NewCallbacks` (5个) | `NewCallbacks` (5个) | `NewCallbacks` + 元数据驱动 UI 生成 |
| 兼容层 | `compat.lua` (34项) | `compat.lua` | **`polyfill.lua`** (SetSize/GetSize/print 等 API 补丁) |
| 配置导入导出 | ✅ 序列化+校验和 ★ | ❌ | ❌ |
| 错误系统 | 自定义错误处理（节流） | 自定义错误处理（节流） | **环境沙盒 (`setfenv`) + 错误收集器** |
| GUID 追踪 | ✅ libguid ★ | ❌ | ✅ libguid |
| 自定义事件 | ✅ libevents ★ | ❌ | ✅ libevents |
| 数据持久化 | 4 个 SavedVariables | 4 个 SavedVariables | 5 个 SavedVariables |

---

## 二、功能覆盖对比

### 2.1 功能矩阵

| 功能模块 | fix (v2.0.0) | Reloaded | Dragonflight3 |
|---------|-----|----------|---------------|
| **动作条系统** | ✅ 56 项配置 | ✅ 56+ 项配置 + 距离检测 | ✅ 多条 + 宠物条 + 姿态条 |
| **施法条** | ✅ 火花/闪光动画 | ✅ 动画完整 | ✅ 通道 + 跳跃释放 |
| **单位框架(玩家)** | ✅ 含血球系统 ★ | ⚠️ 标记"待实现" | ✅ 完整 |
| **单位框架(目标)** | ✅ | ⚠️ 标记"待实现" | ✅ 完整 |
| **单位框架(小队)** | ✅ | ⚠️ 标记"待实现" | ✅ 群组 + Raid 框架 |
| **背包系统** | ✅ | ✅ | ✅ 统一背包 + 搜索 + 自动售灰 |
| **小地图** | ✅ | ✅ + 坐标收集器 | ✅ 标记收集器 |
| **聊天系统** | ✅ 含暗色模式 ★ | ✅ | ✅ **Intellisense + 学习数据** |
| **菜单系统** | ✅ + 声音管理 ★ | ✅ 8 按钮 | ✅ |
| **经验/声望条** | ✅ | ✅ | ✅ |
| **框架移动** | ✅ | ✅ Ctrl+Shift+Alt | ✅ **编辑模式 + 网格对齐** |
| **配置界面** | ✅ 9 个 GUI 模块 + 导入导出 ★ | ✅ 9 个 GUI 模块 | ✅ 标签系统 + 性能监测 |
| **双主题模式** | ✅ 明/暗切换 | ✅ 明/暗切换 + 8 个滑块 | ✅ |
| **光环/Buff 系统** | ✅ **完整系统** ★ | ✅ 完整光环系统 | ✅ BuffWatch 监控 |
| **Buff 计时器** | ✅ **多精度分层** ★ | ✅ 基于 GUID | ✅ |
| **天赋规划** | ✅ **20方案模拟** ★ | ❌ | ❌ |
| **天赋描述数据库** | ✅ ★ | ❌ | ❌ |
| **冷却时间数字** | ✅ ★ | ❌ | ✅ |
| **物品比较** | ✅ ★ | ❌ | ✅ |
| **职业配色管理** | ✅ 三套预设 ★ | ❌ | ✅ |
| **Tooltip 增强** | ✅ 距离+目标的目标 ★ | ✅ tooltip.lua | ✅ 距离 + 目标 + 生命值条 |
| **暗黑血球系统** | ✅ orbs.lua ★ | ❌ | ❌ |
| **姓名板** | ❌ | ⚠️ 基于版本检查 | ✅ **Debuff 显示** |
| **面板美化** | ❌ | ❌ | ✅ **21+ 子模块** |
| **HealComm** | ❌ | ❌ | ✅ 治疗通信库 |
| **健康值估算** | ❌ | ❌ | ✅ libhealth |
| **施法追踪库** | ❌ | ❌ | ✅ libcast |
| **开发工具** | ❌ | ❌ | ✅ Frame Inspector + SafeBoot |
| **减益数据库** | ✅ 933 条 | ✅ 933 条减益数据 | ✅ libdebuff |

### 2.2 v2.0.0 新增功能清单（对比 v1.3.3-fix）

| # | 功能 | 来源 | 说明 |
|---|------|------|------|
| 1 | 完整 Buff/Debuff 系统 | Reloaded | 多单位 + 4 色减益 + 冷却螺旋 + 多精度计时（GetPlayerBuffTimeLeft / GUID / LookupDuration） |
| 2 | 天赋规划系统 | 自研 | 20 方案 + 前置验证 + Shift 重置 + 滚轮操作 |
| 3 | 天赋描述数据库 | 自研 | talents_desc.lua，天赋当前/下级效果说明 |
| 4 | 冷却时间数字 | DF3 移植 | 动作按钮 CD 显示 |
| 5 | 物品比较 | DF3 移植 | Shift 悬停装备并排对比 |
| 6 | 职业配色管理 | DF3 移植 | Vanilla/TBC/Dragonflight 三套预设 |
| 7 | Tooltip 增强 | DF3 移植 | 鼠标跟随 + 目标的目标 + 距离 |
| 8 | libguid 库 | DF3 移植 | GUID 追踪（SuperWoW 原生 / 伪 GUID 回退） |
| 9 | libevents 库 | DF3 移植 | PLAYER_AFTER_ENTERING_WORLD / SYNC_READY |
| 10 | 暗黑血球系统 | 自研 | Diablo 风格 HP/MP 球体 |
| 11 | 配置导入导出 | 自研 | 序列化+校验和+跨角色同步 |
| 12 | 命名空间重构 | 自研 | DFRL → DFUI，SavedVariables 全面更名 |

### 2.3 各仓库独有功能（更新后）

#### dragonflight-fix 独有
- **天赋规划/模拟系统** — 20 方案切换 + 前置验证 + 层级解锁 + 滚轮加减点（其他两者均无）
- **天赋描述数据库** — talents_desc.lua，显示天赋各级效果文字
- **暗黑血球系统** — orbs.lua，Diablo 风格 HP/MP 球体显示
- **配置导入导出** — 序列化字符串 + 校验和，支持跨角色/跨设备同步
- **完整中文本地化** — 界面、设置、提示全部中文化（内联方式）
- **多精度 Buff 计时** — 玩家精确/宠物回退/目标仅 GUID，分层精度策略
- **动画状态条框架** — statusbar.lua 含脉冲/切割/渐变动画

#### DragonflightReloaded 独有
- **距离检测动作条** — 动作按钮距离指示
- **ShaguTweaks 深度集成** — 完整兼容性管理面板

#### Dragonflight3 独有
- **Polyfill 兼容层** — 为 Vanilla 1.12.1 补全现代 API
- **21+ 面板美化** — 人物/装备/法术书/天赋/社交等系统面板
- **Frame 检查器** — `/df inspect` 实时显示框架信息
- **安全启动模式** — `/df safeboot` 禁用所有模块调试
- **HealComm/Health/Cast 库** — 团队治疗通信 + 怪物血量估算 + 施法追踪
- **编辑模式网格对齐** — 拖拽调整所有 UI 框架
- **配置版本迁移系统** — v1→v2→v3 自动迁移
- **聊天 Intellisense** — 智能补全 + 学习系统
- **XML 分层加载** — 7 个 XML 清单控制加载顺序
- **本地化系统** — DF.L() 函数 + zhCN.lua 1,449 行翻译
- **姓名板系统** — 含 Debuff 显示

---

## 三、关系与继承

```
DragonflightUI-Reforged (原始项目, 作者: Guzruul)
    │
    ├──fork──→ dragonflight-fix (v1.3.3-fix → v2.0.0)
    │           v1.3.3: 中文本地化 + Turtle WoW 兼容性修复
    │           v2.0.0: ★ 命名空间 DFRL→DFUI
    │                   ★ 从 Reloaded 合并 Buff/Debuff 系统
    │                   ★ 从 DF3 移植 cooldowns/itemcompare/colors/tooltip/libguid/libevents
    │                   ★ 自研 天赋规划/血球/配置导入导出
    │
    ├──fork/续作──→ DragonflightReloaded (v2.3.5)
    │               • 添加 3 个库 (tipscan/spell/debuff)
    │               • 933 条减益数据库
    │               • 完整光环/Buff 系统
    │               • 单位框架未完成（标记"待实现"）
    │
    └──独立重写──→ Dragonflight3 (Beta)
                    • 全新 DF 命名空间
                    • 8 个独立库 + 79 模块
                    • 工业级开发工具链
```

---

## 四、优势评估（更新后）

### dragonflight-fix 优势
1. **中文用户最友好** — 唯一在代码中内联完整中文的版本
2. **单位框架完成度最高** — 玩家/目标/小队全部实现（Reloaded 仍标记"待实现"）
3. **Buff/Debuff 系统最精细** — 多精度分层计时（玩家精确 → 宠物回退 → 目标仅 GUID）
4. **天赋系统独一无二** — 规划/模拟功能三者中唯一拥有
5. **功能综合度最高** — 融合了 Reloaded 的 Buff 系统 + DF3 的实用模块 + 自研特色功能
6. **配置可迁移** — 导入导出+校验和，唯一支持跨角色配置同步

### DragonflightReloaded 优势
1. **版本最成熟** — v2.3.5，21 次提交迭代
2. **距离检测动作条** — fix 和 DF3 未集成

### Dragonflight3 优势
1. **架构最先进** — Polyfill、XML 分层加载、版本迁移
2. **代码量最大** — 46,885 行，模块覆盖最广
3. **代码质量最高** — Luacheck + check.sh + 统一命名
4. **库系统最强** — HealComm/Health/Cast 等团队级功能
5. **开发体验最好** — Frame 检查器、安全启动、编辑模式
6. **面板美化最全** — 21+ 系统面板

---

## 五、综合推荐（更新后）

| 使用场景 | 推荐 | 原因 |
|---------|------|------|
| 中文玩家日常使用 | **dragonflight-fix** | 唯一完整中文化 + 功能最综合 |
| 需要精细 Buff/天赋系统 | **dragonflight-fix** | 多精度计时 + 天赋规划独有 |
| 团队副本（治疗预测等） | **Dragonflight3** | HealComm / Raid 框架 / libhealth |
| 全面 UI 替换 + 面板美化 | **Dragonflight3** | 面板美化覆盖最广 (21+ 面板) |
| 二次开发/学习架构 | **Dragonflight3** | 工业级架构，代码质量最高 |

---

## 六、仍可从其他仓库借鉴的功能

完成 v2.0.0 后，以下功能仍是 dragonflight-fix 缺失的高价值项：

| 优先级 | 来源 | 功能 | 说明 |
|--------|------|------|------|
| P1 | Dragonflight3 | 姓名板系统 | 职业着色 + Debuff 显示，fix 完全缺失 |
| P1 | Dragonflight3 | HealComm 治疗预测 | 团队副本核心需求 |
| P2 | Dragonflight3 | 面板美化 | 银行/法术书/角色面板等 |
| P2 | Dragonflight3 | libhealth 怪物血量 | 目标框架增强 |
| P2 | Dragonflight3 | libcast 施法追踪 | 目标施法条 |
| P2 | Dragonflight3 | 挥击计时器 | 近战核心功能 |
| P2 | Dragonflight3 | CC 控制监视 | PvP 实用 |
| P3 | Dragonflight3 | 编辑模式网格对齐 | 框架拖拽增强 |
| P3 | Dragonflight3 | 配置版本迁移 | 升级不丢配置 |

---

## 七、远程文档同步状态

远程仓库（GitHub）有 9 个文档，本地有 4 个。以下为各文档的时效性：

| 远程文档 | 本地存在 | 时效性 | 说明 |
|---------|---------|--------|------|
| dragonflight-comparison.md | ✅ | ❌ 严重过时 → **已重写**（本文件） | 原文基于 v1.3.3，现已更新至 v2.0.0 |
| aura-timer-design.md | ✅ | ⚠️ 已更新 | 补充了 SnapshotAndDetectNewAuras 间接路径说明 |
| dragonflight-fix-talent-planning.md | ✅ | ⚠️ 已更新 | 变量名 DFRL→DFUI，行数 591→1077，删除过时行号 |
| frame-position-export-design.md | ✅ | ❌ 未实现 → **已标注** | AbsToRel/RelToAbs 设计未实现，标注为设计稿 |
| profile-export-import-lessons.md | ✅ | ✅ 准确 | 与代码一致 |
| dragonflight-feature-discovery.md | ❌ 缺失 | ⚠️ 部分过时 | 功能清单基于 v1.3.3，许多"未移植"项已完成 |
| dragonflight-fix-execution-plan.md | ❌ 缺失 | ⚠️ 大部分已完成 | Phase 0 + Phase 1 大部分已实现 |
| dragonflight-fix-optimization-guide.md | ❌ 缺失 | ⚠️ 部分过时 | 短板分析中多项已修复 |
| dragonflight-fix-work-plan.md | ❌ 缺失 | ⚠️ 需更新进度 | "半完成"项已全部激活，Phase 1 大部分已完成 |

### 执行计划进度跟踪（对比 work-plan / execution-plan）

| 阶段 | 计划任务 | 当前状态 |
|------|---------|---------|
| **Phase 0** 激活已有文件 | .toc 加入 libs/debuffs/auras/sounds | ✅ 已完成（sounds.lua 存在但未加入 .toc） |
| **1.1** 冷却时间数字 | 新建 cooldowns.lua | ✅ 已完成 |
| **1.2** 物品比较 | 新建 itemcompare.lua | ✅ 已完成 |
| **1.3** 职业配色 | 新建 colors.lua | ✅ 已完成 |
| **1.4** Tooltip 增强 | 扩展 tooltip.lua | ✅ 已完成 |
| **1.5** 聊天增强 | 扩展 chat.lua | ⚠️ 需确认具体新增内容 |
| **1.6** 配置版本迁移 | 修改 core.lua | ❌ 未实现 |
| **1.7** GUID 追踪库 | 新建 libguid.lua | ✅ 已完成 |
| **1.8** 自定义事件库 | 新建 libevents.lua | ✅ 已完成 |
| **2.1** 挥击计时器 | 新建 swingtimer.lua | ❌ 未实现 |
| **2.2** CC 控制监视 | 新建 nocontrol.lua | ❌ 未实现 |
| **2.3** 距离显示器 | 新建 distance.lua | ❌ 未实现 |
| **2.4** 连击点可视化 | 新建 combopoints.lua | ❌ 未实现 |
| **2.5** HealComm | 新建 libhealcomm.lua | ❌ 未实现 |
| **2.6** 怪物血量 | 新建 libhealth.lua | ❌ 未实现 |
| **2.7** 施法追踪 | 新建 libcast.lua | ❌ 未实现 |
| **3.x** 视觉增强 | 环境边框/暗化/姓名板/面板 | ❌ 未实现 |
| **4.x** 自身优化 | BUG修复/错误处理/字体去重 | ⚠️ 部分完成（字体统一等） |
| **—** 天赋规划 | 自研功能（不在原计划中） | ✅ **超额完成** |
| **—** 暗黑血球 | 自研功能（不在原计划中） | ✅ **超额完成** |
| **—** 配置导入导出 | 自研功能（不在原计划中） | ✅ **超额完成** |
| **—** 命名空间重构 | DFRL→DFUI | ✅ **超额完成** |
| **—** 天赋描述数据库 | talents_desc.lua | ✅ **超额完成** |

**总结**：Phase 0 + Phase 1（8 项中 7 项）已完成。Phase 2-4 尚未启动。额外自研了 5 项计划外功能。
