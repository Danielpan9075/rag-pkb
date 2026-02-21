#!/bin/bash
echo "=== 检查 Ollama 状态 ==="
curl -s http://localhost:11434/api/tags || echo "Ollama 未启动"

echo -e "\n=== 检查 Milvus 容器 ==="
docker ps | grep milvus || echo "Milvus 容器未运行"

echo -e "\n=== 检查 Dify 状态 ==="
curl -s http://localhost:8000 || echo "Dify 未启动"
