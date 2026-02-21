#!/bin/bash
echo "重启 Ollama 服务..."
ollama restart
echo "验证 Metal 加速配置..."
ollama info kamekichi128/qwen3-4b-instruct-2507:latest
