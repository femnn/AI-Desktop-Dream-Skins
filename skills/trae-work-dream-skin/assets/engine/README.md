# macOS 安装包

普通用户直接双击 `Install TRAE Work Dream Skin.command`。安装完成后，使用桌面的启动、定制、验证和恢复入口。

## 系统要求

- macOS 12 或更高版本
- 官方 TRAE Work 桌面端
- 不需要另外安装 Node.js

当前 TRAE Work 可能安装为 `/Applications/TRAE SOLO.app`，脚本通过 Bundle ID `com.trae.solo.app` 识别。

## 命令行

```bash
./tests/run-tests.sh
./scripts/install-dream-skin-macos.sh --no-launch
./scripts/customize-theme-macos.sh --preset pixel-8bit
./scripts/verify-dream-skin-macos.sh --screenshot "$HOME/Desktop/验证.png"
./scripts/restore-dream-skin-macos.sh --restart-trae
```

自定义图片：

```bash
./scripts/customize-theme-macos.sh \
  --image "/path/to/image.png" \
  --name "我的 TRAE 主题" \
  --accent "#e25563" \
  --secondary "#36b8c8" \
  --highlight "#f3c96a"
```

安装位置：

| 内容 | 路径 |
| --- | --- |
| 运行引擎 | `~/.trae/trae-work-dream-skin-studio` |
| 状态、日志和用户主题 | `~/Library/Application Support/TraeWorkDreamSkinStudio` |
| 桌面入口 | `~/Desktop/TRAE Work Dream Skin*.command` |

安全说明和实现原理见仓库根目录的 `docs/ARCHITECTURE.md`。
