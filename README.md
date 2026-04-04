# 巨龙时代 Fix (Dragonflight-Fix)

基于 [DragonflightUI-Reforged](https://github.com/Stormhand-dev/DragonflightUI-Reforged) 的汉化修复增强版，适用于 Turtle WoW 1.18.1+。

## 功能一览

| 功能 | 说明 |
|------|------|
| 巨龙时代风格 UI | 现代化界面设计，适配经典旧世 |
| 模块化开关 | 动作条、施法条、单位框体、小地图、背包等均可独立开关 |
| 配置文件 | 明/暗两套主题，账号级存储，角色级布局 |
| 完整中文支持 | 所有界面文字中文化，中文字体不乱码 |
| 单位框体 | 玩家/目标/宠物/小队框体，职业着色、战斗发光 |
| 施法条 | 平滑动画、火花特效、闪光反馈 |
| 冷却倒计时 | 技能/物品图标上直接显示剩余时间，颜色随时间变化 |
| Buff/Debuff 计时 | 玩家/目标/宠物/小队的增益减益倒计时，永久光环自动过滤，增益栏可自定义布局 |
| 天赋规划 | 规划模式下模拟加点，查看每级天赋描述，最多保存 20 套方案 |
| 物品比较 | Shift+悬停物品时自动显示当前装备对比 |
| Tooltip 增强 | 鼠标跟随、目标的目标显示、距离显示 |
| 聊天增强 | URL 可点击复制、时间戳、频道缩写、深色模式 |
| 职业配色 | Vanilla/TBC/Dragonflight 三套预设，可自定义每个职业颜色 |
| 暗黑血球/蓝球 | 动作条两侧球形血量/法力显示，支持怒气/能量自动切换，低血量脉冲警告 |
| 经验/声望条 | 文字显示、进度追踪 |
| 小地图 | 重新设计的小地图模块 |

## 安装

1. [下载](https://github.com/aymmmmmm/Dragonflight-Fix/archive/refs/heads/main.zip) 并解压
2. 将文件夹放入 WoW 目录的 `Interface\AddOns\`
3. **文件夹必须命名为 `Dragonflight-Fix`**（解压后需将 `Dragonflight-Fix-main` 重命名）
4. 启动游戏，输入 `/dfui` 打开设置面板

### 推荐搭配

| 组件 | 作用 | 必须？ |
|------|------|--------|
| SuperWoW 1.5+ | 增强 Buff/Debuff 计时精度，启用目标 debuff 倒计时 | 强烈推荐 |
| UnitXP SP3 | Tooltip 距离显示、更精确的计时 | 推荐 |

> 不安装也能正常使用，部分功能（如目标 debuff 计时）会受限。

### 小地图箭头替换（可选）

项目中 `1. EXTRAS\Minimap\` 目录包含小地图箭头贴图替换文件。

安装方法：将该文件夹复制到 `Interface\` 目录（注意：是 `Interface\`，不是 `Interface\AddOns\`）。

## 使用说明

### 设置面板

- 输入 `/dfui` 或通过 ESC 菜单打开
- 每个模块可单独开关、调整参数
- 修改后即时生效，无需重载

### Buff/Debuff 计时

- **玩家自身**：所有 Buff/Debuff 均有精确倒计时
- **目标/宠物**：你施放的或在场时施放的技能会显示倒计时；切换到陌生目标时，未知来源的 Buff 不会显示不准确的计时
- **永久光环**（如雄鹰守护、奉献光环）：自动识别，不显示倒计时
- 可在设置面板中分别调整玩家/目标/宠物/小队的计时器开关、字号、颜色风格

### 天赋规划

- 打开天赋面板，点击右上角切换「已学」/「规划」模式
- 规划模式下：左键加点、右键减点、滚轮操作
- 悬停天赋图标可查看当前等级和下一等级的详细描述
- 最多保存 20 套方案

### 物品比较

- 按住 Shift 悬停装备，自动显示已穿戴同部位装备的对比 Tooltip
- 支持多语言客户端

## 兼容性

| 插件 | 状态 |
|------|------|
| ShaguTweaks | 自动禁用冲突模块，互补模块保留 |
| ShaguTweaks-extras | 自动禁用冲突模块 |
| ShaguPlates | 安全共存 |
| Immersion | 安全共存 |
| Bagshui | 安全共存 |

## 已知限制

- 目标/队友身上**已存在的 Buff**（你不在场时施放的）无法显示倒计时，这是 WoW 1.12 客户端的 API 限制
- 配置文件在首次使用时自动创建，从旧版本升级会自动合并设置

## 致谢

- **原作者**: [Karl-Heinz-Schneider](https://github.com/Karl-Heinz-Schneider) — 原版 [DragonflightUI](https://github.com/Karl-Heinz-Schneider/WoW-DragonflightUI) 的开发者
- **重铸版作者**: [Stormhand](https://github.com/Stormhand-dev) — [DragonflightUI-Reforged](https://github.com/Stormhand-dev/DragonflightUI-Reforged)
- **修改者**: [anym](https://github.com/aymmmmmm) — 中文本地化、模块扩展、Bug 修复
- **测试**: [marcoatbath](https://github.com/marcoatbath)
