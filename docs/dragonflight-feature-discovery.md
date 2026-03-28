# Dragonflight 三仓库功能深度挖掘报告

> 生成日期：2026-03-25 | 基于完整代码库逐文件分析

本文档记录从 DragonflightReloaded 和 Dragonflight3 中发现的**所有可借鉴功能**，包括原优化指南已列出的和新发现的「隐藏宝石」。

---

## 一、Dragonflight3 完整模块清单

### 1.1 库文件 (libs/) — 9个

| 文件 | 行数 | 功能 | 已列入原计划 |
|------|------|------|:---:|
| `libguid.lua` | 244 | 伪GUID生成（pGUID-name-level-class-subzone-counter）、双向映射、120秒过期清理、优先原生UnitGUID | ✅ Phase 2.4 |
| `libhealth.lua` | 244 | 怪物HP估算（伤害值+HP%反推）、滚动平均10样本、8种战斗日志模式解析 | ✅ Phase 3.2 |
| `libhealcomm.lua` | 252 | 治疗预测（5职业法术数据库）、HealComm协议广播、队伍/团队同步 | ✅ Phase 3.1 |
| `libcast.lua` | 81 | 伪造UnitCastingInfo/UnitChannelInfo、追踪其他玩家施法、SuperWoW UNIT_CASTEVENT | ✅ Phase 3.3 |
| `libdebuff.lua` | 700+ | Hook点系统（12个回调）、100ms去重、SuperWoW AURA_CAST驱动、Tooltip扫描降级 | ❌ |
| `libevents.lua` | 120 | 自定义事件：PLAYER_AFTER_ENTERING_WORLD（延迟50ms）、SYNC_READY（延迟2s）、PLAYERMODEL_READY | ❌ **新发现** |
| `libspell.lua` | 120 | 法术信息查询：GetSpellMaxRank/GetSpellIndex/GetSpellInfo | 通过Reloaded版 |
| `libtipscan.lua` | 128 | Tooltip扫描器：30种Set方法、FindText/GetLine/GetText | 通过Reloaded版 |

### 1.2 通用功能模块 (mods/general/) — 20+个

| 文件 | 行数 | 功能 | 已列入原计划 | 移植难度 |
|------|------|------|:---:|---------|
| **cooldowns.lua** | ~200 | 动作按钮冷却数字显示，按时段着色（<10s红/10-59s黄/1-5m白/5m+灰），可选秒数 | ❌ **新发现** | 低 |
| **itemcompare.lua** | ~150 | Shift悬停装备时并排显示已穿戴物品Tooltip，自动映射16个装备槽 | ❌ **新发现** | 极低 |
| **colors.lua** | ~250 | 职业配色方案管理：Vanilla/TBC/Dragonflight三套预设，资源条着色（法力/怒气/焦点/能量） | ❌ **新发现** | 低 |
| **nocontrol.lua** | ~700 | CC控制监视：8种CC类型分类、职业特定法术列表、可用中断提示、脉冲发光效果 | ❌ **新发现** | 低-中 |
| **distance.lua** | ~400 | 实时距离显示器：目标肖像、侧边范围条（近战/远程模式）、按范围着色、依赖UnitXP | ❌ **新发现** | 中 |
| **dock.lua** | ~880 | 屏幕边缘停靠信息栏：6个小部件位置（FPS/经验/金币/区域/好友/公会/耐久/弹药/背包/战斗状态），3种发光模式 | ❌ **新发现** | 中-高 |
| **ambient.lua** | ~280 | 环境边框：正常黑色/战斗红色/休息青色，屏幕4边独立控制，渐变效果 | ❌ **新发现** | 低 |
| **darkui.lua** | ~220 | 全局暗化主题：递归暗化所有暴雪UI纹理，白名单保护，可调强度和色调 | ❌ **新发现** | 低 |
| **autoscreenshot.lua** | ~130 | 自动截图：升级/PvP等级变化/Boss击杀/声誉提升时触发，可配置延迟 | ❌ **新发现** | 极低 |
| **sellvalue.lua** | ~180 | 卖出价值：Tooltip显示NPC买卖价格，Shift显示详细信息，基于物品ID查询 | ❌ **新发现** | 低 |
| **hoverbind.lua** | ~150 | 悬停绑定：鼠标悬停按钮时按键绑定，支持修饰键（Alt/Ctrl/Shift），ESC移除 | ❌ **新发现** | 低 |
| **combopoints.lua** | ~100 | 连击点可视化：5个连击点图标，可配置大小和颜色 | ❌ **新发现** | 极低 |
| **questtracker.lua** | ~200 | 任务追踪器增强：显示任务等级和难度颜色，目标进度百分比，pfQuest集成 | ❌ **新发现** | 低 |
| **tweaks.lua** | ~130 | 游戏小技巧：姿态舞蹈（自动切换以施法）、自动下坐骑 | ❌ **新发现** | 极低 |
| **thirdparty.lua** | ~300 | 第三方兼容层：检测Questie/Atlas/AtlasLoot/CT_RaidAssist等，自动修复帧冲突 | ❌ **新发现** | 低 |
| editmode.lua | ~495 | 位置编辑模式网格（64x64）、框架拖拽调整 | ✅ Phase 3.4 | 低 |
| addons.lua | ~200 | 插件管理器 | fix已有 | - |
| error.lua | ~100 | 错误处理 | fix已有 | - |
| sync.lua | ~400 | 同步系统（需服务器端） | 不推荐 | - |
| slashscan.lua | ~200 | 斜杠命令扫描（调试工具） | 不推荐 | - |

### 1.3 单位框架模块 (mods/unitframes/)

| 文件 | 行数 | 功能 | 已列入原计划 | 移植难度 |
|------|------|------|:---:|---------|
| **swingtimer.lua** | ~300 | 挥击计时器：主手/副手/远程武器倒计时条，英勇一击队列检测，躲闪加速，SuperWoW事件驱动 | ❌ **新发现** | 低-中 |
| **focus.lua** | ~480 | 焦点目标框架 | ❌ | 中 |
| raid.lua | 1721 | 团队框架 | 不推荐 | 高 |
| raid-interact.lua | - | 团队交互 | 不推荐 | 高 |

### 1.4 面板皮肤 (mods/panels/) — 24个文件

| 文件 | 行数 | 功能 | 已列入原计划 |
|------|------|------|:---:|
| bank.lua | 88 | 银行面板 | ✅ Phase 4.2 |
| spellbook.lua | 534 | 法术书 | ✅ Phase 4.2 |
| talents.lua | 535 | 天赋树 | ✅ Phase 4.2 |
| **turtlepanels.lua** | ~240 | **Turtle WoW专属**：外观收藏/成就/伙伴/Transmog皮肤 | ❌ **新发现** |
| characterframe.lua | ~260 | 角色信息面板 | ❌ |
| worldmap.lua | ~330 | 世界地图 | ❌ |
| gamemenu.lua | ~360 | 游戏菜单 | ❌ |
| socialframe.lua | ~290 | 社交框架 | ❌ |
| questlog.lua | ~170 | 任务日志 | ❌ |
| lootframe.lua | ~180 | 战利品框架 | ❌ |
| merchantframe.lua | ~80 | 商人 | ❌ |
| questframe.lua | ~80 | 任务对话 | ❌ |
| gossipframe.lua | ~90 | NPC对话 | ❌ |
| classtrainerframe.lua | ~120 | 职业训练师 | ❌ |
| inspect.lua | ~60 | 检查界面 | ❌ |
| keybindingframe.lua | ~75 | 按键绑定 | ❌ |
| macroframe.lua | ~120 | 宏界面 | ❌ |
| dressup.lua | ~45 | 换装预览 | ❌ |
| mail.lua / mailopen.lua | ~110 | 邮件 | ❌ |
| trade.lua | ~80 | 交易 | ❌ |
| help.lua | ~45 | 帮助 | ❌ |

### 1.5 其他模块

| 文件 | 行数 | 功能 | 已列入原计划 |
|------|------|------|:---:|
| chat/chat.lua | 775 | 聊天增强（历史/URL/时间戳/职业颜色） | ✅ Phase 2.1 |
| chat/intellisense.lua | 730 | 智能输入自动完成 | 不推荐 |
| chat/whisperproxy.lua | 637 | 密聊代理 | 不推荐 |
| tooltip/tooltip.lua | 304 | Tooltip增强 | ✅ Phase 2.2 |
| nameplates/ | 1385+ | 姓名板系统 | ✅ Phase 4.1 |
| buffs/buffs.lua | ~220 | Buff显示 | 通过Reloaded auras.lua |
| buffs/buffwatch.lua | ~550 | Buff团队监视 | 不推荐 |
| minimap/collector.lua | ~220 | 小地图按钮收集器 | ❌ |
| xprep/xprep.lua | ~670 | 经验/声望条 | fix已有 |
| gui/performance.lua | ~490 | 性能监控面板（FPS最小/平均/最大、内存、GC） | ❌ **新发现** |
| trouble/frameinspect.lua | ~250 | 框架检查器（开发工具） | 不推荐 |

### 1.6 工具库 (tools/)

| 文件 | 大小 | 功能 | 借鉴价值 |
|------|------|------|---------|
| wow/ui-tools.lua | 72K | UI构建工具集（SlotButton/CreateTabs/CreateStatusBar等） | 高 — 面板美化的基础 |
| wow/animations.lua | - | 动画框架 | 中 |
| common/hooks.lua | - | Hook系统 | fix已有等效 |
| common/data.lua | - | 数据操作工具 | 低 |

---

## 二、DragonflightReloaded 完整模块清单

> Reloaded 与 fix 使用完全相同的 DFRL 框架，可直接复制。

### 2.1 核心差异（Reloaded有而fix没有的）

| 文件 | 行数 | 功能 | 已列入原计划 |
|------|------|------|:---:|
| **libs/libtipscan.lua** | 128 | Tooltip扫描器 | ✅ Phase 1.1 |
| **libs/libspell.lua** | 120 | 法术信息查询 | ✅ Phase 1.1 |
| **libs/libdebuff.lua** | 367 | Debuff追踪 | ✅ Phase 1.1 |
| **data/debuffs.lua** | 959 | 933条减益数据库 | ✅ Phase 1.1 |
| **modules/unit/auras.lua** | 1648 | Buff/Debuff完整UI系统 | ✅ Phase 1.1 |
| **data/tables.lua** | 20K | 完整预设配置表（深色/浅色模式） | ❌ **新发现** |
| **core/statusbar.lua** | 10K | 增强进度条系统（脉冲/切割/填充动画） | ❌ **新发现** |

### 2.2 模块功能对比（Reloaded vs fix）

两者模块基本一致，主要差异是Reloaded版本更新、功能更完整。以下是值得注意的差异：

| 模块 | Reloaded行数 | fix行数 | 差异说明 |
|------|-------------|---------|---------|
| bars.lua | 1700+ | 1500+ | Reloaded多了鹰身人装饰翻转选项 |
| cast.lua | 900+ | 729 | Reloaded可能有更好的channel处理 |
| chat.lua | 400+ | 307 | 基本一致 |
| map.lua | 1200+ | 994 | Reloaded有更多缩放选项 |
| micro.lua | 1000+ | 800+ | Reloaded有网络统计显示 |
| player.lua | 1200+ | 980 | Reloaded配置项更多 |
| target.lua | 800+ | 668 | Reloaded有更多着色选项 |
| mini.lua | 1300+ | 998 | Reloaded有更完整的队伍框架 |

---

## 三、功能分类汇总（按用户价值）

### 3.1 每个玩家都需要的基础功能

| 功能 | 来源 | 状态 |
|------|------|------|
| Buff/Debuff显示+计时器 | Reloaded auras.lua | 原计划Phase 1 |
| **冷却时间数字** | DF3 cooldowns.lua | **新发现，建议Phase 2** |
| **物品比较** | DF3 itemcompare.lua | **新发现，建议Phase 2** |
| 聊天增强（URL/时间戳） | DF3 chat.lua | 原计划Phase 2 |
| 配置版本迁移 | DF3 init.lua | 原计划Phase 2 |

### 3.2 PvP/战斗向玩家需要

| 功能 | 来源 | 状态 |
|------|------|------|
| **CC控制监视** | DF3 nocontrol.lua | **新发现，建议Phase 3** |
| **挥击计时器** | DF3 swingtimer.lua | **新发现，建议Phase 3（SuperWoW）** |
| **距离显示器** | DF3 distance.lua | **新发现，建议Phase 3（UnitXP）** |
| 姓名板系统 | DF3 nameplates/ | 原计划Phase 4 |
| **连击点可视化** | DF3 combopoints.lua | **新发现，盗贼/德鲁伊专用** |

### 3.3 视觉/沉浸感增强

| 功能 | 来源 | 状态 |
|------|------|------|
| **环境边框** | DF3 ambient.lua | **新发现** |
| **全局暗化主题** | DF3 darkui.lua | **新发现** |
| **职业配色统一管理** | DF3 colors.lua | **新发现，建议Phase 2** |
| 面板美化（银行/法术书等） | DF3 panels/ | 原计划Phase 4 |
| **Turtle专属面板皮肤** | DF3 turtlepanels.lua | **新发现** |

### 3.4 基础设施/库

| 功能 | 来源 | 状态 |
|------|------|------|
| GUID追踪库 | DF3 libguid.lua | 原计划Phase 2 |
| **自定义事件库** | DF3 libevents.lua | **新发现** |
| HealComm治疗预测 | DF3 libhealcomm.lua | 原计划Phase 3 |
| 怪物HP估算 | DF3 libhealth.lua | 原计划Phase 3 |
| 施法追踪 | DF3 libcast.lua | 原计划Phase 3 |

### 3.5 小而美的QoL功能

| 功能 | 来源 | 改动量 | 说明 |
|------|------|--------|------|
| **自动截图** | DF3 autoscreenshot.lua | ~130行 | 升级/Boss击杀自动截图 |
| **卖出价值** | DF3 sellvalue.lua | ~180行 | Tooltip显示NPC售价 |
| **游戏小技巧** | DF3 tweaks.lua | ~130行 | 姿态舞蹈、自动下坐骑 |
| **悬停绑定** | DF3 hoverbind.lua | ~150行 | 鼠标悬停按钮时绑键 |
| **任务追踪增强** | DF3 questtracker.lua | ~200行 | 任务等级颜色+进度百分比 |
| **性能监控面板** | DF3 gui/performance.lua | ~490行 | FPS/内存/GC统计 |

---

## 四、确认不移植的功能

| 功能 | 来源 | 行数 | 原因 |
|------|------|------|------|
| Polyfill (SetSize) | DF3 | 29 | fix的tools.lua已有等效实现 |
| Raid框架 | DF3 | 1,721 | 过于复杂，fix已有mini.lua满足5人本 |
| Intellisense | DF3 | 730 | 对中文输入法兼容性存疑 |
| Whisper代理 | DF3 | 637 | 价值/复杂度比低 |
| BuffWatch团队监视 | DF3 | 18,500 | 仅40人团本有用 |
| 框架检查器 | DF3 | 250 | 开发工具，对玩家无直接价值 |
| 同步系统 | DF3 | 400 | 需要服务器端支持 |
| 斜杠命令扫描 | DF3 | 200 | 调试工具 |

---

## 五、API 翻译速查（DF3 → DFRL）

```lua
-- 配置系统
DF.profile[mod][opt]           → DFRL:GetTempDB(mod, opt)
DF:NewDefaults(mod, defs)      → DFRL:NewDefaults(mod, defs)
DF:NewModule(mod, pri, evt, fn)→ DFRL:NewMod(mod, pri, fn)

-- Hook系统
DF.hooks.HookScript(f, s, fn)  → HookScript(f, s, fn)
DF.hooks.HookSecureFunc(n, fn) → DFRL.env.hooksecurefunc(n, fn)

-- UI工具
DF.common.KillFrame(f)         → f:Hide(); f:SetScript('OnUpdate', nil)
DF.ui.Font(parent, size, ...)  → parent:CreateFontString(nil, 'OVERLAY')
DF.ui.Frame(parent, ...)       → CreateFrame('Frame', nil, parent)

-- 本地化
DF.L('English text')           → "中文文字"

-- 媒体资源
media['tex:path']              → DFRL:GetInfoOrCons('tex')..'path'
media['font:name']             → DFRL:GetInfoOrCons('font')..'name.ttf'

-- 服务器检测
DF.others.server               → (GetRealmName() or ''):find('Turtle')
DF.others.isTurtle             → 同上

-- 其他
DF.others.superWoW             → (UnitGUID ~= nil) -- SuperWoW检测
DF.others.unitXP               → (UnitXP ~= nil) -- UnitXP检测
```

---

## 六、源文件绝对路径速查

### Dragonflight3 新发现文件
```
/home/ym/new_ilabel/turtle-wow/-Dragonflight3/mods/general/cooldowns.lua
/home/ym/new_ilabel/turtle-wow/-Dragonflight3/mods/general/itemcompare.lua
/home/ym/new_ilabel/turtle-wow/-Dragonflight3/mods/general/colors.lua
/home/ym/new_ilabel/turtle-wow/-Dragonflight3/mods/general/nocontrol.lua
/home/ym/new_ilabel/turtle-wow/-Dragonflight3/mods/general/distance.lua
/home/ym/new_ilabel/turtle-wow/-Dragonflight3/mods/general/dock.lua
/home/ym/new_ilabel/turtle-wow/-Dragonflight3/mods/general/ambient.lua
/home/ym/new_ilabel/turtle-wow/-Dragonflight3/mods/general/darkui.lua
/home/ym/new_ilabel/turtle-wow/-Dragonflight3/mods/general/autoscreenshot.lua
/home/ym/new_ilabel/turtle-wow/-Dragonflight3/mods/general/sellvalue.lua
/home/ym/new_ilabel/turtle-wow/-Dragonflight3/mods/general/hoverbind.lua
/home/ym/new_ilabel/turtle-wow/-Dragonflight3/mods/general/combopoints.lua
/home/ym/new_ilabel/turtle-wow/-Dragonflight3/mods/general/questtracker.lua
/home/ym/new_ilabel/turtle-wow/-Dragonflight3/mods/general/tweaks.lua
/home/ym/new_ilabel/turtle-wow/-Dragonflight3/mods/general/thirdparty.lua
/home/ym/new_ilabel/turtle-wow/-Dragonflight3/mods/unitframes/swingtimer.lua
/home/ym/new_ilabel/turtle-wow/-Dragonflight3/mods/panels/turtlepanels.lua
/home/ym/new_ilabel/turtle-wow/-Dragonflight3/libs/libevents.lua
/home/ym/new_ilabel/turtle-wow/-Dragonflight3/mods/gui/performance.lua
```

### 原计划已有文件
```
/home/ym/new_ilabel/turtle-wow/-DragonflightReloaded/libs/libtipscan.lua
/home/ym/new_ilabel/turtle-wow/-DragonflightReloaded/libs/libspell.lua
/home/ym/new_ilabel/turtle-wow/-DragonflightReloaded/libs/libdebuff.lua
/home/ym/new_ilabel/turtle-wow/-DragonflightReloaded/data/debuffs.lua
/home/ym/new_ilabel/turtle-wow/-DragonflightReloaded/modules/unit/auras.lua
/home/ym/new_ilabel/turtle-wow/-Dragonflight3/mods/chat/chat.lua
/home/ym/new_ilabel/turtle-wow/-Dragonflight3/mods/tooltip/tooltip.lua
/home/ym/new_ilabel/turtle-wow/-Dragonflight3/core/init.lua
/home/ym/new_ilabel/turtle-wow/-Dragonflight3/libs/libguid.lua
/home/ym/new_ilabel/turtle-wow/-Dragonflight3/libs/libhealcomm.lua
/home/ym/new_ilabel/turtle-wow/-Dragonflight3/libs/libhealth.lua
/home/ym/new_ilabel/turtle-wow/-Dragonflight3/libs/libcast.lua
```
