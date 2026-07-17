# Startup, persistence, and recovery

## First install

```bash
cd /path/to/AI-Desktop-Dream-Skins
./scripts/install-skills-macos.sh
./scripts/check-installation-macos.sh
```

The installer backs up previous Skills, installs the new ones, installs the Codex base pack, and registers the event-driven WorkBuddy/TRAE guard. It does not close applications during installation.

## Codex

```bash
~/.codex/skills/codex-theme-pet-studio/scripts/switch_pack_macos.sh --id astro-bot
```

This switches both the UI and the pet. Run it after saving your work. If the current Codex session has no hot endpoint, final recovery may require one restart.

The session guard permits one Codex instance during recovery and preserves the current task route. If recovery redirects to New Task, run `repair_single_launch_engine_macos.sh` instead of reopening the app repeatedly. An old transaction may roll back only while it still owns the active lock, so it cannot overwrite a newer theme and pet.

## WorkBuddy

CodeDrobe Core 0.3.0 is required. The default path is `~/Documents/WorkBuddy/CodeDrobe-core`; override it with `CODEDROBE_CORE_DIR`.

```bash
PROJECT="$PWD/themes/workbuddy/switch2-adventure"
~/.codex/skills/workbuddy-theme-studio/scripts/workbuddy-theme.sh apply "$PROJECT"
~/.codex/skills/workbuddy-theme-studio/scripts/workbuddy-theme.sh verify "$PROJECT"
~/.codex/skills/workbuddy-theme-studio/scripts/workbuddy-theme.sh persist "$PROJECT"
```

On later launches, open WorkBuddy normally and wait. The guard verifies first, hot-applies when the endpoint exists, and permits at most one recovery restart otherwise.

## TRAE Work / TRAE SOLO

```bash
~/.codex/skills/trae-work-dream-skin/scripts/trae-work-skin.sh apply-preset xbox-series-xs
~/.codex/skills/trae-work-dream-skin/scripts/trae-work-skin.sh persist
~/.codex/skills/trae-work-dream-skin/scripts/trae-work-skin.sh doctor
```

Verify white editor text, readable placeholder text, visible caret and buttons, and an unobstructed conversation page.

## When a theme is missing

```bash
./scripts/check-installation-macos.sh
~/.codex/skills/desktop-skin-router/scripts/status_persistence_guard_macos.sh
```

Check the registered package path and guard status before reinstalling or repeatedly reopening the app. Run `persist` again after moving a WorkBuddy package or changing the installed TRAE theme.

## Restore official UI

```bash
~/.codex/skills/workbuddy-theme-studio/scripts/workbuddy-theme.sh restore "$PWD/themes/workbuddy/switch2-adventure"
~/.codex/skills/trae-work-dream-skin/scripts/trae-work-skin.sh restore
```

Restore does not delete tasks, projects, or chats, but it may restart the target app. Save your work first.
