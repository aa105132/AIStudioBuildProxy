#!/bin/bash

# 1. 修改 config.yaml
# 使用 sed 将 enableServerPlugins: false 替换为 true
# 兼容 Linux 和 macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS 需要一个空字符串作为备份后缀
    sed -i '' 's/enableServerPlugins: false/enableServerPlugins: true/g' config.yaml
else
    # Linux 标准写法
    sed -i 's/enableServerPlugins: false/enableServerPlugins: true/g' config.yaml
fi
echo "Config updated."

# 2. 进入 plugins 目录并克隆 server 分支
if [ -d "plugins" ]; then
    cd plugins
    echo "Cloning server plugin..."
    git clone -b server https://github.com/starowo/AIStudioBuildProxy.git
else
    echo "Error: Directory 'plugins' not found."
    exit 1
fi

# 3. 进入 ../public/scripts/extensions/third-party 并克隆 client 分支
# 从 plugins 目录往回退一级再进入目标目录
TARGET_DIR="../public/scripts/extensions/third-party"

if [ -d "$TARGET_DIR" ]; then
    cd "$TARGET_DIR"
    echo "Cloning client extension..."
    git clone -b client https://github.com/starowo/AIStudioBuildProxy.git
else
    echo "Error: Directory '$TARGET_DIR' not found."
    exit 1
fi

echo "Done!"