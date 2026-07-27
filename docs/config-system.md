# 配置系统

> 优先级 P1。本文档描述 DFUI 配置的整体架构：默认值注册、模块加载、SavedVariables 落盘、档案管理与导入导出。
> 导入导出的字符串格式与 setfenv 陷阱细节见 [profile-export-import-lessons.md](profile-export-import-lessons.md)；`_FramePos` 框架位置的存储设计见 [frame-position-export-design.md](frame-position-export-design.md)。

## 概览

DFUI 的配置分三层：

1. **代码默认值** `DFUI.defaults` —— 各模块在加载时通过 `NewDefaults` 注册（`{key = {default, type, ...}}`）。这是配置项的**唯一权威定义**：增删配置项只改这里。
2. **运行期工作表** `DFUI.tempDB` —— 当前生效的扁平配置（`tempDB[mod][key] = value`）。模块代码全程读它，不直接读磁盘表。
3. **磁盘 SavedVariables** —— 持久化的多档案数据（`DFUI_PROFILES` 等）。登录时灌进 `tempDB`，登出时由 `tempDB` 回写。

数据流：`磁盘档案 → InitTempDB → tempDB →（模块运行/用户改设置）→ SaveTempDB → 磁盘档案`。

## 关键文件

| 文件 | 职责 |
|------|------|
| `core/core.lua` | 配置系统全部核心：默认值/模块注册、tempDB 初始化与读写、档案 CRUD、同步、序列化/反序列化 |
| `data/tables.lua` | 手写的深/浅模式快照表 `DFUI.profiles.darkMode` / `.lightMode`（**与 defaults 是独立的第二数据源**） |
| `core/first.lua` | 首次登录欢迎页 + 深/浅模式切换 `TempDBForSwitching`（套用 tables.lua 快照） |
| `modules/gui/prof.lua` | 档案管理 GUI（同账号切换/复制/删除/新建/重置 + 导入导出弹窗），`NewMod("Gui-prof", 4)` |
| `modules/track/track.lua` | 写 `DFUI_DB_SETUP.lastVersionCheck`（版本检查时间，非档案数据） |
| `Dragonflight-Fix.toc` | 声明 SavedVariables，决定文件加载顺序 |

> ⚠️ 仓库内存在 `core/serialize.lua`，但**未在 .toc 中装载**（.toc 只列 core.lua/error.lua/tools.lua/statusbar.lua/compat.lua/first.lua）。当前生效的序列化逻辑是 `core.lua` 内的 `do...end` 块，serialize.lua 是历史遗留文件。

## SavedVariables 结构

`.toc` 声明（`Dragonflight-Fix.toc:8,10`）：

```
## SavedVariables: DFUI_PROFILES, DFUI_DB_SETUP, DFUI_BUGS, DFUI_HealthDB, DFUI_TrainerSpells, DFUI_ShieldDB, DFUI_PredictDB
## SavedVariablesPerCharacter: DFUI_CUR_PROFILE, DFUI_FRAMEPOS
```

其中四张属于档案系统，在 `core.lua:5-8` 初始化为空表：

| 变量 | 作用域 | 结构 | 写入处 |
|------|--------|------|--------|
| `DFUI_PROFILES` | 账号共享 | `[档案名] = { [模块名] = {key=value,...}, _FramePos = {帧名={x,y}} }` | `SaveTempDB` / 档案 CRUD |
| `DFUI_DB_SETUP` | 账号共享 | `{ lastVersionCheck = {version, date} }` —— 仅运行期状态，非档案 | `track.lua:37,101` |
| `DFUI_CUR_PROFILE` | 角色特定 | `[角色名] = 档案名`；另有 `[角色名.."_firstRun"] = true` 标记首登已过 | `InitTempDB` / `SwitchProfile` / `first.lua` |
| `DFUI_FRAMEPOS` | 角色特定 | `[帧名] = {x, y}`（绝对像素坐标） | `frames.lua` 拖拽保存 / `SaveTempDB` 同步 |

其余五个声明在 .toc 但不属于档案系统，都是运行期采集的数据缓存或日志，**不进导出串**（这是设计边界，非缺陷）：

| 变量 | 来源 | 内容 |
|------|------|------|
| `DFUI_BUGS` | `core/error.lua` | `entries` = 最多 50 条错误记录。注：原本还存 `prefs`，已迁进档案（见下节 tab16） |
| `DFUI_HealthDB` | `libs/libhealth.lua` | 怪物血量估算，schema v2 |
| `DFUI_TrainerSpells` | `modules/panels/trainerdata.lua` | 训练师扫描到的法术，按职业分组，供法术书「未学技能」页用 |
| `DFUI_ShieldDB` | `libs/libabsorb.lua` | 护盾吸收量实测校准，按 realm/角色 |
| `DFUI_PredictDB` | `libs/libpredict.lua` | 治疗量预读校准，按 realm/角色 |

另有几个**寄生在 `DFUI_CUR_PROFILE`** 命名空间里的角色级数据（与「角色名→档案名」映射共用一张表），同样不进导出串：`[角色名.."_firstRun"]`（`first.lua:119,133`）、`TalentPlans` / `TalentFrameSmall`（`ui/talents.lua:74,451`）、`TexFixAutoHeal`（`dftex.lua:409`）、`TradeSkillFavorites`（`panels/tradeskill.lua:292`）。

`_FramePos` 在档案内是**嵌入子表**：`SaveTempDB`（`core.lua:280-285`）把运行期 `DFUI_FRAMEPOS` 拷进 `DFUI_PROFILES[cur]["_FramePos"]`；各档案恢复路径（`InitTempDB`/`LoadProfile`/`CopyProfile`）再拆回 `DFUI_FRAMEPOS`。当前实现存的是绝对坐标（相对坐标方案见 frame-position-export-design.md，标注为未实现）。

旧存档迁移：`core.lua:651-661` 在 `ADDON_LOADED` 时一次性把旧前缀 `DFF_*`（次新）或 `DFRL_*`（最旧）迁进 `DFUI_*`，仅当目标空且源非空时迁移，迁完置 nil。

## 核心实现（函数名 + 文件:行）

### 注册

- `DFUI:NewDefaults(mod, defaults)` —— `core.lua:86`。把 `{key={default,...}}` 并入 `DFUI.defaults[mod]`。`default` 取 `value[1]`。
- `DFUI:NewMod(name, prio, func)` —— `core.lua:96`。注册模块 `{func, priority}`；重名直接返回（先注册者胜）。
- `DFUI:NewCallbacks(mod, callbacks)` —— `core.lua:366`。注册 `mod_key_changed` 回调，注册即用当前值触发一次。

### 加载（登录）

入口在 `core.lua:641` 的 `ADDON_LOADED`（`dragonflight-fix`，`boot` 标志防重入）：依次 `InitTempDB()` → `RunMods()`。

- `DFUI:InitTempDB()` —— `core.lua:192`。
  1. 先调 `SyncProfiles()` 同步所有档案结构，有变更则在聊天框报「配置已同步」。
  2. 角色无绑定档案时默认 `"Default"`（`core.lua:206-208`）；档案不存在则建空表。
  3. 把当前档案逐键拷进 `tempDB`；`_FramePos` 单独还原到 `DFUI_FRAMEPOS`（`core.lua:218-231`）。
  4. **兜底补默认值**：遍历 `DFUI.defaults`，对 `tempDB[mod][key] == nil` 的项填 `val[1]`（`core.lua:234-241`）。这保证正常登录路径下 tempDB 不会缺 key。
- `DFUI:RunMods()` —— `core.lua:101`。把所有模块按 `priority` **升序**排序（`core.lua:107`，`a.priority < b.priority`）后逐个 `setfenv` + `pcall` 执行；**仅当 `tempDB[name].enabled == true` 才运行**（`core.lua:112-113`）。出错走 `geterrorhandler()`，并记录耗时/内存到 `DFUI.performance`。

### NewMod 优先级语义

`priority` 数字越小越先跑（升序）。实测分布：

- **1** —— 绝大多数功能模块（Player/Target/Bars/Cast/Map/Talents/Loot/Tooltip… 见各模块 `NewMod` 第二参）。
- **2** —— `Gui-base`（GUI 主框架，必须先于其它 GUI 子页）。
- **3** —— `Gui-home` / `Gui-elem` / `Gui-shag` / `Gui-mods` / `Gui-superwow`。
- **4** —— `Gui-prof` / `GUI-Dragonflight`(homeb)。
- **5** —— `Gui-info` / `Gui-bugs`。

设计意图：功能模块（prio 1）先注册各自的 defaults/元素，GUI 面板（prio 2~5）后建并消费它们；GUI 内部再按 base→子页→依赖子页分层。注意优先级只决定 `RunMods` 内的执行序，文件本身的解析序仍由 .toc 决定（defaults 注册发生在文件解析阶段，早于 RunMods）。

### 读写 tempDB

- `SetTempDB(mod, key, value)` —— `core.lua:244`。写值并触发 `mod_key_changed` 回调。
- `SetTempDBNoCallback(mod, key, value)` —— `core.lua:253`。写值不触发回调。
- `GetTempValue(name, key)` / `GetTempDB(mod, key)` —— `core.lua:260` / `:268`。读值。

### 落盘（登出）

- `DFUI:SaveTempDB()` —— `core.lua:273`，由 `PLAYER_LOGOUT` 触发（`core.lua:673-674`）。把整个 `tempDB` 赋给 `DFUI_PROFILES[cur]`，并把 `DFUI_FRAMEPOS` 嵌进该档案的 `_FramePos`。

### 档案管理（profile）

| 函数 | 文件:行 | 行为 |
|------|---------|------|
| `CreateProfile(name)` | `core.lua:298` | 新建档案，用 `defaults` 全量填默认值 |
| `SwitchProfile(name)` | `core.lua:308` | 先把 `tempDB` 存回旧档案 → 改 `DFUI_CUR_PROFILE[char]` → `LoadProfile` → `RestoreFramePositions` |
| `CopyProfile(from, tbl)` | `core.lua:320` | 用 `tbl`（优先）或 `DFUI_PROFILES[from]` 整表覆盖 `tempDB` |
| `LoadProfile(name)` | `core.lua:343` | 用指定档案重建 `tempDB`，`_FramePos` 还原到 `DFUI_FRAMEPOS` |
| `DeleteProfile(name)` | `core.lua:361` | 置 `DFUI_PROFILES[name] = nil` |
| `ResetDB()` | `core.lua:289` | 清空 tempDB 与三张档案表后 `ReloadUI` |

GUI 入口 `modules/gui/prof.lua`（`Gui-prof` 面板）：

- 左区「同账号快速切换」—— `BuildProfileList`（`prof.lua:79`）渲染档案列表，每个非 Default 档案带「切换/复制/删除」按钮（操作后均 `SaveTempDB` + `ReloadUI`）。「新建档案」上限 10 个（`prof.lua:172`），新建后 `CreateProfile`+`SwitchProfile` 并标记 `Generic.firstRun`。「重置为默认」走 `CopyProfile(nil, Default快照)`。
- Default 档案的快照在 `prof.lua:19-28` 用 `DFUI.defaults` 现场生成（`sanitized["Default"][mod][key] = value[1]`），不依赖磁盘。

### 档案结构同步（无版本号机制）

- `DFUI:SyncProfiles()` —— `core.lua:135`。每次登录由 `InitTempDB` 调用，**幂等**，对**每个**档案做三件事：
  1. 合并新增模块/新增 key（缺失则填 `default`）；类型不匹配则用 default 修正（`core.lua:142-158`）。
  2. 清理 `defaults` 里已不存在的废弃模块（保留 `_FramePos`）（`core.lua:160-170`）。
  3. 清理已删除的废弃 key（`core.lua:172-186`）。

  返回 `added, removed, fixed` 计数；非零时聊天框提示。**这套机制取代了手动改版本号**：增删配置项只改 `NewDefaults`，登录时所有档案自动对齐。`DFUI.DBversion`（`core.lua:23`，当前 `"2.0"`）是发版常量，与同步无关、不影响档案。

### 序列化 / 导入导出

序列化逻辑在 `core.lua:405-641` 的一个 `do...end` 块内（局部辅助函数 + 两个公开方法）：

- `DFUI:SerializeProfile(profileName)` —— `core.lua:554`。把档案编码为 `DFUI1#<校验和>~模块:键=值,...` 字符串；档案不存在返回 `nil`。
- `DFUI:DeserializeProfile(str)` —— `core.lua:583`。校验 `DFUI1` 头与校验和（body 字节和 `math.mod(sum,65536)`），失败返回 `nil, errMsg`；兼容旧 `|` 分隔格式。

UI 侧 `prof.lua` 右区「配置共享」：

- 导出 `ShowExportDialog`（`prof.lua:499`）—— 先抓 ShaguTweaks 快照、`SaveTempDB` 落盘当前档案，再 `SerializeProfile`，结果填进只读弹窗供 Ctrl+C 复制。
- 导入弹窗「确认导入」（`prof.lua:447`）—— `DeserializeProfile` → 清空并重建 `tempDB`（`_FramePos` 经 `_G.DFUI_FRAMEPOS`）→ **回填默认值** → 回写 ShaguTweaks 开关 → `ReloadUI`。

字段编码与 setfenv 影子变量陷阱见 [profile-export-import-lessons.md](profile-export-import-lessons.md)。

## 配置界面（ESC 面板）与导出的对应关系

`SerializeProfile` 全量遍历档案、无白名单，所以**判断一个选项能不能共享，只需看它写到哪**：写进 `tempDB` 就一定进串。GUI 主框架 17 个 tab（`gui/base.lua:72-91`）的写入目标：

| tab | 页面 | 控件写入目标 | 可导出 |
|-----|------|--------------|--------|
| 1 首页 / 2 信息 | `gui/home.lua` `homeb.lua` `info.lua` | 无配置控件（`GUI-Dragonflight` 的 6 项渲染在 tab11） | — |
| 3 档案 | `gui/prof.lua` | 导入导出页本体 | — |
| 4 模块 | `gui/mods.lua:160` | `SetTempDBNoCallback(模块名, "enabled")` | ✅ |
| 5 ShaguTweaks | `gui/shag.lua` → `gui/tools.lua:467,473` | `ShaguTweaks_config[key]`（外部插件 SV） | ⚠️ 见下 |
| 6 SuperWoW | `gui/superwow.lua`（11 处） | `SetTempDB("SuperWoW", …)`，CVar 由回调重放 | ✅ |
| 7–15 动作条/背包/施法条/聊天/界面/微型菜单/小地图/单位框架/经验声望 | `gui/elem.lua` + `gui/tools.lua` 四个工厂（`CreateCheckbox:439` `CreateSlider:534` `CreateColour:672` `CreateDropDown:745`） | `SetTempDB(模块, key)` | ✅ |
| 16 诊断 | `gui/bugs.lua` | `SetTempDB("Errors", "bugOnlyDFUI"/"bugAutoToast")` | ✅ |
| 17 辅助功能 | `gui/assist.lua:50` | `SetTempDB("Assist", key)` | ✅ |

**tab16 诊断页**：两个复选框原本存在账号级 `DFUI_BUGS.prefs`，带不走。现改存档案 `Errors.bugAutoToast` / `Errors.bugOnlyDFUI`（`ui/errorHandler.lua`），`DFUI.errors.prefs` 降级为内存镜像，`error.lua` 的 `showToast` 与 `bugs.lua:41` 的过滤读取点不变。迁移与镜像刷新由 `DFUI.errors.SyncPrefs()`（`core/error.lua`）完成，**在 `Errors` 模块（prio 1）的 NewMod 里调用** —— 必须早于 `Gui-bugs`（prio 5）建复选框，否则面板读到的是迁移前的值；`restoreFromSV` 与 `PLAYER_ENTERING_WORLD` 各留一次幂等兜底。

**tab5 ShaguTweaks**：设置真值归 ShaguTweaks 自己的 `ShaguTweaks_config`，DFUI 代管一份快照 `Gui-shag.shaguSnapshot`（`{[英文模块名] = 0/1}`）：
- 导出时**现抓**（`prof.lua:CaptureShaguSnapshot`，在 `SaveTempDB` 之前）—— 现抓而非勾选时写，才能覆盖用户在 ShaguTweaks 自家面板做的改动
- 导入时在 `ReloadUI()` **之前**回写（`prof.lua:ApplyShaguSnapshot`）—— 那时 ShaguTweaks 已完整加载，一次重载即全部生效
- ShaguTweaks 未装：导出跳过（不动档案里已有快照）、导入跳过回写但快照留档，以后装了再导一次即生效
- 快照 key 是 `core/compat.lua:88-130` 硬编码的英文名，只含字母和空格，不触发 `SerializeValue` 的转义字符集

### ⭐ 加新模块的检查清单

配置项的权威定义只有 `NewDefaults` 一处，但**光注册 defaults 不等于用户能看到**。新增带控件元数据的模块，必须同步做：

1. `DFUI:NewDefaults(模块名, {...})` —— 每项 9 元组 `{默认值, 控件类型, 控件参数, 依赖key, 分类名, 排序, 描述, 副描述, status}`
2. **`gui/elem.lua` 的 `moduleMapping` 加一行 `[模块名] = {tab号, 同tab内排序}`** —— `elem.lua:177` 的门槛是 `if self.moduleMapping[moduleName]`，漏了则该模块**所有**选项在配置页不可见（值仍能正常导出生效，接收方却改不了）
3. 若落在 **tab7 或 tab14**，还要在 `elem.lua` 的 `moduleDisplayNames` 加显示名 —— 这两个 tab 会拼「模块名 - 分类名」标题（`elem.lua:420-426`），不加则退化为纯分类名，与同 tab 其他模块的同名分类（如"外观"）混淆
4. **`categoryIndex`（第 6 位）必须全模块连续递增，不能每个分类各自从 1 开始** —— `elem.lua:216-221` 取「该分类下首个被 `pairs` 遍历到的元素」的 `categoryIndex` 作为分类排序值，各分类都从 1 开始会让分类间顺序随 `pairs` 随机

> 2026-07-27 修复的 `Focus` / `Loot` / `ComboPoints` 共 15 个选项不可见，根因就是第 2 条；`Loot` 同时踩了第 4 条。

## 已知坑与限制

1. **双数据源失同步（tables.lua vs defaults）**：`data/tables.lua` 的 `darkMode`/`lightMode`（即 `DFUI.profiles`）是**手写快照**，与 `NewDefaults` 注册的模块集合**容易脱节**——曾漏整个模块（Auras 20+ slider、Cooldowns 等）。深/浅模式切换走 `first.lua:TempDBForSwitching`（`first.lua:28`）**整表替换** tempDB，若快照缺 key 则该 key 变 nil，建 slider 时 `SetValue(nil)` 报错。
   **现状**：`TempDBForSwitching` 在套用快照后追加了「遍历 `DFUI.defaults` 补全缺失 key」循环（`first.lua:46-53`），并用 `value ~= nil` 而非 `if value` 回填（防快照里的合法 `false` 被默认值覆盖）。**加新模块不必再手动同步两张表**，但 tables.lua 快照本身仍是手写、内容仍可能与 defaults 不一致（影响切换后的具体取值，但不再 nil 崩）。

2. **导入旧版本字符串同样靠 defaults 兜底**：导入串可能缺新版本的模块/key，故 `prof.lua:405-413` 导入后必须遍历 `defaults` 补 nil 项；判断用 `== nil`（同上，防 `false` 被覆盖）。这与登录的 `InitTempDB` 补 defaults（`core.lua:234-241`）是同一套兜底。

3. **setfenv 裸赋值陷阱**：模块跑在 `DFUI:GetEnv()` 自定义环境，对全局 SavedVariable 裸赋值（`DFUI_FRAMEPOS = {}`）只写进 env 影子，`_G` 原值不变。必须 `_G.DFUI_FRAMEPOS = {}`。详见 lessons 文档。

4. **`enabled == true` 门控**：`RunMods` 只跑 `tempDB[name].enabled == true` 的模块（`core.lua:112-113`）。若某模块 `NewDefaults` 没声明 `enabled`、或默认为 `false`/被用户关闭，则其 NewMod 函数体不执行。

5. **serialize.lua 未装载**：仓库有 `core/serialize.lua` 但不在 .toc，改它无效；生效代码在 core.lua 内联块。

6. **⚠️ 写进 tempDB 却没注册 defaults 的键，每次登录被清空（未修，2026-07-27 排查发现）**：`SyncProfiles` 第 2 步删掉不在 `DFUI.defaults` 里的整个模块段、第 3 步删掉模块内不在 defaults 的键。以下写入因此**只在当前会话有效，登出落盘、下次登录即被抹掉**；期间还会混进导出串：

   | 位置 | 键 | 后果 |
   |------|-----|------|
   | `panels/spellbook.lua:245,1215` | `SpellBook.knownSpells` / `newSpells` | 「新学法术高亮」基线每次登录重建，功能实际失效；且会把该角色几百条法术名塞进导出串，导入后污染接收方基线 |
   | `map/collect.lua:235` | `Collector.buttonOrder` | 小地图收集按钮排序每次登录丢失 |
   | `map/map.lua:478,483` | `pwb.visible` | 伪模块 `pwb` 整段被删，PizzaWorldBuffs 面板显隐不跨会话 |
   | `core/first.lua:190`、`gui/prof.lua:186` | `Generic.patchWarnVersion` / `Generic.firstRun` | 伪模块 `Generic` 整段被删 |
   | `frames/frames.lua:184` | `SetTempDBNoCallback("actionbars", "movable")` | **模块名笔误**，应为 `"Bars"`（`Bars.movable` 才是真键），该写入当前完全无效 |

   修法二选一：在对应模块的 `NewDefaults` 里补声明（哪怕 `{{}}`），或改存独立 SavedVariable。`knownSpells`/`newSpells` 属角色私有数据、体积大，宜走后者。

7. **运行期实测项（待游戏内实证）**：
   - `SyncProfiles` 对多档案、含废弃模块的实际增删/修正计数与聊天提示文案。
   - 深/浅模式切换后各模块取值是否符合预期（tables.lua 快照内容是否与当前 defaults 语义一致）。
   - 导入跨账号/跨分辨率字符串后 `_FramePos` 框架落位（当前存绝对坐标，跨分辨率可能偏移）。
