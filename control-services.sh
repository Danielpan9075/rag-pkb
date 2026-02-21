#!/bin/bash

echo "===================================="
echo "  RAG 知识库服务控制"
echo "===================================="
echo ""

# 检查服务状态
echo "检查服务状态..."
echo ""

milvus_running=$(curl -s http://localhost:19530/v1/healthz 2>&1)
ollama_running=$(curl -s http://localhost:11434/api/tags 2>&1 | head -1)
dify_running=$(curl -s -I http://localhost 2>&1 | head -1)

echo "Milvus: $milvus_running"
echo "Ollama: $ollama_running"
echo "Dify: $dify_running"
echo ""

# 判断是否所有服务都在运行
if [[ -n "$milvus_running" && -n "$ollama_running" && -n "$dify_running" ]]; then
    echo "===================================="
    echo "  🔴 关闭所有服务"
    echo "===================================="
    echo ""
    
    # 关闭 Dify（包含 Milvus）
    echo "[1/2] 关闭 Dify（包含 Milvus）..."
    cd ~/rag-pkb/deploy/dify/docker && docker compose down
    echo "  ✅ Dify 已关闭"
    echo ""
    
    # 关闭 Ollama
    echo "[2/2] 关闭 Ollama..."
    pkill -f ollama
    echo "  ✅ Ollama 已关闭"
    echo ""
    
    echo "===================================="
    echo "  🌙 所有服务已关闭"
    echo "===================================="
    
else
    echo "===================================="
    echo "  🟢 启动所有服务"
    echo "===================================="
    echo ""
    
    # 启动 Ollama
    echo "[1/2] 启动 Ollama..."
    if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        nohup ollama serve > /tmp/ollama.log 2>&1 &
    fi
    echo "  ⏳ 等待 Ollama 初始化..."
    sleep 8
    echo "  ✅ Ollama 已启动"
    echo ""
    
    # 启动 Dify（包含 Milvus）
    echo "[2/2] 启动 Dify（包含 Milvus）..."
    cd ~/rag-pkb/deploy/dify/docker && docker compose up -d
    echo "  ⏳ 等待 Dify 初始化..."
    sleep 35
    echo "  ✅ Dify 已启动"
    echo ""
    
    echo "===================================="
    echo "  🎉 所有服务已启动"
    echo "===================================="
    echo ""
    echo "访问 http://localhost 使用 Dify"
    echo ""
    
    # 自动打开 Safari
    echo "自动打开 Safari 浏览器..."
    open -a Safari http://localhost
    echo "  ✅ Safari 已打开"
    echo ""
fi

echo "按任意键退出..."
read -n 1 -s
