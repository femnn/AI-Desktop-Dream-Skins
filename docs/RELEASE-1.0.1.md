# v1.0.1 · Codex 动态展示与会话修复 / Animated Codex gallery and session fix

## 中文

- Codex 主页改为用户确认的最新版界面，并输出为真实 12 帧 GIF。
- 宠物展示改为当前 `astro-dualsense` v2 图集的真实 4 帧动作 GIF。
- 修复主题恢复时重复执行 `open -na`，避免创建第二个 Codex 实例并跳到“新建任务”。
- 切换事务回滚增加锁所有权检查，过期进程不能再覆盖新主题和新宠物。
- 安装器现在同时安装 Codex 会话守卫，以及 WorkBuddy/TRAE 持久化守卫。

## English

- Replaced the Codex home showcase with the user-approved latest UI and a real 12-frame GIF.
- Replaced the static pet image with a real four-frame animation from the active `astro-dualsense` v2 atlas.
- Removed the duplicate recovery `open -na` call that created a second Codex instance and redirected to New Task.
- Added lock-ownership checks so stale transactions cannot roll back over a newer theme and pet.
- The installer now enables the Codex session guard alongside WorkBuddy/TRAE persistence.
