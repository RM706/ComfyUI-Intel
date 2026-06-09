# ComfyUI Intel Docker

基于 Intel XPU (PyTorch) 的 ComfyUI Docker 镜像，支持 Intel 显卡加速推理。

## 特性

- 基于 `intel/pytorch:xpu` 镜像，原生支持 Intel GPU
- 使用国内镜像源加速构建（清华 APT 源、北外 PyPI 源）
- 默认启用 CORS 跨域支持，可被外部网页调用 API
- 容器启动时自动安装 `custom_nodes` 中各节点的 `requirements.txt` 依赖

## 文件说明

| 文件                    | 说明                                                         |
| ----------------------- | ------------------------------------------------------------ |
| `Dockerfile`            | 镜像构建文件                                                 |
| `comfyui-intel.compose` | docker compose 配置                                          |
| `entrypoint.sh`         | 容器启动入口，处理目录初始化、自动安装 custom_nodes 依赖     |

## 构建镜像

```bash
docker build -t comfyui_intel .
```

## 快速开始

### 前置条件

- Intel GPU（如 Arc 系列）
- Docker 已安装

### docker compose 启动

```bash
docker compose -f comfyui-intel.compose up -d
```

首次启动后，当前目录会生成 `models/`、`user/`、`output/`、`custom_nodes/` 四个目录：

| 目录 | 用途 |
|------|------|
| `models/` | 存放模型权重文件（checkpoints、vae、loras 等） |
| `user/` | 用户配置、工作流 |
| `output/` | 生成的图片输出 |
| `custom_nodes/` | 自定义节点插件 |

## 访问

启动后访问 `http://localhost:8188` 即可使用 ComfyUI。
