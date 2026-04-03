# 巨龙时代 Fix (Dragonflight-Fix)

基于 [DragonflightUI-Reforged](https://github.com/Stormhand-dev/DragonflightUI-Reforged) 的汉化修复增强版，适用于 Turtle WoW 1.18.1+。

## 功能特性

### 核心 UI

- **巨龙时代风格 UI** — 现代化界面设计，适配经典旧世
- **模块化架构** — 每个组件可独立开关（动作条、施法条、单位框体、小地图、背包等）
- **配置文件系统** — 支持明/暗两套主题，账号级存储，角色级布局
- **自定义施法条** — 平滑动画、火花特效、闪光反馈
- **单位框体** — 玩家/目标/小队/目标的目标框体，职业着色、战斗发光、休息动画
- **经验/声望条** — 文字显示、进度追踪
- **GUI 设置面板** — 可视化配置界面，滑块/复选框/颜色选择器/下拉菜单
- **首次登录向导** — 新用户引导设置

### 增强模块 (Fix 版新增)

- **冷却时间数字显示** — 技能/物品冷却倒计时覆盖层，4 档颜色阈值（红/黄/绿/灰），支持天/时/分/秒多级格式
- **物品比较** — Shift+悬停物品时自动显示当前装备同部位对比 Tooltip
- **Tooltip 增强** — 鼠标跟随模式、XY 偏移调整、目标的目标显示、距离显示（需 UnitXP）
- **聊天系统增强** — 8 种 URL 模式检测（可点击复制）、时间戳注入、频道名缩写（G/P/R/BG 等）、深色模式
- **职业配色方案** — Vanilla/TBC/Dragonflight 三套预设，支持单独修改每个职业颜色，全局联动单位框架
- **天赋规划/模拟** — 已学/规划双模式切换，左键加点/右键减点/滚轮操作，最多 20 套方案，前置依赖校验，数据持久化
- **Buff/Debuff 计时系统** — 多源级联计时架构（GetPlayerBuffTimeLeft + GUID追踪 + libdebuff + Nampower），pfUI 式 maxdurations 缓存，永久光环自动过滤，UNIT_CASTEVENT/Nampower 桥接 libdebuff 增强 debuff 覆盖，运行时自动学习法术持续时间；增益栏独立显示、图标大小/间距/排序可配、计时器样式选择
- **暗黑风格血球/蓝球** — 动作条两侧球形血量/法力显示，21 帧液面纹理 + SetHeight 动态裁剪，支持怒气/能量自动切换颜色，低血量脉冲警告，边框左右独立偏移/缩放，运行时动态开关

### 底层库 (Fix 版新增)

- **GUID 追踪库 (libguid)** — 为 WoW 1.12.1 提供伪 GUID 生成与追踪，有 SuperWoW 时自动使用原生 UnitGUID
- **自定义事件库 (libevents)** — 延迟事件触发（PLAYER_AFTER_ENTERING_WORLD / SYNC_READY）
- **配置版本迁移** — 升级时自动合并新配置项，保留用户已有设置（DBversion 2.0）

## 相对原版的修改

- **完整中文本地化** — 所有界面文字、设置描述、Aura 配置（约 50 项）均翻译为中文
- **全局字体统一** — 中文兼容字体，解决中文显示方块/乱码问题
- **8 个新增模块** — 冷却数字、物品比较、Tooltip 增强、聊天增强、职业配色、天赋模拟、Buff 增强、暗黑血球
- **2 个新增底层库** — libguid GUID 追踪 + libevents 自定义事件
- **Buff/Debuff 计时系统重构** — 消除伪造计时器，只在拥有真实施法时间时显示；桥接 SuperWoW/Nampower 事件到 libdebuff，大幅提升 debuff 计时覆盖率
- **Bug 修复** — 修复兼容 Turtle WoW 1.18.1 的各种问题
- **小地图重做** — 大幅改进小地图模块
- **错误处理优化** — 自定义错误处理器，防止报错刷屏
- **兼容性改进** — 改善与 ShaguTweaks/ShaguPlates 的集成，自动禁用 16 个冲突模块
- **配置迁移系统** — 版本升级时合并而非清空用户配置，支持 DFRL → DFF → DFUI 全链路迁移
- **全局命名空间重构** — DFRL → DFUI，斜杠命令 `/dfui`，存档变量 `DFUI_*`
- **物品比较多语言** — 使用 WoW 本地化全局变量替代硬编码英文，支持 7 种语言（zhCN/enUS/deDE/esES/frFR/koKR/ruRU）

## 安装说明

### 基本安装

1. 下载本项目
2. 将文件夹放入 WoW 目录：`Interface\AddOns\`
3. **文件夹必须命名为 `Dragonflight-Fix`**（GitHub 下载的 zip 解压后需将 `dragonflight-fix-main` 重命名）
4. 启动游戏，通过 ESC 菜单或 `/dfui` 命令打开设置面板

### 推荐依赖

- **SuperWoW 1.5+** — 启用原生 GUID 支持、UNIT_CASTEVENT 事件，Buff/Debuff 计时系统核心依赖
- **UnitXP SP3** — 启用 Tooltip 距离显示、Nampower AURA_CAST 精确计时（毫秒级）等扩展功能

### 贴图替换（可选）

`1. EXTRAS\Minimap\` 目录下包含小地图箭头贴图替换文件（`.blp`）。

> 这些**不是插件文件**，是直接贴图替换。

安装方法：
1. 将 `1. EXTRAS\Minimap\` 整个文件夹复制到 `Interface\` 目录下
2. 最终路径为 `Interface\Minimap\MinimapArrow.blp` 等
3. **注意：是 `Interface\` 目录，不是 `Interface\AddOns\`**

## 兼容性

| 插件 | 状态 |
|------|------|
| ShaguTweaks | 自动禁用 14 个冲突模块（冷却数字、装备对比、单位框体增强等），互补模块保留 |
| ShaguTweaks-extras | 自动禁用 1 个冲突模块（聊天时间戳） |
| ShaguPlates | 自动禁用冷却数字模块，姓名版系统独立运行不冲突 |
| Immersion | 自动检测，安全共存 |
| Bagshui | 自动检测，安全共存 |

## 项目结构

```
Dragonflight-Fix/
├── core/           # 核心框架（错误处理、主对象、工具函数、状态栏、兼容层）
├── data/           # 静态数据（减益、常量表、天赋描述）
├── libs/           # 独立库（Tooltip 扫描、法术、减益追踪、GUID、事件）
├── modules/
│   ├── bars/       # 动作条 + 距离检测 + 暗黑血球
│   ├── bags/       # 背包
│   ├── cast/       # 施法条
│   ├── chat/       # 聊天增强
│   ├── frames/     # 框架定位
│   ├── gui/        # 设置面板
│   ├── map/        # 小地图
│   ├── menu/       # 菜单 + 插件管理
│   ├── micro/      # 微型按钮
│   ├── track/      # 追踪
│   ├── ui/         # UI 增强（Tooltip、冷却、物品比较、配色、天赋）
│   ├── unit/       # 单位框体（玩家、目标、小队、PvP、Aura）
│   └── xprep/      # 经验/声望条
└── media/          # 贴图、字体资源
```

## 致谢

- **原作者**: [Karl-Heinz-Schneider](https://github.com/Karl-Heinz-Schneider) — 原版 [DragonflightUI](https://github.com/Karl-Heinz-Schneider/WoW-DragonflightUI) 的开发者
- **重铸版作者**: [Stormhand](https://github.com/Stormhand-dev) — [DragonflightUI-Reforged](https://github.com/Stormhand-dev/DragonflightUI-Reforged)
- **修改者**: [anym](https://github.com/aymmmmmm) — 中文本地化、计时系统重构、模块扩展、Bug 修复
