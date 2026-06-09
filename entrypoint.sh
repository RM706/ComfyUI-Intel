#!/bin/bash
# 容器启动入口：若宿主机挂载了空目录，从默认备份中填充原始内容
# 避免 bind mount 的空目录覆盖容器内的默认文件

DEFAULTS_DIR="/opt/comfyui/defaults"
TARGET_DIR="/opt/comfyui"

for dir in models user output custom_nodes; do
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

# 自动安装 custom_nodes 中缺失的依赖
# 注意：custom_nodes 本质上是 ComfyUI 插件，启动时会执行其中的 Python 代码，
# 因此 requirements.txt 引入的附加风险是有限的。
echo "[entrypoint] 检查 custom_nodes 依赖..."
for req in "$TARGET_DIR/custom_nodes/"*/requirements.txt; do
    if [ -f "$req" ]; then
        node_name=$(basename "$(dirname "$req")")
        echo "[entrypoint] 安装 $node_name 依赖，来自 $req ..."
        echo "[entrypoint] $node_name 将安装以下包："
        grep -v '^[[:space:]]*#' "$req" | grep -v '^[[:space:]]*$' || true
        pip install --no-cache-dir -r "$req" || echo "[entrypoint] 警告：$node_name 依赖安装失败，继续启动..."
    fi
done
echo "[entrypoint] custom_nodes 依赖检查完成"

exec "$@"
