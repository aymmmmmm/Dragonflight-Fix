# 单位框体设计（P0）

DF 风格单位框体复刻：玩家 / 目标 / 宠物 / 目标的目标(ToT) / 小队 / PvP 图标。
核心是用自定义 `CreateStatusBar` 取代 vanilla 血条/蓝条，套 DF 框体纹理，再叠加脉冲(pulse)、切割(cutout)、战斗/休息发光等动画。

## 一、概览

| 模块 | 文件 | 接管的 vanilla 框体 |
|------|------|---------------------|
| Player | `modules/unit/player.lua` | PlayerFrame |
| Target | `modules/unit/target.lua` | TargetFrame |
| Mini | `modules/unit/mini.lua` | PetFrame / TargetofTargetFrame / PartyMemberFrame1-4 |
| PVPIcon | `modules/unit/pvp.lua` | Player/TargetPVPIcon |
| StatusBar 工厂 | `core/statusbar.lua` | `CreateStatusBar` |
| 共享工具 | `core/tools.lua` | `FormatNumber` / `GetUnitRealHealth` / `GetPowerColor` / `GetFontPath` |

每个模块走 `DFUI:NewDefaults("X", {...})` 声明配置 + `DFUI:NewMod("X", 1, function() ... end)` 注册逻辑，
回调表通过 `DFUI:NewCallbacks("X", callbacks)` 绑定到配置项。

## 二、关键文件

### 共享纹理路径
- 框体血条 fill：`media\tex\unitframes\healthDF2.tga`
- 玩家蓝条：`UI-HUD-UnitFrame-Player-PortraitOn-Bar-Mana-Status.tga`
- 目标/ToT/宠物/小队蓝条：`UI-HUD-UnitFrame-Target-PortraitOn-Bar-Mana-Status.blp`
- 玩家框体：`UI-TargetingFrameDF.blp`，目标框体：`UI-TargetingFrameDF1.blp`
- 精英/稀有边框：`UI-TargetingFrame-Elite/Rare/RareElite/Boss.blp`
- ToT/小队边框：`media\tex\unitframes\pet`

### 字体
配置项 `frameFont` 经 `GetFontPath(value)`（`core/tools.lua:188`）解析为路径，
fallback 为 `Fonts\FRIZQT__.TTF`。

## 三、核心实现

### 1. StatusBar 工厂（`core/statusbar.lua`）

`CreateStatusBar(parent, width, height, animConfig)` 返回一个含 `bg`(背景) + `fill`(填充) 两层纹理的 Frame，
通过 `SetTexCoord` 裁切 + `SetWidth` 拉伸表现百分比（**1.12 无 retail StatusBar 的 SetMinMaxValues 范式，这里自实现**）。

关键方法：
- `bar:Update()`（`statusbar.lua:78`）—— 按 `val_ / max` 计算 pct，`SetTexCoord(0, pct, 0, 1)` + `SetWidth(GetWidth()*pct)`。支持 `fillDirection`（默认 LEFT_TO_RIGHT，可 RIGHT_TO_LEFT）
- `bar:SetValue(val, instant)`（`statusbar.lua:97`）—— 值变化驱动动画；`val_` 是当前显示值（lerp 中间态），`val` 是目标值
- `bar:SetTextures(fillTex, bgTex)` / `SetFillColor` / `SetCutoutColor` / `SetPulseColor`
- `bar:SetPulseAnimation(on)` / `SetCutoutAnimation(on)` / `SetBarAnimation(on)`
- `bar:SuppressCutout(duration)`（`statusbar.lua:184`）—— 在 `cutoutSuppressed` 时间窗内屏蔽切割，避免切目标/变身时误触发

动画用三张弱表 `animations` / `pulses` / `cutouts`（`statusbar.lua:3-5`，`__mode="k"`）登记，
单一 `OnUpdate` 泵 `AnimateOnUpdate`（`statusbar.lua:312`）统一驱动；三表全空时 `SetScript('OnUpdate', nil)` 自停，`SetValue` 经 `EnsureAnimating()`（`statusbar.lua:325`）重新点火。

### 2. 脉冲 + 切割动画

两者都只在**掉血(伤害)时触发，回血不触发**：

- **脉冲(pulse)**：`SetValue` 中 `if self.enablePulse and val < oldVal then pulses[self] = GetTime()+PULSE_DURATION`（`statusbar.lua:148`）。
  `UpdatePulseAnimations`（`statusbar.lua:253`）按 `PULSE_DURATION=0.3` 在 baseColor↔pulseColor 间插值 `SetVertexColor`，先 fade-in(`PULSE_FADE_IN=0.1`)再 fade-out(指数曲线 `PULSE_CURVE=0.7`)，结束回 baseColor。
- **切割(cutout)**：`SetValue` 中 `if val < oldVal and not instant and self.enableCutout and currentTime > self.cutoutSuppressed`（`statusbar.lua:102`）。
  从 `cutoutPools`（`statusbar.lua:15`，每条 bar 一个纹理池，避免永久分配泄漏）取一张纹理覆盖在「失去的血量区段」，
  `UpdateCutoutAnimations`（`statusbar.lua:293`）在 `CUTOUT_DURATION=0.3` 内 alpha 渐隐，结束 `ReleaseCutoutTexture` 归还池。

配置入口（玩家为例）：`enablePulse`/`pulseColor`/`enableCutout`/`cutoutColor`（`player.lua:33-36`），
回调 `callbacks.enablePulse`→`SetPulseAnimation`、`callbacks.cutoutColor`→`SetCutoutColor`（`player.lua:536-570`）。

### 3. 生命/法力文字与 FormatNumber

- **玩家**（`player.lua` callbacks.textShow:401）：直接用 `UnitHealth/UnitHealthMax`，百分比 `math.floor(health/maxHealth*100)`，数值用原始整数拼接（**未走 FormatNumber**）。
- **目标**（`target.lua` Setup:UpdateTexts:213）：血量经 `GetUnitRealHealth('target')` 取 `cur, max, status`，
  数值用 `FormatNumber(health)`，按 `status` 分三态：
  - `real` → `"1.5k/5.0k" + "30%"`
  - `percent` → 只显示 `"30%"`（避免把百分比当绝对值假装）
  - `none` → 完全清空（如友善 NPC 不可知血量）
- **ToT**（`mini.lua` Setup:UpdateTargetOfTargetTexts:451）：同样按 `status` 分态，但数值用**原始整数拼接，未走 FormatNumber**；
  死亡/ghost/`none` 状态清空。
- **宠物 / 小队**：用 `UnitHealth` 原始整数拼接（`mini.lua:418-447` / `mini.lua:889-916`）。

`FormatNumber(num)`（`core/tools.lua:234`）：`>=1e6` 用 `%.1fM`、`>=1000` 用 `%.1fk`、否则 `tostring`。

`GetUnitRealHealth(unit)`（`core/tools.lua:738`）四步：① 自己/宠物/小队/团队 token 反映射到原生真值(`real`)（`ResolveToTrueUnit`，`tools.lua:719-736`，依次匹配 player/pet/party1-4/raid1-40）；② `rawMax==0`→`none`；③ `rawMax==100` 走 `DFUI.libhealth` 估算，估不到回 `percent`；④ 其他信任别的插件给的真值(`real`)。

各模块都有 `configCache`（如 `target.lua:38`）缓存 `noPercent`/`textMaxShow`/着色开关，节流读 DB（>1s 才刷新），减少每个 UNIT_HEALTH tick 的 `GetTempDB` 调用。

### 4. 反应与职业着色（血条 fill 颜色）

- **玩家**（`player.lua` callbacks.classColor:520）：`classColor` 开 → `DFUI:GetClassColor(class)`，否则绿(0,1,0)。
- **目标**（`target.lua` Setup:UpdateBarColor:371）优先级：
  1. 被他人 tap 的非玩家 → 灰(0.5,0.5,0.5)
  2. `colorClass` 且目标是玩家 → 职业色
  3. `colorReaction` → `UnitReaction('player','target')`：`<=2` 红 / `3-4` 黄 / 其他绿
  4. 兜底绿
  另有 `Setup:CheckTargetTapped`（`target.lua:356`）专管 tap 灰条。
- **ToT/小队**（`mini.lua` Setup:StateManagement:522）：ToT 反应阈值与 target 略不同——`>=5` 绿 / `==4` 黄 / `<=3` 红（`mini.lua:550-558`）；小队只走 `colorClass`(开)或绿。
- **法力条颜色**：统一 `GetPowerColor(UnitPowerType(unit))`（`core/tools.lua:200`，0 蓝/1 红/2、3 黄）。

### 5. 回血回蓝闪光特效

「闪光」指脉冲/切割动画，但**仅伤害(`val < oldVal`)触发，回血回蓝理论上不应闪**（`statusbar.lua:148`/`:102` 的方向判断）。
已知现象（见「已知坑」FormatNumber 精度）：回血/回蓝时虽不触发掉血闪光，但小幅变化会被 `FormatNumber` 的 1 位小数与百分比 `floor` 舍入成相同文本，视觉上「像没更新」。

### 6. 玩家战斗/休息发光（`player.lua`）

独立于 StatusBar 动画，是叠在 PlayerFrame 上的 overlay 纹理脉冲：
- `Setup:CombatGlow`（`player.lua:217`）+ `callbacks.combatGlow`（`player.lua:715`）：`UI-Player-Status.blp` 染红，`OnUpdate` 内按 `math.sin` 脉冲 alpha；离开战斗时 fade out。事件 `PLAYER_REGEN_DISABLED/ENABLED`。
- `Setup:RestingGlow`（`player.lua:240`）+ `callbacks.restingGlow`（`player.lua:779`）：同结构，色为 `restingColor`(默认青)，由 `IsResting()` 驱动，事件 `PLAYER_UPDATE_RESTING`。
- 状态图标 `Setup:StateIcons`（`player.lua:274`）：复用 vanilla `PlayerAttackIcon`(剑)/`PlayerRestIcon`(Zzz)，二者互斥(战斗优先)，对当前图标做 alpha 呼吸(0.45~1.0)。
- 所有 OnUpdate 用 `this.tick` 限频(0.01s) + `DFUI.activeScripts[...]` 登记活跃脚本。

### 7. 能量/法力回复指示（`player.lua` Setup:EnergyTick:309）

仅对 `UnitPowerType==0`(MANA) 或 `==3`(ENERGY) 显示一根 `UI-CastingBar-Spark` 火花在蓝条上滑动，
按 mana/energy diff 推断回复节奏（MANA 5s tick / ENERGY 2s tick）。回调 `callbacks.energyTick`（`player.lua:844`）驱动 spark 位置。

### 8. PvP 图标（`pvp.lua`）

`Setup:UpdatePvPIcon(frame, unit)`（`pvp.lua:12`）：FFA → `UI-PVP-FFA`；按阵营 `UnitFactionGroup` 设 `UI-PVP-Alliance`/`UI-PVP-Horde`(DF 自定义)。
`pvpDark` 开关用 `SetVertexColor(0.1,...)` 压暗（`pvp.lua:32`）。事件 `PLAYER_ENTERING_WORLD`/`PLAYER_TARGET_CHANGED`/`UNIT_FACTION`。

### 9. HC 角色十字尖刺修复（`target.lua`）

Turtle HC(硬核)目标的 `TargetFrame_UpdateChallenges` 会把框体设成 `UI-TargetingFrame_HC` 系纹理，
其头像圆形区域含多余十字像素+金环，且 `TargetFrameTexture` 在 child frame 层级高于 parent 遮罩盖不住。
修复（`target.lua:651-659`）：hook `TargetFrame_UpdateChallenges`，若当前纹理名匹配 `UI%-TargetingFrame_HC` 则改回普通 `UI-TargetingFrameDF1.blp`。

## 四、已知坑与限制

1. **FormatNumber 精度**（target/ToT 数值显示）：`%.1fk`/`%.1fM` 1 位小数 + 百分比 `math.floor` 取整，
   导致小幅回血/回蓝时文本不变、血条宽度 <1px 不可见，用户感知像「数值没刷新」。**当前暂不调整**（项目记忆 `project_dfui_formatnumber`）。
   注意玩家/宠物/小队/ToT 的数值实际是**原始整数拼接，未过 FormatNumber**，只有 target.lua 用了 FormatNumber。

2. **HC 纹理层级**：框体纹理泄露(尖刺/多余内容)优先查 child frame 层级，parent 上的遮罩可能盖不住 child（记忆 `project_target_spike_resolved`）。

3. **1.12 纹理 API**：StatusBar 用 `SetTexCoord`+`SetWidth` 自实现进度，**不用** retail 的 SetMinMaxValues/SetAtlas/SetHorizTile（1.12 无这些 API）。

4. **TGA POT 限制**：`healthDF2.tga` 等自定义贴图须 2 的幂宽高，否则静默丢弃；新增 TGA/BLP 必须重启 WoW.exe（`/reload` 无效）。

5. **vanilla 血条硬禁用**：各模块 `Hide()` 后还把 `.Show = function() end`（如 `player.lua:97`、`mini.lua:79`），并在对应 hook 中反复压制，防止 vanilla 逻辑把原条弹回来。其中 `PetFrame_Update` hook（`mini.lua:183-190`）对 PetFrameHealthBar/PetFrameManaBar 归零宽高（`SetWidth(0)`/`SetHeight(0)`/`SetAlpha(0)`/`Hide()`）；而 `TargetofTarget_Update` hook（`mini.lua:232-234`）仅对 TargetofTargetHealthBar/TargetofTargetManaBar 调 `Hide()`，未归零宽高。

6. **运行期行为待实证**：脉冲/切割/发光的实际观感、ToT 节流(0.2s/0.5s)是否够平滑、能量 spark 节奏准确度，均需**游戏内实证**，本文档只描述代码逻辑。
