# 光环系统实现（P1）

> 本文记录光环系统的**代码级实现**：计时精度分层落地、libdebuff 集成、四色分类、buff/debuff 生命周期与刷新。
> 设计原则（分层 *为什么*、显示格式规约）见 [aura-timer-design.md](aura-timer-design.md)，本文不重复。
>
> 事实源：所有函数名 / 行号以 `modules/unit/auras.lua` 当前代码为准（约 2384 行）。

## 一、概览

`Auras` 是 `DFUI:NewMod("Auras", 2, ...)` 注册的模块（auras.lua:75），依赖 SuperWoW 提供 `UNIT_AURA` 事件与基于 GUID 的光环追踪。它做两件事：

1. **框体光环**：在玩家/目标/宠物/小队框架旁绘制自制 buff/debuff 图标（替换被隐藏的暴雪原生框）。
2. **Buff Bar**：屏幕右上角自制增益/减益/武器附魔栏（替换暴雪 `BuffFrame` + `TemporaryEnchantFrame`）。

计时器精度的核心矛盾：1.12 只有 `GetPlayerBuffTimeLeft` 对**玩家自身**返回真实剩余时间；其他单位的 buff 没有原生 timeleft API，只能靠事件捕获施法瞬间或名称查表估算。本模块用「按单位分层的计时来源级联」解决（详见第三节）。

## 二、关键文件

| 文件 | 角色 |
|------|------|
| `modules/unit/auras.lua` | 模块主体：事件链、计时级联、框体光环、Buff Bar |
| `libs/libdebuff.lua` | debuff 持续时间追踪库（shagu v1.1 移植），挂 `DFUI_Libs.libdebuff` |
| `data/debuffs.lua` | `DFUI_DebuffData`（名称→各等级持续时间）、`DFUI_DynDebuffs`（连击/天赋动态延长）、`DFUI_Judgements` |
| `libs/libtipscan.lua` | tooltip 扫描器，`DFUI_Libs.libtipscan:GetScanner(tag)`，用于读光环名 |
| `libs/libguid.lua` | GUID→`{name, level, ...}` 映射，挂 `DFUI_Libs.libguid.guidMap` |

加载顺序（Dragonflight-Fix.toc）：`data\debuffs.lua`(22) → `libtipscan`(27) → `libspell`(28) → `libdebuff`(29) → `libguid`(30) → `libhealth`(32) → `modules\unit\auras.lua`(80)。

**libhealth 与本模块无直接耦合**：auras.lua 不引用 libhealth（Grep 零命中）。libhealth 估算只服务于框体血量显示，经 `core/tools.lua:738` 的 `GetUnitRealHealth(unit)`（`max==100` 时调 `DFUI.libhealth:GetUnitHealth`）由 target/mini 模块消费。光环图标只读 `UnitBuff/UnitDebuff` 的贴图与堆叠数，不需要血量。见 [reference_libhealth_estimation]。

## 三、核心实现

### 3.1 计时来源级联（按单位分层）

显示链入口：`UpdateBuffs`(auras.lua:1124)、`UpdateDebuffs`(auras.lua:1272)。两者各按优先级尝试拿 `duration, timeleft`，命中即停：

**Buff（UpdateBuffs，auras.lua:1190-1237）**
1. 永久判定：tooltip 扫名 → `buffDurations[name] == 0` 则标 `isPermanentBuff`，整条级联跳过（auras.lua:1183-1187）。
2. 玩家：`FindPlayerBuffIndex(texture, "HELPFUL")` 配纹理找索引 → `GetPlayerBuffTimeLeft`（auras.lua:1192-1210）。
3. GUID 追踪：`texToSpell[NormalizeTexture(texture)]` → `GetTrackedDuration(guid, spellId)`，回退 `"tex:"` 键（auras.lua:1213-1219）。
4. 宠物回退：tooltip 扫名 → `LookupDuration(name)`，仅宠物允许（auras.lua:1223-1236）。

**Debuff（UpdateDebuffs，auras.lua:1330-1383）**
1. 玩家：`FindPlayerBuffIndex(texture, "HARMFUL")` → `GetPlayerBuffTimeLeft`（auras.lua:1331-1349）。
2. GUID 追踪：同上（auras.lua:1352-1358）。
3. libdebuff：`libdebuff:UnitDebuff(data.unit, i)` 取 `dur, tl`，**仅 player/pet**（auras.lua:1361-1367）。
4. 宠物回退：tooltip 扫名 → `LookupDuration`（auras.lua:1370-1383）。

分层落地点：
- **玩家精确**：`GetPlayerBuffTimeLeft` 是唯一原生真值 API。配 `maxdurations[normTex]` 缓存收敛"曾见的最大 timeleft"作总时长，让冷却旋转 / start 推算稳定（auras.lua:1198-1207、1337-1346）。
- **宠物允许名称回退**：buff 来源明确（玩家施放），`start=GetTime()` 基本准；故第 3/4 步对 pet 开放（auras.lua:1223、1361、1370）。
- **目标/小队仅事件追踪**：显示链里它们只能命中第 2 步 GUID 追踪（Nampower/UNIT_CASTEVENT 实时捕获，时间点准），不走 `LookupDuration`（auras.lua:1213）。
- **其他单位仅存在**：未命中任何级联时不显示计时器，仅显示图标（`else` 分支 `timer:Hide()`，auras.lua:1246-1248、1391-1394）。

> ⚠️ 间接路径：`SnapshotAndDetectNewAuras`(auras.lua:768) 对含 target/party 的**所有单位**用 `LookupDuration` 写 `auraDurations`（`start=GetTime()`），随后会被显示链第 2 步以"tex:"键读到。即切目标时预存在 buff 仍可能拿到偏大计时器——已知精度折中（见 design 文档第一节"间接路径"）。

### 3.2 事件追踪与持续时间学习

**UNIT_CASTEVENT**（`castTracker`，auras.lua:637-662）：`CAST` 类型 → 名称查 `LookupDuration` → `TrackDuration(targetGuid, spellId, dur)`，并桥接 libdebuff。

**Nampower AURA_CAST**（`nampowerTracker`，auras.lua:665-701，`pcall` 包裹防 API 缺失）：监听 `AURA_CAST_ON_SELF/OTHER`，从 `arg8`(durationMs) 取**精确毫秒**持续时间 → `TrackDuration` + 写 `learnedDurations[name]`（被 `LookupDuration` 最优先采用，auras.lua:510）。永久法术（`buffDurations[name]==0`）跳过。

**`TrackDuration`**(auras.lua:523)：写 `auraDurations[guid][spellId] = {start=GetTime(), duration}`，并同时按归一化纹理写 `["tex:"..norm]` 兜底键。**`GetTrackedDuration`**(auras.lua:539)：算 `remaining = start+duration-GetTime()`，≤0 即就地清除。

**清理**：`castTracker:OnUpdate`(auras.lua:708) 每 60s 扫 `auraDurations`，过期条目删除，整 guid 空则连 `auraSnapshots[guid]` 一并清。

### 3.3 libdebuff 集成

**写入（桥接）**：UNIT_CASTEVENT 与 Nampower 两个 handler 在拿到 `name+dur+targetGuid` 后，经 `DFUI_Libs.libguid.guidMap[targetGuid]` 取 `{name, level}`，调 `libdebuff:AddEffect(gdata.name, gdata.level, name, dur, nil, targetGuid)`（auras.lua:652-660、688-696）。Nampower 路径喂的是精确 ms，比 pfUI 更准。

**读取**：仅 player/pet debuff 显示链调 `libdebuff:UnitDebuff(unit, i)`（auras.lua:1362）与 `RefreshTimers` 兜底补时（auras.lua:1622-1628）。

**库内部**（libdebuff.lua）：
- `GetDuration(effect, rank)`(libdebuff.lua:67)：查 `DFUI_DebuffData`，缺失则回退 `ShaguPlates_locale[locale]["debuffs"]`（中文客户端，libdebuff.lua:55-65）；再按 `DFUI_DynDebuffs` 对鸡腿/割裂/SW:P 等做连击点/天赋动态加成（libdebuff.lua:83-110）。
- 自身监听 `UNIT_AURA`(target/pet/party)、`PLAYER_TARGET_CHANGED` 等，用 tooltip 扫名 + `AddEffect` 记账（libdebuff.lua:239-265）；并 hook 全局 `CastSpell/CastSpellByName/UseAction` 走 `AddPending`→`SPELLCAST_STOP` 时 `PersistPending`（libdebuff.lua:286-313）。
- 双索引：`debuffs[name][level][effect]`（UnitDebuff）与 `debuffsByGuid[guid][effect]`（UnitDebuffByGuid）。

### 3.4 四色分类（debuff 类型边框）

`DEBUFF_COLORS` 表（auras.lua:78-84）：

| key | RGB | 含义 |
|-----|-----|------|
| `Magic` | 0.2, 0.6, 1.0 | 魔法（蓝） |
| `Disease` | 0.6, 0.4, 0.0 | 疾病（褐） |
| `Poison` | 0.0, 0.6, 0.0 | 中毒（绿） |
| `Curse` | 0.6, 0.0, 1.0 | 诅咒（紫） |
| `none` | 0.8, 0.0, 0.0 | 无类型 / 未知（红，fallback） |

- 框体 debuff：`color = DEBUFF_COLORS[debuffType] or DEBUFF_COLORS.none`，`border:SetVertexColor(...)`（auras.lua:1314-1315）。`debuffType` 来自 `UnitDebuff` 第 3 返回值。
- Buff Bar debuff（HARMFUL）：`BB_UpdateBorder` 经 `GetPlayerBuffDispelType(buffIndex)` 取类型后同样上色（auras.lua:1916-1927）。
- 边框贴图统一 `Interface\Buttons\UI-Debuff-Overlays` + `SetTexCoord(0.296875, 0.5703125, 0, 0.515625)`（auras.lua:1053-1055、1862-1866）。

### 3.5 框体光环生命周期与刷新

- **创建**：`CreateAuraButton`(auras.lua:1045) 建图标 + 边框(debuff) + `CooldownFrameTemplate` 旋转 + timer/count FontString；`CreateAuraRow` 每行 16 个（auras.lua:1092）。容器 `CreateAuraContainer` 挂 UIParent、`MEDIUM`/level 10（auras.lua:988）；锚点 `CreateAuraAnchor` 锚到对应单位框（auras.lua:997），偏移由 `*AuraX/*AuraY` 滑条控制（callbacks 调 `RepositionAnchor`，auras.lua:2361-2380）。
- **更新**：`UpdatePlayerAuras/UpdateTargetAuras/UpdatePetAuras/UpdatePartyAuras` 读各自 TempDB 设置 → 调 `UpdateBuffs/UpdateDebuffs`；debuff 行按可见 buff 行数下移（`buffRows*step`，auras.lua:1482 等）。`UpdateAllAuras` 汇总（auras.lua:1605）。
- **变更检测**：`UpdateBuffs/UpdateDebuffs` 对比 `icon:GetTexture()` 与新纹理，不同则清 `timerStart/timerDuration` 防残留（auras.lua:1156-1159、1306-1309）。
- **布局**：`LayoutAuras`(auras.lua:1104) 只对 `IsShown()` 的按钮紧凑排布，按 `perRow` 折行，`growRight` 控制左/右增长。
- **倒计时刷新**：独立 `timerFrame:OnUpdate`(auras.lua:1710) 每 0.1s 跑 `RefreshTimers`(auras.lua:1617)，用 `timerDuration - (GetTime()-timerStart)` 算剩余；文本变化才 `SetText`（`_lastTimerText` diff 省 GC，auras.lua:1659）；归零则 Hide 并清状态。设置每 ~2s 经 `RefreshTimerSettings` 重缓存（auras.lua:1687）避免 OnUpdate 里频繁 GetTempDB。
- **事件驱动重建**：`eventFrame`(auras.lua:1765) 监听 `UNIT_AURA`(分单位)、`PLAYER_AURAS_CHANGED`、`PLAYER_TARGET_CHANGED`、`PLAYER_ENTERING_WORLD`、`UNIT_PET`、`PARTY_MEMBERS_CHANGED`、`RAID_ROSTER_UPDATE`，分别 `SeedSnapshot`/`SnapshotAndDetectNewAuras` + 对应 Update（auras.lua:1774-1830）。
- **永久判定**：`buffDurations[name]==0` 或 timeleft ≥ `PERMANENT_THRESHOLD`(86400) 视为永久，不显示计时器（auras.lua:473、506、1952）。
- **隐藏原生**：`HideBlizzardTargetAuras`(auras.lua:873，覆盖 Turtle 扩展的 32 槽)、`HideBlizzardPartyAuras`(auras.lua:927)、`HideBlizzardPetAuras`(auras.lua:949)，并 hook `TargetFrame_UpdateAuras`/`PetFrame_Update` 等保持隐藏；空置 `TargetDebuffButton_Update` 切断 ShaguTweaks Debuff Timer hook 链（auras.lua:907-909）。

### 3.6 Buff Bar 生命周期

- **初始化**：`BB_Init`(auras.lua:2179) 按 `buffBarMode` 三态分支：`Default` 还原暴雪框；`Disabled` 关暴雪不建自制；`Buff Bar` 关暴雪 + 建 `BB_CreateBuffFrame`(HELPFUL/HARMFUL) + `BB_CreateWeaponFrame`，三段竖排（auras.lua:2225-2232）。
- **按钮更新**：`BB_UpdateButton` = Icon+Border+Count+Duration+TimerPosition（auras.lua:1990）。计时直接 `GetPlayerBuffTimeLeft`（Buff Bar 只显示玩家，故全程精确，auras.lua:1951）。武器附魔走 `GetWeaponEnchantInfo`（auras.lua:1998）。
- **排序**：`BB_SortButtons`(auras.lua:2038) 按 `buffBarSortOrder` 对 `GetPlayerBuff` 索引重排，写 `frame.sortedIndices`。
- **刷新节流**：每个 frame 自带 `OnUpdate` 0.1s tick（auras.lua:2122）。
- **交互**：右键 `CancelPlayerBuff`/`CancelItemTempEnchantment`，hover `GameTooltip:SetPlayerBuff`（auras.lua:2101-2116）。
- **格式**：Buff Bar 调 `FormatTime(t, style)` 不传 compact（时钟格式 HH:MM）；框体调 `FormatTime(t, style, true)`（紧凑单位制）。`ApplyTimerColor` 按 Gold / White+Red 上色（auras.lua:625）。

## 四、已知坑与限制

- **强依赖 SuperWoW**：GUID 追踪、`UNIT_AURA`、`GetUnitField("aura")`(auras.lua:554) 均需 SuperWoW；Nampower `AURA_CAST_*` 缺失时 `pcall` 静默降级，损失毫秒级精确时长。
- **预存在 buff 计时偏大**：目标/小队切换时已跑一半的 buff，经 `SnapshotAndDetectNewAuras` 的 `LookupDuration`(start=GetTime()) 间接路径会偏大——刻意保留（近似优于不显示）。
- **Lua 5.0 约束**：取长度全程 `table.getn`（如 BB_SortButtons auras.lua:2061、libdebuff queueFrame libdebuff.lua:41），无 retail `SetAtlas`，旋转用 `CooldownFrameTemplate`+`CooldownFrame_SetTimer`。
- **GetPlayerBuff 与 UnitBuff 枚举顺序可能不一致**：故玩家计时不能假设 `i-1` 索引对齐，必须 `FindPlayerBuffIndex` 按纹理配 0..31（auras.lua:477-487）。同纹理多 buff 时配错风险待游戏内实证。
- **中文 buff 时长靠手维护表**：`buffDurations` zhCN 分支（auras.lua:349-470）来自 Babble-Spell + ShaguPlates 静态表，Turtle 自定义/改版 buff 时长可能不符——运行期准确性待游戏内实证。
- **libdebuff 名称查表覆盖有限**：`DFUI_DebuffData` 为静态库，未收录的 debuff（尤其 Turtle 自定义）`GetDuration` 返回 0，只能靠事件追踪兜底。
- **libhealth 不参与光环**：本模块不读血量；若未来要按血量/类型过滤光环需新接 `GetUnitRealHealth`，勿在 OnUpdate 直接调（估算有 conf 阈值，低置信回退百分比）。
