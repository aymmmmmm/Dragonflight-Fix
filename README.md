# 巨龙时代 Fix (Dragonflight-Fix)

基于 [DragonflightUI-Reforged](https://github.com/Stormhand-dev/DragonflightUI-Reforged) 的汉化修复版，适用于 Turtle WoW 1.18.1。

## 功能特性

- **巨龙时代风格 UI** — 现代化界面设计，适配经典旧世
- **模块化架构** — 每个组件可独立开关（动作条、施法条、单位框体、小地图、背包等）
- **配置文件系统** — 支持明/暗两套主题，账号级存储，角色级布局
- **自定义施法条** — 平滑动画、火花特效、闪光反馈
- **单位框体** — 玩家/目标/小队框体，职业着色、战斗发光、休息动画
- **经验/声望条** — 文字显示、进度追踪
- **GUI 设置面板** — 可视化配置界面，滑块/复选框/颜色选择器
- **首次登录向导** — 新用户引导设置

## 相对原版的修改

- **完整中文本地化** — 所有界面文字、设置描述均翻译为中文
- **Bug 修复** — 修复兼容 Turtle WoW 1.18.1 的各种问题
- **小地图重做** — 大幅改进小地图模块（315 行改动）
- **错误处理优化** — 自定义错误处理器，防止报错刷屏
- **兼容性改进** — 改善与 ShaguTweaks 的集成
- **代码清理** — 38 个文件，800+ 行改动

## 安装说明

### 基本安装

1. 下载本项目
2. 将文件夹放入 WoW 目录：`Interface\AddOns\`
3. **文件夹必须命名为 `Dragonflight-Fix`**（不能是其他名字）
4. 启动游戏

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
| ShaguTweaks | 自动禁用冲突模块，深度集成 |
| Immersion | 自动检测，安全共存 |
| PizzaWorldBuffs | 支持面板定位 |

## 致谢

- **Guzruul** — Dragonflight UI 2 Reloaded 原作者
- **Stormhand** — DragonflightUI-Reforged 重铸版作者
- **Shagu** — ShaguTweaks 框架
- **DragonflightUI by Karl-Heinz-Schneider** — 灵感来源
- **Blizzard Entertainment**
