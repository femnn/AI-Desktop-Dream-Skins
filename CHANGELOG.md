# Changelog / 更新记录

## 1.0.1 - 2026-07-17

- 中文：Codex 展示改为用户确认的最新主页 GIF，并使用真实 v2 图集动作作为宠物 GIF。
- English: Replaced the Codex gallery with the user-approved latest home GIF and a real v2-atlas pet animation.
- 中文：修复恢复过程重复 `open -na` 导致跳到“新建任务”，并阻止过期事务回滚覆盖新套装。
- English: Fixed duplicate recovery launches that opened New Task and blocked stale transactions from rolling back over a newer pack.

## 1.0.0 - 2026-07-17

- 中文：收录 Codex ASTRO BOT、WorkBuddy Switch 2 1.2.1、TRAE Xbox Series X|S 三套基础主题及真实截图。
- English: Added the Codex ASTRO BOT, WorkBuddy Switch 2 1.2.1, and TRAE Xbox Series X|S base themes with real UI screenshots.
- 中文：持久化守卫改为优先验证和热恢复，仅在调试端口缺失时允许一次恢复重启。
- English: Persistence now verifies and hot-recovers first, allowing one recovery restart only when the debugging endpoint is absent.
- 中文：增加中英文启动说明、只读检查脚本和 Skill 自动备份安装器。
- English: Added bilingual startup instructions, a read-only checker, and a Skill installer with automatic backups.
