# 企业级标准 RAG 个人知识库搭建教程

## 项目概述

本项目基于 Dify + Ollama + Milvus 技术栈搭建企业级标准的 RAG（检索增强生成）个人知识库。该知识库支持本地部署，保护数据隐私，同时提供企业级的向量检索能力。

**核心功能：**
- 本地大语言模型推理（Ollama）
- 可视化 RAG 平台（Dify）
- 企业级向量数据库（Milvus）
- 多知识库支持，每个知识库可配置独立的向量模型

## 项目结构

```
rag-pkb/
├── README.md                      # 项目说明文档
├── RAG服务开关.app                # macOS 应用程序（一键启动/关闭服务）
├── control-services.sh             # 服务控制脚本
├── config/                        # 配置文件目录
│   └── ollama/                   # Ollama 模型配置
├── data/                          # 数据目录
│   ├── code_repo/                # 代码仓库
│   └── knowledge_base/           # 知识库文件
├── deploy/                       # 部署文件目录
│   └── dify/                     # Dify 平台
│       ├── Dockerfile            # 自定义镜像构建文件
│       ├── patches/              # 代码修改补丁
│       │   ├── milvus/
│       │   │   └── milvus_vector.py
│       │   └── vdb/
│       │       └── vector_factory.py
│       └── docker/               # Docker 配置
│           ├── .env             # Dify 环境变量配置
│           ├── docker-compose.yaml
│           └── volumes/         # 数据卷
├── docs/                         # 文档目录
├── logs/                         # 日志目录
├── plugins/                      # 插件目录
└── scripts/                      # 脚本目录
```

## 技术栈

| 组件 | 用途 | 端口 |
|------|------|------|
| **Dify** | 可视化 RAG 平台 | 80 (Web), 5001 (API) |
| **Ollama** | 本地 LLM 引擎 | 11434 |
| **Milvus** | 向量数据库（Dify 内置） | 19530, 9091 |
| **PostgreSQL** | Dify 数据库 | 5432 |
| **Redis** | Dify 缓存 | 6379 |

### 使用的模型

- **推理模型**: `qwen3-4b-instruct-2507:latest`
- **中文 embedding 模型**: `bge-large-zh-v1.5:q8_0`
- **英文 embedding 模型**: `nomic-embed-text:v1.5`

## 环境准备

### 硬件要求

| 配置项 | 最低要求 | 推荐配置 |
|--------|----------|----------|
| 设备 | MacBook Air M2 16G | MacBook Air M4 24G |
| 内存 | 16GB | 24GB |
| 存储 | 50GB 可用空间 | 100GB SSD |
| GPU | 集成 GPU | 强大 GPU 加速 |

### 软件依赖

| 软件 | 版本要求 | 安装方式 |
|------|----------|----------|
| **Docker Desktop** | 最新版 | [Docker官网](https://www.docker.com/products/docker-desktop) |
| **Ollama** | 最新版 | [Ollama官网](https://ollama.com/download) |
| **Git** | 任意版本 | Homebrew: `brew install git` |

### macOS 系统代理注意事项

**重要**：如果系统开启了代理软件（如 ClashX、Surge 等），可能导致 Docker 容器网络问题。

**解决方案**：
1. 在 Docker Compose 配置中添加 `no_proxy` 环境变量
2. 或在系统代理中排除 Docker 内部网段：`localhost,127.0.0.1,host.docker.internal,172.18.0.0/16`

## 部署步骤

### 步骤 1：启动 Ollama 并下载模型

```bash
# 启动 Ollama 服务
ollama serve

# 下载推理模型
ollama pull qwen3-4b-instruct-2507:latest

# 下载中文 embedding 模型
ollama pull bge-large-zh-v1.5:q8_0

# 下载英文 embedding 模型
ollama pull nomic-embed-text:v1.5

# 验证模型列表
ollama list
```

### 步骤 2：构建自定义 Dify 镜像

```bash
# 进入 Dify 部署目录
cd ~/rag-pkb/deploy/dify

# 构建自定义镜像（包含代码修改）
docker build -t dify-api-custom:1.13.0 .
```

### 步骤 3：配置 Dify 环境变量

```bash
# 进入 Dify 配置目录
cd ~/rag-pkb/deploy/dify/docker

# 复制环境变量文件
cp .env.example .env
```

编辑 `.env` 文件，配置以下关键项：

```env
# ==================== 向量库配置 ====================
VECTOR_STORE=milvus
MILVUS_URI=http://host.docker.internal:19530
MILVUS_USER=root
MILVUS_PASSWORD=Milvus

# ==================== Ollama 配置 ====================
# 注意：使用 host.docker.internal 访问宿主机 Ollama
OLLAMA_BASE_URL=http://host.docker.internal:11434

# ==================== 代理配置（重要）====================
# 如果开启系统代理，需要添加以下配置避免容器内网络问题
no_proxy=localhost,127.0.0.1,host.docker.internal,plugin_daemon,redis,db_postgres,172.18.0.0/16
NO_PROXY=localhost,127.0.0.1,host.docker.internal,plugin_daemon,redis,db_postgres,172.18.0.0/16
```

### 步骤 4：启动 Dify 服务

```bash
# 进入 Dify Docker 目录
cd ~/rag-pkb/deploy/dify/docker

# 启动 Dify 所有服务
docker compose up -d

# 等待服务启动（约 1-2 分钟）
docker compose ps

# 查看服务日志
docker compose logs -f
```

**验证 Dify 启动成功：**
- 访问 http://localhost 应该能看到 Dify 登录页面
- 如果无法访问，检查日志：`docker compose logs web`

### 步骤 5：配置 Ollama 插件

1. 访问 Dify Web 界面 (http://localhost)
2. 进入「设置」→「模型供应商」
3. 点击「添加模型供应商」→ 选择「Ollama」
4. 配置：
   - URL: `http://host.docker.internal:11434`
5. 添加模型：
   - 推理模型：选择 Ollama → 添加 `qwen3-4b-instruct-2507:latest`
   - Embedding 模型：添加 `bge-large-zh-v1.5:q8_0` 和 `nomic-embed-text:v1.5`

### 步骤 6：创建知识库

1. 点击「知识库」→「创建知识库」
2. 填写知识库名称（如「小说创作」）
3. 配置向量模型：
   - 选择「Milvus」
   - 选择 embedding 模型（如 `bge-large-zh-v1.5:q8_0`）
4. 配置索引方式：
   - 推荐分段标识符：`<<<`
   - 最大分段长度：`2000`
   - 其他分段长度：`500`

### 步骤 7：上传文档并测试

1. 在知识库中点击「上传文档」
2. 等待文档处理完成
3. 在 Dify 中创建应用并关联知识库
4. 测试问答功能

## 验证测试

### 服务状态检查

```bash
# 检查所有 Docker 容器状态
docker ps

# 检查 Milvus 健康状态
curl -s http://localhost:19530/v1/healthz

# 检查 Ollama 服务
curl -s http://localhost:11434/api/tags
```

### 数据库状态检查

```bash
# 进入 Dify 数据库容器
docker exec -it docker-db_postgres-1 psql -U postgres -d dify

# 查看知识库列表
SELECT id, name, created_at FROM datasets;

# 查看向量集合绑定
SELECT provider_name, model_name, collection_name FROM dataset_collection_bindings;

# 查看文档索引状态
SELECT id, name, indexing_status, error FROM documents;
```

### 测试 RAG 功能

1. 创建「空白应用」或「知识库助手」应用
2. 关联已创建的知识库
3. 输入测试问题验证回答是否基于知识库内容

## 常用命令

### Dify 服务列表

| 服务名称 | 用途 | 端口 | 容器名称 |
|---------|------|------|-----------|
| **api** | Dify 后端 API 服务 | 5001 | docker-api-1 |
| **worker** | Celery 任务队列处理 | 5001 | docker-worker-1 |
| **worker_beat** | Celery 定时任务调度 | 5001 | docker-worker_beat-1 |
| **web** | Dify 前端 Web 界面 | 3000 | docker-web-1 |
| **nginx** | 反向代理服务器 | 80, 443 | docker-nginx-1 |
| **db_postgres** | PostgreSQL 数据库 | 5432 | docker-db_postgres-1 |
| **redis** | Redis 缓存服务 | 6379 | docker-redis-1 |
| **plugin_daemon** | 插件守护进程 | 5004 | docker-plugin_daemon-1 |
| **sandbox** | 沙箱环境 | - | docker-sandbox-1 |
| **ssrf_proxy** | SSRF 代理 | 3128 | docker-ssrf_proxy-1 |
| **milvus-standalone** | Milvus 向量库 | 19530 | dify-milvus-standalone |
| **milvus-etcd** | Milvus etcd 存储 | 2379 | dify-milvus-etcd |
| **milvus-minio** | Milvus 对象存储 | 9000 | dify-milvus-minio |

### Docker 服务管理命令

```bash
# 进入 Dify Docker 目录
cd ~/rag-pkb/deploy/dify/docker

# 启动所有服务
docker compose up -d

# 停止所有服务
docker compose stop

# 重启所有服务
docker compose restart

# 重启特定服务（如 api 和 worker）
docker compose restart api worker

# 重启 nginx
docker compose restart nginx

# 查看所有服务状态
docker compose ps

# 查看服务日志
docker compose logs -f

# 查看特定服务日志
docker compose logs -f api
docker compose logs -f worker
docker compose logs -f nginx

# 查看服务最近的日志
docker logs docker-api-1 --tail 50
docker logs docker-worker-1 --tail 50
docker logs docker-nginx-1 --tail 50

# 进入服务容器
docker exec -it docker-api-1 bash
docker exec -it docker-worker-1 bash
docker exec -it docker-db_postgres-1 psql -U postgres -d dify

# 停止并删除所有服务
docker compose down

# 停止并删除所有服务及数据卷
docker compose down -v
```

### Ollama 常用命令

```bash
# 启动 Ollama 服务
ollama serve

# 查看已安装的模型列表
ollama list

# 下载模型
ollama pull <模型名称>

# 下载推理模型
ollama pull qwen3-4b-instruct-2507:latest

# 下载中文 embedding 模型
ollama pull bge-large-zh-v1.5:q8_0

# 下载英文 embedding 模型
ollama pull nomic-embed-text:v1.5

# 运行模型进行测试
ollama run <模型名称>

# 运行推理模型测试
ollama run qwen3-4b-instruct-2507:latest

# 查看模型信息
ollama show <模型名称>

# 删除模型
ollama rm <模型名称>

# 查看模型版本信息
ollama show --modelfile <模型名称>

# 查看模型运行状态
ollama ps

# 检查 Ollama 服务状态
curl -s http://localhost:11434/api/tags
```

### 数据库查询命令

```bash
# 进入 Dify 数据库
docker exec -it docker-db_postgres-1 psql -U postgres -d dify

# 查看所有知识库
SELECT id, name, created_at FROM datasets;

# 查看向量集合绑定
SELECT provider_name, model_name, collection_name FROM dataset_collection_bindings;

# 查看文档索引状态
SELECT id, name, indexing_status, error FROM documents;

# 查看文档段落状态
SELECT COUNT(*), status FROM document_segments GROUP BY status;

# 重置文档状态
UPDATE documents 
SET indexing_status = 'waiting', error = NULL, stopped_at = NULL 
WHERE id = '文档ID';

# 重置段落状态
UPDATE document_segments 
SET status = 'pending' 
WHERE dataset_id = '知识库ID' AND status = 'indexing';

# 退出数据库
\q
```

### 系统服务检查命令

```bash
# 检查所有 Docker 容器状态
docker ps -a

# 检查容器资源使用情况
docker stats

# 查看容器详细信息
docker inspect <容器名称>

# 查看容器日志
docker logs <容器名称>

# 查看容器端口映射
docker port <容器名称>

# 清理未使用的 Docker 资源
docker system prune

# 查看磁盘使用情况
docker system df
```

### 一键启动/关闭服务

```bash
# 使用 macOS 应用程序
# 双击 RAG服务开关.app 即可一键启动/关闭所有服务

# 或使用脚本
./control-services.sh
```

## 常见问题与解决方案

### 1. Dify 内部服务器错误 (502 Bad Gateway)

**问题描述**：访问 Dify Web 界面时出现 502 错误

**原因分析**：
- Plugin daemon 服务未正常启动
- 端口映射配置错误

**解决方案**：
```bash
# 检查 plugin_daemon 服务状态
docker compose logs plugin_daemon

# 重启 nginx 服务
docker compose restart nginx
```

### 2. Ollama 插件安装失败

**问题描述**：无法安装 Ollama 插件，提示 "Failed to request plugin daemon"

**原因分析**：Plugin daemon 通信问题，可能是端口或代理配置错误

**解决方案**：
在 `.env` 文件中添加：
```env
PLUGIN_DAEMON_URL=http://plugin_daemon:5005
no_proxy=localhost,127.0.0.1,host.docker.internal,plugin_daemon,redis,db_postgres
NO_PROXY=localhost,127.0.0.1,host.docker.internal,plugin_daemon,redis,db_postgres
```

然后重启服务：
```bash
docker compose restart worker
```

### 3. Docker 端口冲突 (9091)

**问题描述**：`Bind for 0.0.0.0:9091 failed: port is already allocated`

**原因分析**：端口 9091 被其他服务占用

**解决方案**：
修改 `deploy/dify/docker/docker-compose.yaml` 中的 Milvus 配置：
```yaml
milvus:
  ports:
    - "19531:19530"  # 改为 19531
    - "9092:9091"    # 改为 9092
```

### 4. 文档索引错误 - Provider 不存在

**问题描述**：索引失败，提示 `Provider langgenius/ollama/ollama does not exist`

**原因分析**：Worker 服务代理配置未同步

**解决方案**：
在 `docker-compose.yaml` 的 worker 服务中添加：
```yaml
worker:
  environment:
    - no_proxy=localhost,127.0.0.1,host.docker.internal,plugin_daemon,redis,db_postgres,172.18.0.0/16
    - NO_PROXY=localhost,127.0.0.1,host.docker.internal,plugin_daemon,redis,db_postgres,172.18.0.0/16
```

### 5. Embedding 模型 context 太小

**问题描述**：索引失败，提示 embedding 模型 context 长度为 512，太小

**原因分析**：使用的 embedding 模型 context_length 为 512，但分段长度设置过大

**解决方案**：
在创建知识库时，将「最大分段长度」调整为 `500` 以内

### 6. 凭据名称不一致导致索引失败

**问题描述**：索引失败，提示 `Invalid credentials` 或模型无法调用

**原因分析**：在 Dify 中配置 Ollama 推理模型和 Embedding 模型时，使用了不同的凭据名称，导致某些模型无法正确调用

**解决方案**：
1. 在 Dify 的「设置」→「模型供应商」→「Ollama」中，确保所有模型使用相同的凭据名称
2. 建议统一使用 `ollama` 作为 API Key
3. 如果已存在不同凭据的模型，删除后重新添加

### 7. TypeError: object of type 'NoneType' has no len()

**问题描述**：文档索引时出现 `TypeError: object of type 'NoneType' has no len()` 错误

**原因分析**：Ollama 返回 None 嵌入向量时，代码未处理这种情况

**解决方案**：
本项目已通过自定义镜像修复此问题。修改的代码位于：
- `deploy/dify/patches/milvus/milvus_vector.py`
- `deploy/dify/patches/vdb/vector_factory.py`

如果需要重新构建镜像：
```bash
cd ~/rag-pkb/deploy/dify
docker build -t dify-api-custom:1.13.0 .
cd docker
docker compose up -d
```

### 8. 重启后代码修改丢失

**问题描述**：重启 Docker 容器后，修改的代码丢失

**原因分析**：代码修改是在容器内部进行的，未持久化

**解决方案**：
本项目已通过自定义镜像解决此问题。修改的代码已打包到 `dify-api-custom:1.13.0` 镜像中，重启容器后代码修改不会丢失。

如果需要添加新的代码修改：
1. 修改 `deploy/dify/patches/` 目录下的文件
2. 重新构建镜像：`docker build -t dify-api-custom:1.13.0 .`
3. 重启服务：`docker compose up -d`

### 9. 文档索引状态卡住

**问题描述**：文档一直处于 "indexing" 状态

**原因分析**：索引过程中出错但状态未更新

**解决方案**：
```sql
-- 重置文档状态
UPDATE documents 
SET indexing_status = 'waiting', error = NULL, stopped_at = NULL 
WHERE id = '文档ID';

-- 重置段落状态
UPDATE document_segments 
SET status = 'pending' 
WHERE dataset_id = '知识库ID' AND status = 'indexing';
```

### 10. 模型名称包含斜杠导致索引失败

**问题描述**：使用 `qllama/bge-large-zh-v1.5:q8_0` 模型时索引失败

**原因分析**：Dify 对模型名称中的斜杠有特殊处理

**解决方案**：
确保模型名称正确，Dify 会自动处理斜杠。如果仍有问题，检查模型是否正确下载：
```bash
ollama list
```

## 日志查看

### Dify 服务日志

```bash
# 进入 Dify Docker 目录
cd ~/rag-pkb/deploy/dify/docker

# 查看 API 服务日志
docker compose logs -f api

# 查看 Worker 服务日志
docker compose logs -f worker

# 查看 Web 服务日志
docker compose logs -f web

# 查看 Plugin daemon 日志
docker compose logs -f plugin_daemon
```

### Ollama 日志

```bash
# macOS 上查看 Ollama 日志
# 打开 Console.app → 系统日志 → 搜索 ollama
```

### 数据库日志

```bash
# 进入 PostgreSQL 容器
docker exec -it docker-db_postgres-1 psql -U postgres -d dify

# 查看最近的文档索引错误
SELECT id, name, indexing_status, error FROM documents WHERE error IS NOT NULL;
```

## 性能优化

### 1. Ollama 模型优化

```json
// config/ollama/config.json
{
  "num_gpu": 1,
  "metal": true,
  "num_ctx": 4096  // 增加上下文长度
}
```

### 2. Milvus 索引优化

根据数据特点调整索引参数：

```python
# 在 milvus_vector.py 中
index_params = {
    "metric_type": "IP",      # 内积相似度
    "index_type": "HNSW",     # HNSW 索引
    "params": {
        "M": 8,               # 内存使用参数
        "efConstruction": 64 # 建索引参数
    }
}
```

### 3. Dify Worker 并发优化

在 `.env` 文件中调整 worker 并发数：

```env
CELERY_WORKER_CONCURRENCY=4
```

### 4. 内存优化

如果内存不足，可以：
1. 使用更小的 embedding 模型
2. 减少并发索引的段落数量
3. 在 docker-compose.yaml 中限制容器内存

### 5. 独立向量库配置

为不同知识库配置独立向量模型的步骤：

1. 在创建知识库时，选择不同的 embedding 模型
2. Dify 会自动为每个知识库创建独立的 Milvus collection
3. Collection 命名格式：`Vector_index_{dataset_id}_Node`

验证独立向量库：
```sql
SELECT provider_name, model_name, collection_name 
FROM dataset_collection_bindings;
```

## 部署架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                         MacBook Air m4                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────┐    ┌─────────────────────────────────┐   │
│  │    Ollama        │    │       Docker Containers         │   │
│  │  (本地 LLM)      │    ├─────────────────────────────────┤   │
│  │  端口: 11434     │    │  ┌─────────┐  ┌──────────────┐  │   │
│  │                  │    │  │  Dify   │  │   Milvus     │  │   │
│  │  模型:           │    │  │  Web    │  │  向量库      │  │   │
│  │  - qwen3-4b      │    │  │  :80    │  │  :19530      │  │   │
│  │  - bge-large-zh  │    │  ├─────────┤  ├──────────────┤  │   │
│  │  - nomic-embed   │    │  │  API    │  │  PostgreSQL  │  │   │
│  │                  │    │  │  :5001  │  │  :5432       │  │   │
│  └──────────────────┘    │  ├─────────┤  ├──────────────┤  │   │
│                         │  │ Worker  │  │    Redis     │  │   │
│                         │  └─────────┘  │    :6379      │  │   │
│                         └─────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## 代码修改说明

本项目对 Dify 源码进行了以下修改，以解决特定问题：

### 修改文件

1. **milvus_vector.py** - Milvus 向量处理
   - 添加 None 嵌入过滤逻辑
   - 解决 "NoneType has no len()" 错误

2. **vector_factory.py** - 向量工厂
   - 添加 None 嵌入过滤逻辑
   - 统一向量处理流程

详细说明请参考：[deploy/dify/patches/README.md](deploy/dify/patches/README.md)

## 项目维护

### 更新 Dify 版本

1. 修改 `deploy/dify/Dockerfile` 中的基础镜像版本
2. 重新构建镜像：`docker build -t dify-api-custom:1.13.0 .`
3. 重启服务：`docker compose up -d`

### 备份数据

```bash
# 备份 PostgreSQL 数据
docker exec docker-db_postgres-1 pg_dump -U postgres dify > backup.sql

# 备份 Milvus 数据
docker cp dify-milvus-minio:/data ./milvus_backup
```

### 恢复数据

```bash
# 恢复 PostgreSQL 数据
docker exec -i docker-db_postgres-1 psql -U postgres dify < backup.sql

# 恢复 Milvus 数据
docker cp ./milvus_backup dify-milvus-minio:/data
```

## 参考资源

- [Dify 官方文档](https://docs.dify.ai)
- [Ollama 官方文档](https://ollama.com/docs)
- [Milvus 官方文档](https://milvus.io/docs)

## 许可证

本项目遵循 MIT 许可证。

---

如有任何问题，请参考常见问题章节或查看详细日志进行排查。
