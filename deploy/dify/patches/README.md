# Dify 代码修改补丁

本目录包含对 Dify 源码的修改，用于解决特定问题并优化功能。

## 修改概述

### 修改目的

本项目对 Dify 进行了以下修改，主要解决 Ollama 返回 None 嵌入向量时导致的索引失败问题：

1. **TypeError: object of type 'NoneType' has no len()** - 文档索引时出现错误
2. **代码修改持久化** - 确保重启容器后修改不丢失

### 修改策略

通过构建自定义 Docker 镜像将修改打包，避免使用 Volume 挂载带来的复杂性和模块缺失问题。

## 修改文件

### 1. milvus/milvus_vector.py

**文件路径**: `api/core/rag/datasource/vdb/milvus/milvus_vector.py`

**修改内容**:

在 `create()` 方法中添加 None 嵌入过滤逻辑：

```python
# 过滤 None 嵌入
filtered_texts = []
filtered_embeddings = []
for text, emb in zip(texts, embeddings):
    if emb is not None:
        filtered_texts.append(text)
        filtered_embeddings.append(emb)

if not filtered_texts:
    logger.warning("No valid embeddings found, skipping collection creation")
    return
```

**修改位置**:
- `create()` 方法 - 创建向量集合时过滤 None 嵌入
- `add_texts()` 方法 - 添加文本时过滤 None 嵌入
- `_create_collection()` 方法 - 创建集合时过滤 None 嵌入

### 2. vdb/vector_factory.py

**文件路径**: `api/core/rag/datasource/vdb/vector_factory.py`

**修改内容**:

在向量生成和过滤逻辑中添加 None 检查：

```python
# 过滤 None 嵌入
filtered_embeddings = [emb for emb in embeddings if emb is not None]
if not filtered_embeddings:
    logger.warning("No valid embeddings found, skipping collection creation")
    return
```

**修改位置**:
- 向量生成后的过滤逻辑
- 批量处理时的 None 检查

## 问题背景

### 原始问题

在使用 Ollama 作为 Embedding 模型时，偶尔会出现以下错误：

```
TypeError: object of type 'NoneType' has no len()
```

**错误原因**:
- Ollama 在某些情况下返回 None 作为嵌入向量
- Dify 原始代码未处理这种情况
- 导致索引过程中断

### 影响范围

- 文档索引失败
- 知识库无法正常使用
- 需要手动重置文档状态

## 部署方式

### 构建自定义镜像

```bash
# 进入 Dify 部署目录
cd ~/rag-pkb/deploy/dify

# 构建自定义镜像
docker build -t dify-api-custom:1.13.0 .
```

### 使用自定义镜像

修改 `docker/docker-compose.yaml`，将以下服务的镜像改为自定义镜像：

```yaml
services:
  api:
    image: dify-api-custom:1.13.0
  
  worker:
    image: dify-api-custom:1.13.0
  
  worker_beat:
    image: dify-api-custom:1.13.0
```

### 启动服务

```bash
# 进入 Docker 目录
cd ~/rag-pkb/deploy/dify/docker

# 启动服务
docker compose up -d
```

## 验证修改

### 检查代码是否生效

```bash
# 检查 API 容器中的代码
docker exec docker-api-1 grep -A 3 "if emb is not None" /app/api/core/rag/datasource/vdb/milvus/milvus_vector.py

# 应该看到类似输出：
# if emb is not None:
#     filtered_texts.append(text)
#     filtered_embeddings.append(emb)
```

### 测试索引功能

1. 在 Dify 中创建知识库
2. 上传文档进行索引
3. 检查是否还会出现 "NoneType has no len()" 错误

## 更新和维护

### 添加新的代码修改

1. 在对应的 `patches/` 子目录中修改文件
2. 重新构建镜像：`docker build -t dify-api-custom:1.13.0 .`
3. 重启服务：`docker compose up -d`

### 更新 Dify 版本

1. 修改 `Dockerfile` 中的基础镜像版本
2. 检查代码修改是否与新版本兼容
3. 重新构建镜像
4. 测试功能是否正常

## 技术细节

### 为什么使用自定义镜像而不是 Volume 挂载？

**Volume 挂载的问题**:
- 容易导致模块缺失（如 `ModuleNotFoundError: No module named 'core.logging'`）
- 需要挂载完整的目录结构
- 难以维护和迁移

**自定义镜像的优势**:
- 代码修改永久保存在镜像中
- 重启容器后修改不丢失
- 易于部署和迁移
- 避免模块缺失问题

### 修改的影响范围

- 仅影响 Milvus 向量处理逻辑
- 不影响其他向量数据库（如 Weaviate、Qdrant）
- 不影响 Dify 的核心功能

## 参考资源

- [Dify 官方文档](https://docs.dify.ai)
- [Milvus 官方文档](https://milvus.io/docs)
- [Ollama 官方文档](https://ollama.com/docs)

## 版本历史

| 版本 | 日期 | 修改内容 |
|------|------|----------|
| 1.0.0 | 2026-02-21 | 初始版本，添加 None 嵌入过滤逻辑 |

---

如有问题或建议，请参考主项目 README.md 或提交 Issue。
