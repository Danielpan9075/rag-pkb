import os
import re

def search_code_snippets(folder_path, keyword):
    """检索指定文件夹下的代码片段"""
    result = []
    for root, dirs, files in os.walk(folder_path):
        for file in files:
            if file.endswith(('.py', '.js', '.java')):
                file_path = os.path.join(root, file)
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    if keyword in content:
                        func_pattern = r'def\s+(\w+)\('
                        funcs = re.findall(func_pattern, content)
                        result.append({
                            "file": file_path,
                            "functions": funcs,
                            "snippet": content[:500]
                        })
    return result

if __name__ == "__main__":
    print(search_code_snippets("./my_code", "快速排序"))
