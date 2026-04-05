# Profile Export/Import — 经验与教训

## 问题背景

导出导入配置字符串时，模块设置（颜色、缩放、字体等）正常同步，但框架位置（`_FramePos`）始终不生效。

## 根因：setfenv 影子变量

### 机制

所有模块通过 `setfenv(func, DFUI.env)` 运行在自定义环境中（`core.lua:117`）：

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

### 导出包含的数据

- 28 个注册模块的所有设置项（300+ 键值对）
- `_FramePos`：仅包含用户手动拖拽过的框架位置（Ctrl+Shift+Alt 模式下拖拽）
- `Generic`/`actionbars` 等动态模块

### 导出不包含的数据

- `DFUI_CUR_PROFILE`（角色-档案绑定，角色特定）
- `DFUI_DB_SETUP`（数据库版本，导入时由代码设置）
- 从未拖拽过的框架位置（使用模块默认位置的框架不在 `_FramePos` 中）

## 排查问题的经验

### 1. 先确认环境一致性再设计方案

错误做法：假设分辨率/UI缩放不同，直接添加相对坐标转换。
正确做法：先读 Config.wtf 确认实际环境，发现所有账号共享同一配置后，排除此假设。

### 2. 用实际数据验证而非纯代码推理

导出字符串是最直接的证据。对比导入前后的导出字符串可以立即判断数据是否被正确写入。

### 3. setfenv 是 WoW 1.12 Lua 的常见陷阱

在自定义环境中，对全局变量的裸赋值（`VAR = xxx`）会创建影子变量。读取看似正常（因为 `__index` 回退），但写入的数据对外部代码不可见。
