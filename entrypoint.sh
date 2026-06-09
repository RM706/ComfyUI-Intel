#!/bin/bash
# 容器启动入口：若宿主机挂载了空目录，从默认备份中填充原始内容
# 避免 bind mount 的空目录覆盖容器内的默认文件

DEFAULTS_DIR="/opt/comfyui/defaults"
TARGET_DIR="/opt/comfyui"

for dir in models user output; do
    target="$TARGET_DIR/$dir"
    backup="$DEFAULTS_DIR/$dir"

    if [ -d "$target" ] && [ -z "$(ls -A "$target" 2>/dev/null)" ]; then
        echo "[entrypoint] 目录 $dir 为空，从默认备份复制..."
        if [ -d "$backup" ]; then
            cp -a "$backup/." "$target/"
            echo "[entrypoint] $dir 初始化完成"
        else
            echo "[entrypoint] 警告：备份目录 $backup 不存在，跳过 $dir"
        fi
    fi
done

exec "$@"
