#!/bin/bash

# 定义主题路径
LIGHT_THEME="$HOME/.config/kitty/themes/Light_Default.conf"
DARK_THEME="$HOME/.config/kitty/Default.conf"

# 函数：查找所有活动的 kitty socket 并发送指令
function update_all_kitties() {
    local THEME_FILE=$1

    # 1. 从 /proc/net/unix 中查找所有包含 "mykitty" 的抽象套接字
    # 2. 使用 grep -o 提取以 @ 开头的部分
    # 3. 循环对每一个 socket 发送指令
    grep -aPo '@mykitty[^\s]*' /proc/net/unix | sort | uniq | while read -r socket_path; do
        # 注意：/proc/net/unix 输出的 @ 对应 abstract socket
        kitty @ --to "unix:$socket_path" set-colors --all --configured "$THEME_FILE" 2>/dev/null
    done
}


# 获取当前系统模式
current_mode=$(gsettings get org.gnome.desktop.interface color-scheme)

# 初始化设置
if [[ "$current_mode" == "'prefer-dark'" ]]; then
    update_all_kitties "$DARK_THEME"
else
    update_all_kitties "$LIGHT_THEME"
fi

# 监听变化
gsettings monitor org.gnome.desktop.interface color-scheme | while read -r line; do
    if [[ "$line" == *"prefer-dark"* ]]; then
        update_all_kitties "$DARK_THEME"
    else
        update_all_kitties "$LIGHT_THEME"
    fi
done

