# Aura (Buff/Debuff) 计时器设计原则

## 一、计时精度分层

不同单位类型使用不同的计时策略，核心原则是：**只在时间点准确时才显示计时器**。

### LookupDuration 回退规则

LookupDuration（名称查表 + start=GetTime()）假设 buff 是"刚刚施放"的，对于预存在的 buff 会导致计时器偏大。

| 单位 | LookupDuration 回退 | 原因 |
|------|---------------------|------|
| 玩家 | 不需要 | 有 GetPlayerBuffTimeLeft API |
| 目标 | 不允许 | 预存在 buff 无法知道真实施法时间，start=GetTime() 会偏大 |
| 宠物 | 允许 | buff 来源明确（玩家施放），start=GetTime() 基本准确 |
| 队友 | 不允许 | 同目标，预存在 buff 时间不可知 |

### 各单位计时来源优先级（UpdateBuffs/UpdateDebuffs 显示链）

- **玩家自身**：GetPlayerBuffTimeLeft（texture-matched index）→ GUID 追踪
- **宠物**：GUID 追踪 → LookupDuration 回退（允许，宠物 buff 来源明确）
- **目标/队友**：仅 GUID 追踪（Nampower/UNIT_CASTEVENT），显示链中不直接调用 LookupDuration
- **Debuff 补充**：libdebuff 参与 player/pet 的 debuff 回退（`libdebuff:UnitDebuff`）

### ⚠️ SnapshotAndDetectNewAuras 的间接路径

`SnapshotAndDetectNewAuras` 在检测到新 aura 时，会对**所有单位**（含 target/party）使用 LookupDuration 创建 auraDurations 条目（`start=GetTime()`）。这些条目随后可被 UpdateBuffs/UpdateDebuffs 中的 GUID 追踪路径读取。

这意味着切换目标时，预存在 buff 可能通过此间接路径获得不准确的计时器（start=GetTime() 偏大）。目前这是一个已知的精度折中：提供近似计时器优于完全不显示。

## 二、计时器显示精度

根据图标大小区分两种显示模式（`FormatTime` 的 `compact` 参数控制）：

### Buff Bar（屏幕右侧大图标 25px）— 时钟格式（FormatTime 不传 compact）

| 剩余时间 | 格式 | 示例 |
|----------|------|------|
| >= 1天 | `Xd`（仅天数） | `1d` |
| >= 1小时 | `HH:MM`（时:分，`%02d:%02d`） | `02:30` |
| >= 1分钟 | `MM:SS`（分:秒，`%02d:%02d`） | `05:42` |
| < 1分钟 | `X`（纯数字，floor） | `42` |

### 框体 Aura（玩家/目标/宠物/小队小图标 20px）— 紧凑显示（FormatTime compact=true）

| 剩余时间 | 格式 | 示例 |
|----------|------|------|
| >= 1天 | `Xd` | `1d` |
| >= 1小时 | `Xh` | `2h` |
| >= 1分钟 | `Xm` | `5m` |
| < 1分钟 | `X`（纯数字） | `42` |

### 设计理由

- Buff Bar 图标大，时钟格式（HH:MM / MM:SS）能精确看到分秒剩余
- 框体图标只有 20px，时钟文字过长放不下，单位制紧凑显示（ceil 到上一级单位）更合适

### 样式

FormatTime 函数支持两种颜色样式：
- **Gold**：全金色文字
- **White + Red**：数字白色，后缀字母红色，秒级倒计时不带后缀

## 三、永久光环

- 持续时间表中 duration = 0 的光环绝不显示计时器
- 剩余时间 >= 24 小时（86400 秒）的 buff 视为永久光环
- 包括：圣骑士光环、猎人守护、术士灵魂链接等

---

> 实现细节（事件链、计时来源级联、Buff Bar 与框体光环代码结构）详见 [auras-implementation.md](auras-implementation.md)。
