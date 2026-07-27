# Profile Export/Import — 经验与教训

## 问题背景

导出导入配置字符串时，模块设置（颜色、缩放、字体等）正常同步，但框架位置（`_FramePos`）始终不生效。

## 根因：setfenv 影子变量

### 机制

所有模块在 `RunMods` 中通过 `setfenv(func, self:GetEnv())` 运行在自定义环境中（`core.lua:117`，`GetEnv` 返回 `DFUI.env`）：

```lua
function DFUI:GetEnv()
    self.env._G = getfenv(0)
    self.env.T = self.tools
    return self.env
end
setmetatable(DFUI.env, {__index = getfenv(0)})
```

`DFUI.env` 的 metatable 只有 `__index`（读穿透到全局），没有 `__newindex`。因此：

- **读取**全局变量：正常，通过 `__index` 回退到 `_G`
- **赋值**全局变量：写入 `DFUI.env`，创建影子变量，`_G` 中的原变量不受影响

### 具体表现

prof.lua 导入代码中：

```lua
-- 这行写入 DFUI.env["DFUI_FRAMEPOS"]，NOT _G["DFUI_FRAMEPOS"]
DFUI_FRAMEPOS = {}
```

之后 `SaveTempDB`（运行在全局作用域的 core.lua 中）读取 `_G["DFUI_FRAMEPOS"]`，拿到的仍是导入前的旧数据。

### 修复

```lua
-- 显式写入全局环境
_G.DFUI_FRAMEPOS = {}
```

`_G` 在模块环境中可用（`GetEnv` 设置了 `self.env._G = getfenv(0)`）。

### 安全的写法 vs 危险的写法

在 setfenv 模块中：

| 写法 | 是否安全 | 原因 |
|------|---------|------|
| `DFUI.tempDB = {}` | ✅ 安全 | 读取 DFUI（穿透到全局），修改其字段 |
| `DFUI_DB_SETUP.version = x` | ✅ 安全 | 读取全局表，修改其字段 |
| `DFUI:SetTempDB(...)` | ✅ 安全 | 方法调用，操作全局对象 |
| `ReloadUI()` | ✅ 安全 | 函数调用，通过 __index 读取 |
| `DFUI_FRAMEPOS = {}` | ❌ 危险 | 裸变量赋值，写入模块 env 影子 |
| `_G.DFUI_FRAMEPOS = {}` | ✅ 安全 | 显式写入全局 |

**规则：在 setfenv 模块中，不要对全局 SavedVariable 做裸赋值。用 `_G.XXX = ...` 或通过 DFUI 方法操作。**

## 导出/导入 API

序列化/反序列化在 `core.lua` 的一个 `do ... end` 块内（局部函数 + 两个公开方法）：

| API | 签名 | 返回 | 位置 |
|-----|------|------|------|
| `DFUI:SerializeProfile(profileName)` | profileName 为档案名（字符串） | 成功返回字符串；档案不存在返回 `nil` | `core.lua:554` |
| `DFUI:DeserializeProfile(str)` | str 为导入字符串 | 成功返回 `profileData` 表；失败返回 `nil, errMsg` | `core.lua:583` |

辅助局部函数（块内，外部不可见）：`SerializeValue` / `DeserializeValue`（值编解码）、`Checksum`（`math.mod(sum, 65536)`）、`SplitTopLevel(str, sep)`（按分隔符切分但跳过引号内与 `{}` 内的分隔符）。

UI 侧调用链（`modules/gui/prof.lua`）：
- 导出：`ShowExportDialog`（`prof.lua:499`）先抓 ShaguTweaks 快照、`DFUI:SaveTempDB()` 落盘当前档案，再 `DFUI:SerializeProfile(curProf)`，把结果填进只读弹窗。
- 导入：弹窗"确认导入"按钮（`prof.lua:447`）→ `DFUI:DeserializeProfile(text)` → 重建 `DFUI.tempDB` + 回填默认值 → 回写 `ShaguTweaks_config` → `ReloadUI()`。

> `DeserializeValue` 解析嵌套 table 时**不跟踪引号**（只按 `{}` 深度和 `;` 切分），所以 table 类型的配置值里不能放含 `;` `{` `}` 的字符串。当前所有 table 值都安全：`colour` 是 3 元数字数组，`Gui-shag.shaguSnapshot` 的键是 `compat.lua` 硬编码的英文名（只含字母和空格）、值是 0/1。

## 导出/导入字符串格式

### 格式结构

```
DFUI1#<校验和>~模块A:键1=值1,键2=值2~模块B:键3=值3~_FramePos:帧名={x=数字;y=数字}
```

- `DFUI1` — 格式标识
- `#数字` — 校验和（body 字节和 mod 65536）
- `~` — 模块分隔符
- `:` — 模块名与键值对分隔符
- `,` — 键值对分隔符
- `=` — 键值分隔符

### 值编码

| 类型 | 编码 | 示例 |
|------|------|------|
| boolean | `T` / `F` | `enabled=T` |
| number | 最多4位小数 | `x=347.6358` |
| string | 引号+转义 | `"FRIZQT__.TTF"` |
| 数组 table | `{v1;v2;v3}` | `{1;0.82;0}` |
| 字典 table | `{k1=v1;k2=v2}` | `{x=100;y=200}` |

### _FramePos 数据流

```
运行时 DFUI_FRAMEPOS        绝对像素坐标 {x, y}
    ↓ SaveTempDB
DFUI_PROFILES[profile]      绝对像素坐标 {x, y}
    ↓ SerializeProfile
导出字符串                   _FramePos:PlayerFrame={x=6.9416;y=913.3431}
    ↓ DeserializeProfile
导入 profileData             {x=6.9416, y=913.3431}
    ↓ prof.lua 导入处理 (_G.DFUI_FRAMEPOS)
运行时 DFUI_FRAMEPOS        绝对像素坐标 {x, y}
    ↓ ReloadUI → PLAYER_LOGOUT → SaveTempDB
磁盘 SavedVariables          持久化
    ↓ InitTempDB
运行时 DFUI_FRAMEPOS        绝对像素坐标 {x, y}
    ↓ RestoreFramePositions (PLAYER_ENTERING_WORLD)
实际框架位置                  SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
```

### 导入时必须回填默认值（双数据源同步坑）

导入字符串可能来自**旧版本**导出，缺少新版本新增的模块/键。若直接 `DFUI.tempDB = profileData` 就重载，新模块在 tempDB 里是 nil，建控件时（如 slider）会 `SetValue(nil)` 报错——与切换深/浅模式套用 profile 表的失同步问题同源。

因此导入逻辑（`prof.lua:463-486`）分两步：

1. 用 `profileData` 重建 `DFUI.tempDB`（`_FramePos` 走 `_G.DFUI_FRAMEPOS`，其余模块逐键拷进 `tempDB[mod]`）。
2. 遍历 `DFUI.defaults`，对 `tempDB[mod][key] == nil` 的项用 `def[key][1]`（默认值）补齐。

> 关键：补齐判断必须用 `== nil` 而非 `if not`，否则导入字符串里合法的 `false` 会被默认值覆盖。这与 `core.lua:InitTempDB`（`core.lua:236-244`）登录时补 defaults 是同一套逻辑——两条进 tempDB 的路径都靠 `DFUI.defaults` 兜底，所以加新模块不必手动同步导出字符串。

导入还会在重建 tempDB 前先 `DFUI.tempDB = {}`（`prof.lua:463`），目的是覆盖而非合并，避免 `PLAYER_LOGOUT` 的 `SaveTempDB` 把旧残留写回档案。

### 导出包含的数据

- 当前档案 `DFUI_PROFILES[profileName]` 里所有模块的设置项（即全部经 `NewDefaults` 注册的模块；模块数随版本增长，不固定）
- `_FramePos`：仅包含用户手动拖拽过的框架位置（Ctrl+Shift+Alt 模式下拖拽）
- `Errors.bugAutoToast` / `Errors.bugOnlyDFUI`：诊断页（tab16）两个复选框，原存 `DFUI_BUGS.prefs`，已迁进档案
- `Gui-shag.shaguSnapshot`：ShaguTweaks 各模块开关的代管快照，导出时现抓、导入时在 `ReloadUI` 前回写 `ShaguTweaks_config`
- `Generic` 等动态模块（但这类未注册 defaults 的伪模块会被 `SyncProfiles` 在下次登录清掉，见 config-system.md 已知坑 6）

注：导出只序列化 `DFUI_PROFILES[profileName]` 中存在的内容。`SerializeProfile`（`core.lua:554`）按模块名排序遍历该档案，对每个 table 类型字段输出 `模块名:键=值,...`。**没有白名单**——判断一个选项能不能共享，只需看它有没有写进 `tempDB`。

### 导出不包含的数据

- `DFUI_CUR_PROFILE`（角色-档案绑定，角色特定），及寄生在它命名空间里的 `TalentPlans` / `TalentFrameSmall` / `TradeSkillFavorites` / `TexFixAutoHeal` / `[角色名.."_firstRun"]`
- `DFUI_DB_SETUP`（仅存 `lastVersionCheck` 等运行期状态，由 track.lua 写；不是档案数据，导入流程完全不碰它）
- `DFUI_BUGS.entries`（错误日志）、`DFUI_HealthDB` / `DFUI_TrainerSpells` / `DFUI_ShieldDB` / `DFUI_PredictDB`（运行期采集的数据缓存）
- 从未拖拽过的框架位置（使用模块默认位置的框架不在 `_FramePos` 中）

> 注：`DFUI.DBversion`（`core.lua:23`，当前 `"2.0"`）是代码常量，与 `DFUI_DB_SETUP` 无关，也不随导入/导出变化。

## 排查问题的经验

### 1. 先确认环境一致性再设计方案

错误做法：假设分辨率/UI缩放不同，直接添加相对坐标转换。
正确做法：先读 Config.wtf 确认实际环境，发现所有账号共享同一配置后，排除此假设。

### 2. 用实际数据验证而非纯代码推理

导出字符串是最直接的证据。对比导入前后的导出字符串可以立即判断数据是否被正确写入。

### 3. setfenv 是 WoW 1.12 Lua 的常见陷阱

在自定义环境中，对全局变量的裸赋值（`VAR = xxx`）会创建影子变量。读取看似正常（因为 `__index` 回退），但写入的数据对外部代码不可见。
