#!/bin/zsh
set -euo pipefail

EXPECTED_VERSION="0.3.0"
LOCAL_CORE="${CODEDROBE_CORE_DIR:-$HOME/Documents/WorkBuddy/CodeDrobe-core}"
PORT="${CODEDROBE_WORKBUDDY_PORT:-9336}"
PERSISTENCE_INSTALLER="$HOME/.codex/skills/desktop-skin-router/scripts/install_persistence_guard_macos.sh"

if [[ -f "$LOCAL_CORE/bin/codedrobe.mjs" ]]; then
  NODE_BIN="$(command -v node 2>/dev/null || true)"
  [[ -n "$NODE_BIN" ]] || { print -u2 "找不到 Node.js。"; exit 2; }
  CLI=("$NODE_BIN" "$LOCAL_CORE/bin/codedrobe.mjs")
elif command -v codedrobe >/dev/null 2>&1; then
  CLI=(codedrobe)
else
  print -u2 "找不到 CodeDrobe Core 0.3.0。"
  exit 2
fi

version="$(${CLI[@]} --version)"
[[ "$version" == "$EXPECTED_VERSION" ]] || {
  print -u2 "需要 CodeDrobe Core $EXPECTED_VERSION，当前为 $version。"
  exit 2
}

command_name="${1:-help}"
project="${2:-}"
[[ "$command_name" == "help" || -n "$project" ]] || { print -u2 "缺少项目绝对路径。"; exit 2; }
if [[ -n "$project" ]]; then
  project="${project:A}"
  [[ -d "$project" ]] || { print -u2 "项目不存在: $project"; exit 2; }
fi

manifest="$project/theme.json"
bundle_path() {
  node -e 'const fs=require("fs"),p=require("path"),m=JSON.parse(fs.readFileSync(process.argv[1],"utf8")); process.stdout.write(p.join(process.argv[2],"build",`${m.id}-${m.version}.codedrobe-theme`));' "$manifest" "$project"
}

pack() {
  [[ -f "$manifest" ]] || { print -u2 "缺少 $manifest"; exit 2; }
  mkdir -p "$project/build" "$project/dom" "$project/screenshots" "$project/logs"
  bundle="$(bundle_path)"
  ${CLI[@]} theme pack "$manifest" --output "$bundle" --force | tee "$project/logs/pack-latest.txt"
  ${CLI[@]} theme inspect "$bundle" | tee "$project/logs/inspect-latest.txt"
}

case "$command_name" in
  snapshot)
    mkdir -p "$project/dom"
    ${CLI[@]} dom snapshot --app workbuddy --port "$PORT" --max-nodes 3000 --output "$project/dom/workbuddy-native.json"
    ;;
  probe)
    ${CLI[@]} probe --app workbuddy --port "$PORT" --timeout-ms 10000 --json
    ;;
  pack) pack ;;
  apply)
    pack
    bundle="$(bundle_path)"
    ${CLI[@]} apply --app workbuddy --port "$PORT" --theme "$bundle" --json | tee "$project/logs/apply-latest.json"
    [[ -x "$PERSISTENCE_INSTALLER" ]] && "$PERSISTENCE_INSTALLER" --workbuddy-theme "$bundle"
    ;;
  verify)
    bundle="$(bundle_path)"
    [[ -f "$bundle" ]] || pack
    ${CLI[@]} verify --app workbuddy --port "$PORT" --theme "$bundle" --screenshot "$project/screenshots/workbuddy-theme-live.png" --json | tee "$project/logs/verify-latest.json"
    ;;
  restore)
    mkdir -p "$project/logs"
    ${CLI[@]} restore --app workbuddy --port "$PORT" --json | tee "$project/logs/restore-latest.json"
    ;;
  persist)
    bundle="$(bundle_path)"
    [[ -f "$bundle" ]] || pack
    [[ -x "$PERSISTENCE_INSTALLER" ]] || { print -u2 "找不到桌面皮肤会话守卫安装器。"; exit 2; }
    "$PERSISTENCE_INSTALLER" --workbuddy-theme "$bundle"
    ;;
  status)
    ${CLI[@]} detect --app workbuddy --json
    ${CLI[@]} probe --app workbuddy --port "$PORT" --timeout-ms 1500 --json || true
    ;;
  help|-h|--help)
    print "用法: $0 {snapshot|probe|pack|apply|verify|restore|persist|status} /绝对/项目路径"
    ;;
  *) print -u2 "未知命令: $command_name"; exit 2 ;;
esac
