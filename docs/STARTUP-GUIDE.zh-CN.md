# 启动、持久化与恢复

## 首次安装

```bash
cd /你的路径/AI-Desktop-Dream-Skins
./scripts/install-skills-macos.sh
./scripts/check-installation-macos.sh
```

安装器会备份旧 Skill、安装新 Skill、安装 Codex 基础套装，并注册 WorkBuddy/TRAE 的事件驱动守卫。它不会为了安装而关闭应用。

## Codex

安装基础套装后，用主题选择器切换：

```bash
~/.codex/skills/codex-theme-pet-studio/scripts/switch_pack_macos.sh --id astro-bot
```

这条命令会同时切换界面和宠物。请在工作完成后执行；如果当前 Codex 没有可用热连接，最终恢复可能需要一次重启。

## WorkBuddy

需要 CodeDrobe Core 0.3.0，默认位置为 `~/Documents/WorkBuddy/CodeDrobe-core`，也可用 `CODEDROBE_CORE_DIR` 指定。

```bash
PROJECT="$PWD/themes/workbuddy/switch2-adventure"
~/.codex/skills/workbuddy-theme-studio/scripts/workbuddy-theme.sh apply "$PROJECT"
~/.codex/skills/workbuddy-theme-studio/scripts/workbuddy-theme.sh verify "$PROJECT"
~/.codex/skills/workbuddy-theme-studio/scripts/workbuddy-theme.sh persist "$PROJECT"
```

以后从 Dock/Finder 正常打开 WorkBuddy。守卫先验证，端口可用时热注入；端口不存在时最多允许一次恢复重启。不要连续点击 WorkBuddy 图标。

## TRAE Work / TRAE SOLO

```bash
~/.codex/skills/trae-work-dream-skin/scripts/trae-work-skin.sh apply-preset xbox-series-xs
~/.codex/skills/trae-work-dream-skin/scripts/trae-work-skin.sh persist
~/.codex/skills/trae-work-dream-skin/scripts/trae-work-skin.sh doctor
```

以后正常打开 TRAE 并等待主题恢复。输入区必须检查：输入文字为白色、占位文字清晰、光标与按钮可见、聊天页没有被背景遮挡。

## 主题没有出现

先执行：

```bash
./scripts/check-installation-macos.sh
~/.codex/skills/desktop-skin-router/scripts/status_persistence_guard_macos.sh
```

检查包路径是否存在、守卫是否运行、主题是否安装。不要先反复开关应用。移动 WorkBuddy 包或更新 TRAE 主题后，再运行一次 `persist`。

## 恢复官方界面

```bash
~/.codex/skills/workbuddy-theme-studio/scripts/workbuddy-theme.sh restore "$PWD/themes/workbuddy/switch2-adventure"
~/.codex/skills/trae-work-dream-skin/scripts/trae-work-skin.sh restore
```

恢复不会删除任务、项目或聊天记录。执行可能关闭并重新打开目标应用，必须先保存工作。
