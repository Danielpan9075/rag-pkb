# Enterprise-Grade RAG Personal Knowledge Base

## Project Overview

This project builds an enterprise-grade RAG (Retrieval-Augmented Generation) personal knowledge base using Dify + Ollama + Milvus technology stack. The knowledge base supports local deployment, protects data privacy, and provides enterprise-level vector retrieval capabilities.

**Core Features:**
- Local Large Language Model inference (Ollama)
- Visual RAG platform (Dify)
- Enterprise-grade vector database (Milvus)
- Multi-knowledge base support, each with independent vector model configuration

## Project Structure

```
rag-pkb/
├── README.md                      # Project documentation (English)
├── README_zh.md                  # Project documentation (Chinese)
├── control-services.sh             # Service control script
├── config/                        # Configuration directory
│   └── ollama/                   # Ollama model configuration
├── data/                          # Data directory
│   ├── code_repo/                # Code repository
│   └── knowledge_base/           # Knowledge base files
├── deploy/                       # Deployment directory
│   └── dify/                     # Dify platform
│       ├── Dockerfile            # Custom image build file
│       ├── patches/              # Code modification patches
│       │   ├── milvus/
│       │   │   └── milvus_vector.py
│       │   └── vdb/
│       │       └── vector_factory.py
│       └── docker/               # Docker configuration
│           ├── .env             # Dify environment variables
│           ├── docker-compose.yaml
│           └── volumes/         # Data volumes
├── docs/                         # Documentation directory
├── logs/                         # Log directory
├── plugins/                      # Plugin directory
└── scripts/                      # Script directory
```

## Tech Stack

| Component | Purpose | Port |
|-----------|----------|-------|
| **Dify** | Visual RAG platform | 80 (Web), 5001 (API) |
| **Ollama** | Local LLM engine | 11434 |
| **Milvus** | Vector database (built-in Dify) | 19530, 9091 |
| **PostgreSQL** | Dify database | 5432 |
| **Redis** | Dify cache | 6379 |

### Models Used

- **Inference Model**: `qwen3-4b-instruct-2507:latest`
- **Chinese Embedding Model**: `bge-large-zh-v1.5:q8_0`
- **English Embedding Model**: `nomic-embed-text:v1.5`

## Environment Setup

### Hardware Requirements

| Item | Minimum | Recommended |
|-------|----------|-------------|
| Device | MacBook Air M2 16G | MacBook Air M4 24G |
| Memory | 16GB | 24GB |
| Storage | 50GB available space | 100GB SSD |
| GPU | Integrated GPU | Powerful GPU acceleration |

### Software Dependencies

| Software | Version | Installation |
|----------|----------|---------------|
| **Docker Desktop** | Latest | [Docker Website](https://www.docker.com/products/docker-desktop) |
| **Ollama** | Latest | [Ollama Website](https://ollama.com/download) |
| **Git** | Any version | Homebrew: `brew install git` |

### macOS System Proxy Notes

**Important**: If system proxy software (e.g., ClashX, Surge) is enabled, it may cause Docker container network issues.

**Solution**:
1. Add `no_proxy` environment variable in Docker Compose configuration
2. Or exclude Docker internal network in system proxy: `localhost,127.0.0.1,host.docker.internal,172.18.0.0/16`

## Deployment Steps

### Step 1: Start Ollama and Download Models

```bash
# Start Ollama service
ollama serve

# Download inference model
ollama pull qwen3-4b-instruct-2507:latest

# Download Chinese embedding model
ollama pull bge-large-zh-v1.5:q8_0

# Download English embedding model
ollama pull nomic-embed-text:v1.5

# Verify model list
ollama list
```

### Step 2: Build Custom Dify Image

```bash
# Enter Dify deployment directory
cd ~/rag-pkb/deploy/dify

# Build custom image (includes code modifications)
docker build -t dify-api-custom:1.13.0 .
```

### Step 3: Configure Dify Environment Variables

```bash
# Enter Dify configuration directory
cd ~/rag-pkb/deploy/dify/docker

# Copy environment variables file
cp .env.example .env
```

Edit `.env` file and configure the following:

```env
# ==================== Vector Store Configuration ====================
VECTOR_STORE=milvus
MILVUS_URI=http://host.docker.internal:19530
MILVUS_USER=root
MILVUS_PASSWORD=your_password_here

# ==================== Ollama Configuration ====================
# Note: Use host.docker.internal to access host Ollama
OLLAMA_BASE_URL=http://host.docker.internal:11434

# ==================== Proxy Configuration (Important) ====================
# If system proxy is enabled, add the following to avoid container network issues
no_proxy=localhost,127.0.0.1,host.docker.internal,plugin_daemon,redis,db_postgres,172.18.0.0/16
NO_PROXY=localhost,127.0.0.1,host.docker.internal,plugin_daemon,redis,db_postgres,172.18.0.0/16
```

### Step 4: Start Dify Services

```bash
# Enter Dify Docker directory
cd ~/rag-pkb/deploy/dify/docker

# Start all Dify services
docker compose up -d

# Wait for services to start (about 1-2 minutes)
docker compose ps

# View service logs
docker compose logs -f
```

**Verify Dify startup success:**
- Visit http://localhost should see Dify login page
- If inaccessible, check logs: `docker compose logs web`

### Step 5: Configure Ollama Plugin

1. Visit Dify Web interface (http://localhost)
2. Go to "Settings" → "Model Providers"
3. Click "Add Model Provider" → Select "Ollama"
4. Configure:
   - URL: `http://host.docker.internal:11434`
5. Add models:
   - Inference model: Select Ollama → Add `qwen3-4b-instruct-2507:latest`
   - Embedding model: Add `bge-large-zh-v1.5:q8_0` and `nomic-embed-text:v1.5`

### Step 6: Create Knowledge Base

1. Click "Knowledge Base" → "Create Knowledge Base"
2. Fill in knowledge base name (e.g., "Novel Writing")
3. Configure vector model:
   - Select "Milvus"
   - Select embedding model (e.g., `bge-large-zh-v1.5:q8_0`)
4. Configure indexing method:
   - Recommended delimiter: `<<<`
   - Max segment length: `2000`
   - Other segment length: `500`

### Step 7: Upload Documents and Test

1. Click "Upload Document" in knowledge base
2. Wait for document processing to complete
3. Create application in Dify and link knowledge base
4. Test Q&A functionality

## Verification

### Service Status Check

```bash
# Check all Docker container status
docker ps

# Check Milvus health status
curl -s http://localhost:19530/v1/healthz

# Check Ollama service
curl -s http://localhost:11434/api/tags
```

### Database Status Check

```bash
# Enter Dify database container
docker exec -it docker-db_postgres-1 psql -U postgres -d dify

# View knowledge base list
SELECT id, name, created_at FROM datasets;

# View vector collection bindings
SELECT provider_name, model_name, collection_name FROM dataset_collection_bindings;

# View document indexing status
SELECT id, name, indexing_status, error FROM documents;
```

### Test RAG Functionality

1. Create "Blank Application" or "Knowledge Base Assistant" application
2. Link created knowledge base
3. Enter test question to verify if answer is based on knowledge base content

## Common Commands

### Dify Service List

| Service Name | Purpose | Port | Container Name |
|--------------|----------|-------|----------------|
| **api** | Dify backend API service | 5001 | docker-api-1 |
| **worker** | Celery task queue processing | 5001 | docker-worker-1 |
| **worker_beat** | Celery scheduled task scheduling | 5001 | docker-worker_beat-1 |
| **web** | Dify frontend Web interface | 3000 | docker-web-1 |
| **nginx** | Reverse proxy server | 80, 443 | docker-nginx-1 |
| **db_postgres** | PostgreSQL database | 5432 | docker-db_postgres-1 |
| **redis** | Redis cache service | 6379 | docker-redis-1 |
| **plugin_daemon** | Plugin daemon process | 5004 | docker-plugin_daemon-1 |
| **sandbox** | Sandbox environment | - | docker-sandbox-1 |
| **ssrf_proxy** | SSRF proxy | 3128 | docker-ssrf_proxy-1 |
| **milvus-standalone** | Milvus vector database | 19530 | dify-milvus-standalone |
| **milvus-etcd** | Milvus etcd storage | 2379 | dify-milvus-etcd |
| **milvus-minio** | Milvus object storage | 9000 | dify-milvus-minio |

### Docker Service Management Commands

```bash
# Enter Dify Docker directory
cd ~/rag-pkb/deploy/dify/docker

# Start all services
docker compose up -d

# Stop all services
docker compose stop

# Restart all services
docker compose restart

# Restart specific service (e.g., api and worker)
docker compose restart api worker

# Restart nginx
docker compose restart nginx

# View all service status
docker compose ps

# View service logs
docker compose logs -f

# View specific service logs
docker compose logs -f api
docker compose logs -f worker
docker compose logs -f nginx

# View recent service logs
docker logs docker-api-1 --tail 50
docker logs docker-worker-1 --tail 50
docker logs docker-nginx-1 --tail 50

# Enter service container
docker exec -it docker-api-1 bash
docker exec -it docker-worker-1 bash
docker exec -it docker-db_postgres-1 psql -U postgres -d dify

# Stop and delete all services
docker compose down

# Stop and delete all services and data volumes
docker compose down -v
```

### Ollama Common Commands

```bash
# Start Ollama service
ollama serve

# View installed model list
ollama list

# Download model
ollama pull <model_name>

# Download inference model
ollama pull qwen3-4b-instruct-2507:latest

# Download Chinese embedding model
ollama pull bge-large-zh-v1.5:q8_0

# Download English embedding model
ollama pull nomic-embed-text:v1.5

# Run model for testing
ollama run <model_name>

# Run inference model test
ollama run qwen3-4b-instruct-2507:latest

# View model information
ollama show <model_name>

# Delete model
ollama rm <model_name>

# View model version information
ollama show --modelfile <model_name>

# View model running status
ollama ps

# Check Ollama service status
curl -s http://localhost:11434/api/tags
```

### Database Query Commands

```bash
# Enter Dify database
docker exec -it docker-db_postgres-1 psql -U postgres -d dify

# View all knowledge bases
SELECT id, name, created_at FROM datasets;

# View vector collection bindings
SELECT provider_name, model_name, collection_name FROM dataset_collection_bindings;

# View document indexing status
SELECT id, name, indexing_status, error FROM documents;

# View document segment status
SELECT COUNT(*), status FROM document_segments GROUP BY status;

# Reset document status
UPDATE documents 
SET indexing_status = 'waiting', error = NULL, stopped_at = NULL 
WHERE id = 'document_id';

# Reset segment status
UPDATE document_segments 
SET status = 'pending' 
WHERE dataset_id = 'knowledge_base_id' AND status = 'indexing';

# Exit database
\q
```

### System Service Check Commands

```bash
# Check all Docker container status
docker ps -a

# Check container resource usage
docker stats

# View container details
docker inspect <container_name>

# View container logs
docker logs <container_name>

# View container port mapping
docker port <container_name>

# Clean unused Docker resources
docker system prune

# View disk usage
docker system df
```

### One-Click Start/Stop Services

```bash
# Use macOS application
# Double-click RAG服务开关.app to start/stop all services with one click

# Or use script
./control-services.sh
```

## Common Issues and Solutions

### 1. Dify Internal Server Error (502 Bad Gateway)

**Problem**: 502 error when accessing Dify Web interface

**Cause**:
- Plugin daemon service not started properly
- Port mapping configuration error

**Solution**:
```bash
# Check plugin_daemon service status
docker compose logs plugin_daemon

# Restart nginx service
docker compose restart nginx
```

### 2. Ollama Plugin Installation Failed

**Problem**: Cannot install Ollama plugin, "Failed to request plugin daemon"

**Cause**: Plugin daemon communication issue, possibly port or proxy configuration error

**Solution**:
Add to `.env` file:
```env
PLUGIN_DAEMON_URL=http://plugin_daemon:5005
no_proxy=localhost,127.0.0.1,host.docker.internal,plugin_daemon,redis,db_postgres
NO_PROXY=localhost,127.0.0.1,host.docker.internal,plugin_daemon,redis,db_postgres
```

Then restart service:
```bash
docker compose restart worker
```

### 3. Docker Port Conflict (9091)

**Problem**: `Bind for 0.0.0.0:9091 failed: port is already allocated`

**Cause**: Port 9091 is occupied by another service

**Solution**:
Modify Milvus configuration in `deploy/dify/docker/docker-compose.yaml`:
```yaml
milvus:
  ports:
    - "19531:19530"  # Change to 19531
    - "9092:9091"    # Change to 9092
```

### 4. Document Indexing Error - Provider Not Exist

**Problem**: Indexing failed, `Provider langgenius/ollama/ollama does not exist`

**Cause**: Worker service proxy configuration not synchronized

**Solution**:
Add to worker service in `docker-compose.yaml`:
```yaml
worker:
  environment:
    - no_proxy=localhost,127.0.0.1,host.docker.internal,plugin_daemon,redis,db_postgres,172.18.0.0/16
    - NO_PROXY=localhost,127.0.0.1,host.docker.internal,plugin_daemon,redis,db_postgres,172.18.0.0/16
```

### 5. Embedding Model Context Too Small

**Problem**: Indexing failed, embedding model context length is 512, too small

**Cause**: The embedding model's context_length is 512, but segment length is set too large

**Solution**:
When creating knowledge base, adjust "Max Segment Length" to within `500`

### 6. Credential Name Inconsistent Causing Indexing Failure

**Problem**: Indexing failed, `Invalid credentials` or model cannot be called

**Cause**: When configuring Ollama inference model and Embedding model in Dify, different credential names are used, causing some models to fail to call correctly

**Solution**:
1. In Dify "Settings" → "Model Providers" → "Ollama", ensure all models use the same credential name
2. Recommend using `ollama` as API Key
3. If models with different credentials already exist, delete and re-add

### 7. TypeError: object of type 'NoneType' has no len()

**Problem**: `TypeError: object of type 'NoneType' has no len()` error during document indexing

**Cause**: Ollama returns None embedding vector, code does not handle this case

**Solution**:
This project has fixed this issue through custom image. Modified code is located at:
- `deploy/dify/patches/milvus/milvus_vector.py`
- `deploy/dify/patches/vdb/vector_factory.py`

If you need to rebuild the image:
```bash
cd ~/rag-pkb/deploy/dify
docker build -t dify-api-custom:1.13.0 .
cd docker
docker compose up -d
```

### 8. Code Modifications Lost After Restart

**Problem**: Code modifications lost after restarting Docker container

**Cause**: Code modifications were made inside the container and not persisted

**Solution**:
This project has solved this issue through custom image. Modified code has been packaged into `dify-api-custom:1.13.0` image, code modifications will not be lost after restarting container.

If you need to add new code modifications:
1. Modify files in `deploy/dify/patches/` directory
2. Rebuild image: `docker build -t dify-api-custom:1.13.0 .`
3. Restart service: `docker compose up -d`

### 9. Document Indexing Status Stuck

**Problem**: Document always in "indexing" status

**Cause**: Error during indexing but status not updated

**Solution**:
```sql
-- Reset document status
UPDATE documents 
SET indexing_status = 'waiting', error = NULL, stopped_at = NULL 
WHERE id = 'document_id';

-- Reset segment status
UPDATE document_segments 
SET status = 'pending' 
WHERE dataset_id = 'knowledge_base_id' AND status = 'indexing';
```

### 10. Model Name Contains Slash Causing Indexing Failure

**Problem**: Using `qllama/bge-large-zh-v1.5:q8_0` model causes indexing failure

**Cause**: Dify has special handling for slashes in model names

**Solution**:
Ensure model name is correct, Dify will automatically handle slashes. If problem persists, check if model is downloaded correctly:
```bash
ollama list
```

## Log Viewing

### Dify Service Logs

```bash
# Enter Dify Docker directory
cd ~/rag-pkb/deploy/dify/docker

# View API service logs
docker compose logs -f api

# View Worker service logs
docker compose logs -f worker

# View Web service logs
docker compose logs -f web

# View Plugin daemon logs
docker compose logs -f plugin_daemon
```

### Ollama Logs

```bash
# View Ollama logs on macOS
# Open Console.app → System Logs → Search ollama
```

### Database Logs

```bash
# Enter PostgreSQL container
docker exec -it docker-db_postgres-1 psql -U postgres -d dify

# View recent document indexing errors
SELECT id, name, indexing_status, error FROM documents WHERE error IS NOT NULL;
```

## Performance Optimization

### 1. Ollama Model Optimization

```json
// config/ollama/config.json
{
  "num_gpu": 1,
  "metal": true,
  "num_ctx": 4096  // Increase context length
}
```

### 2. Milvus Index Optimization

Adjust index parameters based on data characteristics:

```python
# In milvus_vector.py
index_params = {
    "metric_type": "IP",      # Inner product similarity
    "index_type": "HNSW",     # HNSW index
    "params": {
        "M": 8,               # Memory usage parameter
        "efConstruction": 64 # Index building parameter
    }
}
```

### 3. Dify Worker Concurrency Optimization

Adjust worker concurrency in `.env` file:

```env
CELERY_WORKER_CONCURRENCY=4
```

### 4. Memory Optimization

If memory is insufficient, you can:
1. Use smaller embedding models
2. Reduce the number of concurrently indexed segments
3. Limit container memory in docker-compose.yaml

### 5. Independent Vector Database Configuration

Steps to configure independent vector models for different knowledge bases:

1. When creating knowledge base, select different embedding models
2. Dify will automatically create independent Milvus collections for each knowledge base
3. Collection naming format: `Vector_index_{dataset_id}_Node`

Verify independent vector databases:
```sql
SELECT provider_name, model_name, collection_name 
FROM dataset_collection_bindings;
```

## Deployment Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         MacBook Air m4                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────┐    ┌─────────────────────────────────┐   │
│  │    Ollama        │    │       Docker Containers         │   │
│  │  (Local LLM)     │    ├─────────────────────────────────┤   │
│  │  Port: 11434     │    │  ┌─────────┐  ┌──────────────┐  │   │
│  │                  │    │  │  Dify   │  │   Milvus     │  │   │
│  │  Models:         │    │  │  Web    │  │  Vector DB   │  │   │
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

## Code Modifications

This project has made the following modifications to Dify source code to solve specific problems:

### Modified Files

1. **milvus_vector.py** - Milvus vector processing
   - Added None embedding filtering logic
   - Solved "NoneType has no len()" error

2. **vector_factory.py** - Vector factory
   - Added None embedding filtering logic
   - Unified vector processing flow

For details, see: [deploy/dify/patches/README.md](deploy/dify/patches/README.md)

## License

This project is open source and available under the same license as Dify.

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## Acknowledgments

- [Dify](https://github.com/langgenius/dify) - Open source LLM application development platform
- [Ollama](https://ollama.com) - Run large language models locally
- [Milvus](https://milvus.io) - Open-source vector database

---

For Chinese documentation, see [README_zh.md](README_zh.md)
