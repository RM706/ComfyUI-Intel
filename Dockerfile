FROM intel/pytorch:xpu-2.11.0-ubuntu24.04-20260608

# 使用清华源替换 Ubuntu 的 APT 源（同时清理 sources.list.d 中的默认源）
RUN rm -rf /etc/apt/sources.list.d/* && \
    printf '%s\n' \
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

# 添加 Intel oneAPI 仓库，用于安装 SYCL 编译器
RUN wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | gpg --dearmor | tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null && \
    echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" | tee /etc/apt/sources.list.d/oneAPI.list

# 更新包索引并安装 git 及 Intel oneAPI 编译工具链
RUN apt-get update && \
    apt-get install -y --no-install-recommends git intel-oneapi-compiler-dpcpp-cpp intel-oneapi-mkl-devel && \
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
    pip install --no-cache-dir matrix-nio matplotlib

# 安装使用SYCL后端的llama-cpp-python
# intel-oneapi-openmp（OpenMP 运行时）已通过 APT 随编译器包安装，无需 pip 安装
RUN . /opt/intel/oneapi/setvars.sh && \
    CMAKE_ARGS="-DGGML_SYCL=on -DCMAKE_C_COMPILER=icx -DCMAKE_CXX_COMPILER=icpx" \
    pip install --no-cache-dir llama-cpp-python

RUN mkdir -p /opt/comfyui/defaults && \
    for dir in models user output custom_nodes; do \
        mkdir -p "$dir" && \
        cp -a "$dir" "/opt/comfyui/defaults/" 2>/dev/null || \
        mkdir -p "/opt/comfyui/defaults/$dir"; \
    done

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["python", "main.py", "--enable-manager", "--enable-cors-header", "--listen", "0.0.0.0"]
