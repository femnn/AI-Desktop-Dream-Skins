# AI Desktop Dream Skins

[English](README.en.md) · 中文

为 Codex、腾讯 WorkBuddy 和 TRAE Work 分别制作的完整桌面主题工作流。仓库不仅保存背景图，还保存平台专用 Skill、CSS、主题包、持久化守卫、基础主题和真实界面截图。

## 三套基础主题

| 平台 | 基础主题 | 套装内容 | 启动恢复 |
| --- | --- | --- | --- |
| Codex | ASTRO BOT · 星舰 | 完整界面、独立装饰、四种表情、DualSense 宠物 | Codex 自身会话守卫 |
| WorkBuddy | Switch 2 · Adventure All-Stars 1.2.1 | 专用横幅、卡带、Joy-Con、首页与会话页 CSS | 事件驱动守卫，优先热恢复 |
| TRAE Work / TRAE SOLO | Xbox Series X\|S · Power Lab | X/S 主视觉、黑绿界面、首页与会话页、高对比输入框 | 事件驱动守卫，优先热恢复 |

### Codex · ASTRO BOT

![Codex ASTRO BOT 首页](screenshots/codex/home.png)

![Codex ASTRO BOT 项目页](screenshots/codex/project.png)

![Codex DualSense 宠物动作与表情](screenshots/codex/pet.png)

### WorkBuddy · Switch 2

![WorkBuddy Switch 2 首页](screenshots/workbuddy/home.png)

![WorkBuddy Switch 2 项目页](screenshots/workbuddy/project.png)

### TRAE · Xbox Series X|S

![TRAE Xbox 首页](screenshots/trae/home.png)

![TRAE Xbox 项目页](screenshots/trae/project.png)

## 安装 Skills

macOS 终端运行：

```bash
./scripts/install-skills-macos.sh
```

脚本会先把已有同名 Skill 备份到 `~/.codex/skill-backups/`，再安装 5 个组件：

- `desktop-skin-router`
- `codex-theme-pet-studio`
- `hatch-pet`
- `workbuddy-theme-studio`
- `trae-work-dream-skin`

安装只整理 Skill 和主题注册，不会强制关闭正在工作的应用。完整使用方法见 [启动与恢复说明](docs/STARTUP-GUIDE.zh-CN.md)。

## 每次启动要注意

1. 从 Dock 或 Finder 正常打开应用，然后等待主题出现；不要连续重复点击图标。
2. 如果应用启动时没有调试端口，WorkBuddy/TRAE 可能自动恢复并且只重启一次，这是预期行为。
3. 制作素材和改 CSS 时不要重启应用；全部完成后再做一次最终重启验收。
4. 主题没有出现时先运行 `./scripts/check-installation-macos.sh`，不要先反复重装。
5. 更新或移动主题包后必须重新执行对应 Skill 的 `persist`。
6. WorkBuddy/TRAE 自动恢复前应先保存未发送输入和正在编辑的内容。

## 目录

```text
skills/       三个平台 Skill、路由器和宠物生成 Skill
themes/       三套可安装基础主题
screenshots/  首页、会话页和可读性验收截图
docs/         中英文启动、恢复和平台差异说明
scripts/      安装与只读检查脚本
```

## 设计与兼容原则

- 三个平台使用不同尺寸、DOM 合同、端口、清单和包格式，禁止混用选择器。
- 主题必须覆盖首页和真实项目会话页，不以“只换壁纸”为完成标准。
- 装饰层必须 `pointer-events: none`，文字必须经过真实尺寸对比度检查。
- 持久化守卫监听应用启动事件，不轮询，也不会在用户退出后擅自打开应用。

## 声明

这是非官方、粉丝创作的本地主题工具。Codex、ASTRO BOT、PlayStation、Nintendo Switch、Xbox、TRAE 和 WorkBuddy 等名称及相关标识归各自权利人所有。仓库中的原创主题素材不代表任何官方授权；使用者应自行确认当地法律、软件条款和再分发权限。
