FROM intel/pytorch:xpu-2.11.0-ubuntu24.04-20260608

# 使用清华源替换 Ubuntu 的 APT 源
RUN printf '%s\n' \
    "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble main restricted universe multiverse" \
    "deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble main restricted universe multiverse" \
    "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-updates main restricted universe multiverse" \
    "deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-updates main restricted universe multiverse" \
    "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-backports main restricted universe multiverse" \
    "deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-backports main restricted universe multiverse" \
    "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-security main restricted universe multiverse" \
    "deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-security main restricted universe multiverse" \
    "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-proposed main restricted universe multiverse" \
    "deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-proposed main restricted universe multiverse" \
    > /etc/apt/sources.list

# 更新包索引并安装 git
RUN apt-get update && \
    apt-get install -y --no-install-recommends git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 升级 pip 并设置镜像源
RUN python -m pip install --upgrade pip && \
    pip config set global.index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple

# 创建目录，克隆 ComfyUI 并安装 manager_requirements
WORKDIR /opt/comfyui
RUN git clone https://github.com/Comfy-Org/ComfyUI.git . && \
    pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir -r manager_requirements.txt && \
    pip install --no-cache-dir matrix-nio

RUN mkdir -p /opt/comfyui/defaults && \
    for dir in models user output custom_nodes; do \
        mkdir -p "$dir" && \
        cp -a "$dir" "/opt/comfyui/defaults/" 2>/dev/null || \
        mkdir -p "/opt/comfyui/defaults/$dir"; \
    done

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["python", "main.py", "--enable-manager", "--listen", "0.0.0.0"]
