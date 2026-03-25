# dragonflight-fix 优化参考指南：从 Reloaded 和 Dragonflight3 借鉴功能

> 生成日期：2026-03-25 | 更新：2026-03-25（整合功能深度挖掘结果）
> 详细功能发现清单见：`dragonflight-feature-discovery.md`

## Context

dragonflight-fix (v1.3.3-fix) 是面向中文 Turtle WoW 玩家的即用版本，但功能覆盖存在明显短板。通过代码分析发现，**Buff/Debuff 显示完全缺失**（代码中有 `-- doesnt work yet` 注释）是最严重的问题。本文档从 Reloaded（同 DFRL 架构，可直接复制）和 Dragonflight3（需 API 翻译）中筛选出高价值、可移植的功能。

**三仓库本地路径：**
- dragonflight-fix: `/home/ym/new_ilabel/turtle-wow/dragonflight-fix/`
- DragonflightReloaded: `/home/ym/new_ilabel/turtle-wow/-DragonflightReloaded/`
- Dragonflight3: `/home/ym/new_ilabel/turtle-wow/-Dragonflight3/`

**设计原则：**
- SuperWoW 和 UnitXP 依赖功能均纳入计划（条件检测，无则优雅降级）
- 所有配置项标签中文化
- 职业颜色统一管理，不再硬编码散落各模块

---

## 一、来源选择策略

```
移植难度由低到高：
  Reloaded (DFRL) ──直接复制──→ dragonflight-fix (DFRL)
  Dragonflight3 (DF) ──API翻译──→ dragonflight-fix (DFRL)

API 翻译速查：
  DF.profile[mod][opt]           → DFRL:GetTempDB(mod, opt)
  DF:NewDefaults(mod, defs)      → DFRL:NewDefaults(mod, defs)
  DF:NewModule(mod, pri, evt, fn)→ DFRL:NewMod(mod, pri, fn)
  DF.hooks.HookScript(f,s,fn)    → HookScript(f, s, fn)
  DF.hooks.HookSecureFunc(n,fn)  → DFRL.env.hooksecurefunc(n, fn)
  DF.common.KillFrame(f)         → f:Hide(); f:SetScript('OnUpdate', nil)
  DF.L('text')                   → 直接中文字符串
  media['tex:path']              → DFRL:GetInfoOrCons('tex')..'path'
  media['font:name']             → DFRL:GetInfoOrCons('font')..'name.ttf'
  DF.others.superWoW             → (UnitGUID ~= nil)
  DF.others.unitXP               → (UnitXP ~= nil)
  DF.others.server / isTurtle    → (GetRealmName() or ''):find('Turtle')
```

---

## 二、dragonflight-fix 当前短板分析

### 关键缺失功能

| 缺失功能 | 严重程度 | 代码证据 |
|---------|---------|---------|
| **Buff/Debuff 显示** | 致命 | `modules/frames/frames.lua:35-39` 有 `-- doesnt work yet` |
| **减益数据库** | 高 | 完全没有 debuff 持续时间数据 |
| **库文件系统** | 高 | 无 `libs/` 目录，无 tipscan/spell/debuff 库 |
| **冷却时间数字** | 高 | 动作按钮无CD秒数显示，基础QoL完全缺失 |
| **职业颜色管理** | 中 | 硬编码散落在 player/target/mini 三个模块，无统一管理 |
| **Tooltip 增强** | 中 | 仅 54 行，3 个选项（鼠标锚点、XY 偏移） |
| **聊天增强** | 中 | 仅 80 行基础实现，无历史/URL/时间戳 |
| **姓名板** | 中 | 完全缺失 |
| **面板美化** | 低 | 完全缺失（银行/法术书/天赋等） |
| **配置迁移** | 低 | 静态 DBversion="1.0"，升级重置配置 |

### 已知 BUG（代码中标记）

1. `modules/chat/chat.lua:3` — "BUG: 暴雪高亮在错误位置闪烁"
2. `modules/map/map.lua:41` — "BUG: 斜杠命令尚未实现"
3. `modules/gui/prof.lua` — "BUG: 新建档案后双击删除" + "输入名称残留"

### 代码质量问题

1. **错误处理**: `core/error.lua` 仅节流 2 次后完全抑制所有错误
2. **Channel 施法**: `modules/cast/cast.lua` 缺少中断动画和 tick 指示
3. **单位框架**: player.lua / target.lua 缺少战斗状态、威胁指示、断线检测
4. **代码重复**: 字体路径映射在 player.lua/target.lua/mini.lua/cast.lua/bars.lua 中重复

---

## 三、分阶段优化路线图

### Phase 1: 核心缺陷修复（P0 - 必须）

#### 1.1 Buff/Debuff 显示系统

**来源**: Reloaded（同 DFRL 架构，可直接复制）

**前置依赖（4 个文件，均直接复制）：**

| 文件 | 行数 | 功能 | 依赖 |
|------|------|------|------|
| `libs/libtipscan.lua` | 128 | 隐藏 Tooltip 扫描器 | 无 |
| `libs/libspell.lua` | 120 | 法术信息查询（图标/施法时间/范围） | libtipscan |
| `libs/libdebuff.lua` | 367 | Debuff 时间追踪 + GUID 追踪 | libtipscan + libspell |
| `data/debuffs.lua` | 959 | 933 条减益效果数据库 | 无（纯数据） |

**核心模块：**

| 文件 | 行数 | 功能 | 移植难度 |
|------|------|------|---------|
| `modules/unit/auras.lua` | 1,648 | 完整 Buff/Debuff UI 系统 | 需中文本地化 |

**auras.lua 功能清单：**
- Buff Bar（顶部右侧玩家 buff 显示，可替换默认 BuffFrame）
- 按单位显示 buff/debuff（Player/Target/Pet/Party）
- 4 种 Debuff 类型着色：魔法(蓝)/疾病(棕)/毒药(绿)/诅咒(紫)
- 计时器（Gold 或 White+Red 两种风格）
- 冷却螺旋覆盖层
- 50+ 配置项（图标大小/间距/行数/排序等）
- SuperWoW GUID 支持（可选，非强制）

**操作步骤：**
1. 在 fix 中创建 `libs/` 目录
2. 复制 3 个库文件到 `dragonflight-fix/libs/`
3. 复制 `debuffs.lua` 到 `dragonflight-fix/data/`
4. 复制 `auras.lua` 到 `dragonflight-fix/modules/unit/`
5. 更新 `.toc` 文件，在 `data\tables.lua` 后添加：
   ```
   data\debuffs.lua
   libs\libtipscan.lua
   libs\libspell.lua
   libs\libdebuff.lua
   ```
6. 在模块加载区域添加 `modules\unit\auras.lua`
7. 中文化 auras.lua 中的配置项标签

**源文件路径：**
```
FROM: -DragonflightReloaded/libs/libtipscan.lua
FROM: -DragonflightReloaded/libs/libspell.lua
FROM: -DragonflightReloaded/libs/libdebuff.lua
FROM: -DragonflightReloaded/data/debuffs.lua
FROM: -DragonflightReloaded/modules/unit/auras.lua
```

#### 1.2 修复 3 个已知 BUG

见上方"已知 BUG"列表。

---

### Phase 2: 高价值低成本功能（P1 - 应该）

#### 2.1 冷却时间数字 ★ 新增

| 项目 | 详情 |
|------|------|
| **来源** | Dragonflight3 `mods/general/cooldowns.lua` (~200 行) |
| **新增功能** | 动作按钮直接显示冷却秒数，按时段着色（<10s红 / 10-59s黄 / 1-5m白 / 5m+灰），可选显示秒数精度 |
| **当前状态** | fix 完全没有冷却数字显示 |
| **自含度** | 1/5（完全独立） |
| **移植难度** | 低 (~150 行修改，Hook ActionButton_OnUpdate) |
| **用户价值** | **极高** — 几乎所有 WoW 玩家都需要，替代 OmniCC 等独立插件 |

**源文件路径：**
```
FROM: -Dragonflight3/mods/general/cooldowns.lua
CREATE: dragonflight-fix/modules/ui/cooldowns.lua
```

#### 2.2 职业配色方案管理 ★ 新增

| 项目 | 详情 |
|------|------|
| **来源** | Dragonflight3 `mods/general/colors.lua` (~250 行) |
| **新增功能** | Vanilla/TBC/Dragonflight 三套职业颜色预设，资源条着色（法力蓝/怒气红/焦点棕/能量黄），全局统一管理 |
| **当前状态** | 职业颜色硬编码散落在 player.lua/target.lua/mini.lua |
| **自含度** | 1.5/5 |
| **移植难度** | 低 (~200 行新增 + 修改3个单位框架模块引用) |
| **用户价值** | 高 — 统一视觉风格，为后续姓名板/聊天职业颜色提供基础 |

**源文件路径：**
```
FROM: -Dragonflight3/mods/general/colors.lua
CREATE: dragonflight-fix/modules/ui/colors.lua
MODIFY: dragonflight-fix/modules/unit/player.lua (引用统一颜色表)
MODIFY: dragonflight-fix/modules/unit/target.lua (引用统一颜色表)
MODIFY: dragonflight-fix/modules/unit/mini.lua (引用统一颜色表)
```

#### 2.3 物品比较 ★ 新增

| 项目 | 详情 |
|------|------|
| **来源** | Dragonflight3 `mods/general/itemcompare.lua` (~150 行) |
| **新增功能** | Shift 悬停装备时并排显示已穿戴物品 Tooltip，自动映射 16 个装备槽 |
| **自含度** | 1/5（完全独立） |
| **移植难度** | 极低 (~100 行修改) |
| **用户价值** | 高 — 装备对比是每个玩家的刚需 |

**源文件路径：**
```
FROM: -Dragonflight3/mods/general/itemcompare.lua
CREATE: dragonflight-fix/modules/ui/itemcompare.lua
```

#### 2.4 聊天系统增强

| 项目 | 详情 |
|------|------|
| **来源** | Dragonflight3 `mods/chat/chat.lua` (775 行) + `chat-tools.lua` (186 行) |
| **新增功能** | 聊天历史 (500 条缓冲) / URL 自动检测 / 时间戳 / 频道缩写 (G/P/R/BG) / 职业颜色 / 聊天淡出 |
| **当前状态** | fix 仅 307 行基础实现（按钮/深色模式/颜色） |
| **自含度** | 1.5/5（高独立性） |
| **移植难度** | 低 (200-400 行修改) |
| **用户价值** | 高 — URL 检测对社交关键，时间戳对日志追踪有帮助 |

**源文件路径：**
```
FROM: -Dragonflight3/mods/chat/chat.lua
MODIFY: dragonflight-fix/modules/chat/chat.lua
```

#### 2.5 Tooltip 增强

| 项目 | 详情 |
|------|------|
| **来源** | Dragonflight3 `mods/tooltip/tooltip.lua` (304 行) |
| **新增功能** | 鼠标跟随 / 距离显示 (需 UnitXP，条件检测) / 目标显示 / 健康值美化 / 自定义颜色透明度缩放 |
| **当前状态** | fix 仅 54 行（鼠标锚点 + XY 偏移 3 个选项） |
| **自含度** | 2/5 |
| **移植难度** | 低-中 (150-200 行修改) |
| **用户价值** | 高 — 目标显示对 PvP 有用，距离显示对所有玩家有帮助 |

**源文件路径：**
```
FROM: -Dragonflight3/mods/tooltip/tooltip.lua
MODIFY: dragonflight-fix/modules/ui/tooltip.lua
```

#### 2.6 配置版本迁移系统

| 项目 | 详情 |
|------|------|
| **来源** | Dragonflight3 `core/init.lua` 第 19-85 行 |
| **新增功能** | 数据库版本管理 + 升级时自动合并新模块默认值 + 保留用户配置 |
| **当前状态** | fix 使用静态 `DBversion = "1.0"`，升级时重置所有配置 |
| **自含度** | 1/5（完全独立） |
| **移植难度** | 极低 (200-300 行新增) |
| **用户价值** | 高 — 避免每次升级丢失配置，对持续开发至关重要 |

**源文件路径：**
```
FROM: -Dragonflight3/core/init.lua (行19-85)
MODIFY: dragonflight-fix/core/core.lua
```

#### 2.7 GUID 追踪库

| 项目 | 详情 |
|------|------|
| **来源** | Dragonflight3 `libs/libguid.lua` (244 行) |
| **新增功能** | 伪 GUID 生成 / 单位映射维护 / 过期清理 (120秒) / 优先原生 UnitGUID (SuperWoW) |
| **自含度** | 1.5/5 |
| **移植难度** | 极低 (~100 行改动) |
| **用户价值** | 高 — Debuff 追踪和团队监视的基础设施 |

**源文件路径：**
```
FROM: -Dragonflight3/libs/libguid.lua
CREATE: dragonflight-fix/libs/libguid.lua
```

#### 2.8 自定义事件库 ★ 新增

| 项目 | 详情 |
|------|------|
| **来源** | Dragonflight3 `libs/libevents.lua` (~120 行) |
| **新增功能** | PLAYER_AFTER_ENTERING_WORLD（延迟50ms）、SYNC_READY（延迟2s）等自定义事件，解决原版事件时序问题 |
| **自含度** | 1/5（完全独立） |
| **移植难度** | 极低 (~80 行改动) |
| **用户价值** | 中 — 基础设施，提升其他模块的可靠性 |

**源文件路径：**
```
FROM: -Dragonflight3/libs/libevents.lua
CREATE: dragonflight-fix/libs/libevents.lua
```

---

### Phase 3: 战斗增强 + 实用工具（P2 - 可以）

#### 3.1 挥击计时器 ★ 新增

| 项目 | 详情 |
|------|------|
| **来源** | Dragonflight3 `mods/unitframes/swingtimer.lua` (~300 行) |
| **新增功能** | 主手/副手/远程武器倒计时条，英勇一击/劈砍队列检测，躲闪加速支持 |
| **依赖** | SuperWoW（UNIT_CASTEVENT / COMBAT_MELEE 事件） |
| **移植难度** | 低-中 (~200 行修改) |
| **用户价值** | 高 — 战士/盗贼核心 PvP 工具 |

**源文件路径：**
```
FROM: -Dragonflight3/mods/unitframes/swingtimer.lua
CREATE: dragonflight-fix/modules/unit/swingtimer.lua
```

#### 3.2 CC 控制监视 ★ 新增

| 项目 | 详情 |
|------|------|
| **来源** | Dragonflight3 `mods/general/nocontrol.lua` (~700 行) |
| **新增功能** | 被控时屏幕显示控制类型（眩晕/沉默/恐惧/缚根/催眠/魅惑/致残/减速），可用中断法术列表，脉冲发光 |
| **自含度** | 1.5/5 |
| **移植难度** | 低 (~200 行修改，主要是法术列表中文化和 API 翻译) |
| **用户价值** | 高 — PvP 必备 |

**源文件路径：**
```
FROM: -Dragonflight3/mods/general/nocontrol.lua
CREATE: dragonflight-fix/modules/ui/nocontrol.lua
```

#### 3.3 距离显示器 ★ 新增

| 项目 | 详情 |
|------|------|
| **来源** | Dragonflight3 `mods/general/distance.lua` (~400 行) |
| **新增功能** | 实时目标距离数字、侧边范围条（近战/远程模式）、按范围着色（绿/黄/红）、目标肖像 |
| **依赖** | UnitXP（distanceBetween API） |
| **移植难度** | 中 (~250 行修改) |
| **用户价值** | 高 — 猎人/法师/PvP 玩家需要精确距离判断 |

**源文件路径：**
```
FROM: -Dragonflight3/mods/general/distance.lua
CREATE: dragonflight-fix/modules/ui/distance.lua
```

#### 3.4 HealComm 治疗预测库

| 项目 | 详情 |
|------|------|
| **来源** | Dragonflight3 `libs/libhealcomm.lua` (252 行) |
| **功能** | 追踪队伍成员正在施法的治疗 / 显示预测 overlay / HealComm 协议广播 / 5职业法术数据库 |
| **移植难度** | 低 (~150 行改动) |
| **用户价值** | 高 — 治疗职业和坦克的关键工具 |

**源文件路径：**
```
FROM: -Dragonflight3/libs/libhealcomm.lua
CREATE: dragonflight-fix/libs/libhealcomm.lua
```

#### 3.5 怪物血量估算库

| 项目 | 详情 |
|------|------|
| **来源** | Dragonflight3 `libs/libhealth.lua` (244 行) |
| **功能** | 伤害值 + HP% 反推怪物最大 HP / 滚动平均 10 样本 / 8种战斗日志模式 |
| **移植难度** | 极低 (~80 行改动) |
| **用户价值** | 中 |

#### 3.6 施法追踪库

| 项目 | 详情 |
|------|------|
| **来源** | Dragonflight3 `libs/libcast.lua` (81 行) |
| **功能** | 伪造 UnitCastingInfo/UnitChannelInfo / 追踪其他玩家施法 / SuperWoW 兼容 |
| **移植难度** | 极低 (~50 行改动) |
| **用户价值** | 中 |

#### 3.7 编辑模式网格增强

| 项目 | 详情 |
|------|------|
| **来源** | Dragonflight3 `mods/general/editmode.lua` (~495 行) |
| **功能** | 拖拽时显示对齐网格 (64x64) / 框架位置快照 / 多模式 |
| **移植难度** | 低 (100-200 行修改) |
| **用户价值** | 中 |

#### 3.8 连击点可视化 ★ 新增

| 项目 | 详情 |
|------|------|
| **来源** | Dragonflight3 `mods/general/combopoints.lua` (~100 行) |
| **新增功能** | 5 个连击点图标，可配置大小和颜色，盗贼/德鲁伊专用 |
| **自含度** | 1/5（完全独立） |
| **移植难度** | 极低 (~60 行修改) |
| **用户价值** | 中 — 盗贼/猫德专属但很实用 |

**源文件路径：**
```
FROM: -Dragonflight3/mods/general/combopoints.lua
CREATE: dragonflight-fix/modules/ui/combopoints.lua
```

#### 3.9 自动截图 ★ 新增

| 项目 | 详情 |
|------|------|
| **来源** | Dragonflight3 `mods/general/autoscreenshot.lua` (~130 行) |
| **新增功能** | 升级/PvP等级变化/Boss击杀/声誉提升时自动截图，可配置延迟 |
| **自含度** | 1/5（完全独立） |
| **移植难度** | 极低 (~80 行修改) |
| **用户价值** | 中 — 趣味性功能，玩家口碑好 |

#### 3.10 卖出价值显示 ★ 新增

| 项目 | 详情 |
|------|------|
| **来源** | Dragonflight3 `mods/general/sellvalue.lua` (~180 行) |
| **新增功能** | Tooltip 显示物品 NPC 买卖价格，Shift 显示堆叠总价 |
| **自含度** | 1/5（完全独立） |
| **移植难度** | 低 (~120 行修改) |
| **用户价值** | 中 — 整理背包时实用 |

---

### Phase 4: 视觉增强 + 面板（P3 - 远期）

#### 4.1 环境边框 ★ 新增

| 项目 | 详情 |
|------|------|
| **来源** | Dragonflight3 `mods/general/ambient.lua` (~280 行) |
| **新增功能** | 屏幕边缘渐变条纹：正常黑色/战斗红色/休息青色，4边独立控制，自动模式切换 |
| **移植难度** | 低 (~200 行修改) |
| **用户价值** | 中 — 沉浸感显著提升 |

#### 4.2 全局暗化主题 ★ 新增

| 项目 | 详情 |
|------|------|
| **来源** | Dragonflight3 `mods/general/darkui.lua` (~220 行) |
| **新增功能** | 递归暗化所有暴雪 UI 纹理，白名单保护 DF 元素，可调强度和色调 |
| **当前状态** | fix 逐模块实现深色模式（chatDarkMode/mapDarkMode 等），不统一 |
| **移植难度** | 低 (~150 行修改) |
| **用户价值** | 中 — 比逐模块深色模式更彻底 |

#### 4.3 姓名板系统

| 项目 | 详情 |
|------|------|
| **来源** | Dragonflight3 `mods/nameplates/` (nameplates.lua 28K + tools 33K) |
| **功能** | 生命条美化 / 职业着色 / Debuff 显示 / 距离指示 / 目标高亮 |
| **移植难度** | 高 (2000+ 行修改) |
| **用户价值** | 极高 — PvP 社区强需求 |

**建议最小可行方案：**
1. 第一步：生命条美化 + 职业着色 (30% 功能)
2. 第二步：距离 + Debuff 显示 (40%)
3. 第三步：焦点火力等高级功能 (20%)

#### 4.4 面板美化（分阶段）

| 项目 | 详情 |
|------|------|
| **来源** | Dragonflight3 `mods/panels/` (24 文件, 15K+ 行) |
| **移植难度** | 每个面板 100-300 行修改 |

**建议顺序（按使用频率）：**
1. `bank.lua` (88 行) — 最简单，银行面板美化
2. `spellbook.lua` (534 行) — 法术书标签重排 + 搜索框
3. `talents.lua` (535 行) — 天赋标签美化 + 点数显示
4. `turtlepanels.lua` (240 行) — Turtle WoW 专属（外观/成就/伙伴）★ 新增
5. 其余面板按需添加

#### 4.5 停靠信息栏 ★ 新增

| 项目 | 详情 |
|------|------|
| **来源** | Dragonflight3 `mods/general/dock.lua` (~880 行) |
| **新增功能** | 屏幕边缘信息栏：6个小部件位置（FPS/经验/金币/区域/好友/公会/耐久/弹药/背包/战斗状态），3种发光模式 |
| **移植难度** | 中-高 (~600 行修改) |
| **用户价值** | 中 — 功能丰富但非必须 |

---

## 四、小而美的 QoL 功能（可穿插在任意 Phase 实施）★ 新增章节

这些功能完全独立、代码极少，可在任何阶段的间隙中快速完成：

| 功能 | 来源 | 改动量 | 说明 |
|------|------|--------|------|
| **自动下坐骑/姿态舞蹈** | DF3 `tweaks.lua` | ~80行 | 施法自动下坐骑、战士自动切姿态 |
| **悬停绑定** | DF3 `hoverbind.lua` | ~100行 | 鼠标悬停按钮时按键绑定 |
| **任务追踪增强** | DF3 `questtracker.lua` | ~150行 | 任务等级颜色+进度百分比 |

---

## 五、不建议移植的功能

| 功能 | 来源 | 行数 | 不移植原因 |
|------|------|------|-----------|
| Polyfill (SetSize) | DF3 | 29 | fix 的 `tools.lua` 已有等效实现 |
| Raid 框架 | DF3 | 1,721 | 过于复杂，fix 已有 `mini.lua` 小队框架满足 5 人本 |
| Intellisense | DF3 | 730 | 对中文输入法兼容性存疑 |
| Whisper 代理 | DF3 | 637 | 价值/复杂度比低 |
| BuffWatch 团队监视 | DF3 | 18,500 | 仅 40 人团本有用 |
| 框架检查器 | DF3 | 250 | 开发工具，对玩家无直接价值 |
| 同步系统 | DF3 | 400 | 需要服务器端支持 |
| 斜杠命令扫描 | DF3 | 200 | 调试工具 |

---

## 六、同步改进项（非移植，fix 自身优化）

| 优先级 | 位置 | 问题 | 建议 |
|--------|------|------|------|
| P1 | `core/error.lua` | 仅节流 2 次后完全抑制所有错误 | 实现分层报告 (WARNING/ERROR/CRITICAL) |
| P1 | `modules/cast/cast.lua` | Channel 施法缺少中断动画和 tick 指示 | 添加中断红色闪烁 + tick 动画 |
| P2 | `modules/unit/player.lua` | 缺少战斗状态指示 | 添加 PLAYER_REGEN_DISABLED 事件处理 |
| P2 | `modules/unit/target.lua` | 缺少威胁指示、断线检测 | 添加 UNIT_CONNECTION 事件 |
| P3 | 多个模块文件 | 字体路径映射重复 5 次 | 提取到 `core/tools.lua` 统一管理 |

---

## 七、优先级总览

```
紧急程度 ──→
高  ┌──────────────────────────────────────────────────────┐
    │  P0: Buff/Debuff 系统 (Reloaded 直接复制)             │
    │      + 3 个库 + 减益数据库 + auras.lua                │
价  │  P0: 修复 3 个已知 BUG                                 │
值  ├──────────────────────────────────────────────────────┤
    │  P1: ★冷却时间数字 (DF3, 低难度)                      │
    │  P1: ★职业配色方案 (DF3, 低难度)                      │
    │  P1: ★物品比较 (DF3, 极低难度)                        │
    │  P1: 聊天增强 (DF3, 低难度)                           │
    │  P1: Tooltip 增强 (DF3, 低-中难度)                    │
    │  P1: 配置迁移系统 (DF3, 极低难度)                     │
    │  P1: GUID 库 + ★自定义事件库 (DF3, 极低难度)         │
    ├──────────────────────────────────────────────────────┤
    │  P2: ★挥击计时器 (SuperWoW)                           │
    │  P2: ★CC控制监视 / ★距离显示器 (UnitXP)              │
    │  P2: HealComm / libhealth / libcast                   │
    │  P2: ★连击点 / ★自动截图 / ★卖出价值                 │
    │  P2: 编辑模式网格                                      │
    ├──────────────────────────────────────────────────────┤
    │  P3: ★环境边框 / ★全局暗化                            │
    │  P3: 姓名板系统 (高难度, 分步实施)                     │
低  │  P3: 面板美化 (按使用频率分批) / ★停靠信息栏          │
    └──────────────────────────────────────────────────────┘

★ = 本次新增功能
```

---

## 八、验证方式

每个 Phase 完成后：
1. 在 Turtle WoW 客户端加载插件，确认无 Lua 错误
2. 检查 `/dfrl` 命令是否正常
3. 逐模块验证功能：
   - Phase 1: 目标框架显示 debuff 图标和计时器
   - Phase 2: 动作按钮显示CD秒数、聊天框显示时间戳和 URL、Tooltip 显示目标的目标、Shift悬停对比装备
   - Phase 3: 挥击计时条显示、被控时屏幕提示、距离数字显示、团队框架显示治疗预测条
   - Phase 4: 屏幕边缘渐变、姓名板显示职业颜色、面板DF风格皮肤
4. 性能测试：主城 40 人场景下帧率不低于 30 FPS
