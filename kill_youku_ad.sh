#!/bin/bash
# 使用方法非常简单
# 首先给当前文件添加执行权限，打开终端,cd 到当前文件所在文件夹，然后输入:chmod a+x kill_youku_ad.sh 给当前文件添加执行权限
# 然后：sudo ./kill_youku_ad.sh 执行这个文件就可以了。
# 
# 整个原理非常简单，原始地址已经失效，可以参考这个转载：http://blogread.cn/it/article/6189?f=wb#original
# 看着脚本似乎很长，其实整个脚本只做了两步操作
# 1. 删除Chrome下的static.youku.com文件，然后用一个空文件替代。
# 2. 向hosts文件添加优酷广告服务器地址，并指向127.0.0.1
# 仅支持Linux和macOS
# Chrome 53 64位 macOS测试通过
if [ $UID -ne 0 ]; then
    echo -e "\033[31m失败！\033[0m需要超级用户权限，请在命令前加：\033[32msudo。\033[0m"
    echo -e "例如： \"\033[32msudo $0\033[0m\""
    exit 1
fi

os=`uname`
case $os in
    "Linux")
        prefixPath="$HOME/.config/google-chrome/"
        ;;
    "Darwin")
        prefixPath="$HOME/Library/Application Support/Google/Chrome/"
        ;;
    *)
        echo -e "\033[31m当前操作系统为：$os\033[0m"
        echo -e "\033[31m不支持的操作系统，仅支持Linux和Mac操作系统\033[0m"
        exit 2
        ;;
esac

IFS=$(echo -en "\n\b")
for dir in `ls $prefixPath | grep -E "Default|Profile"`
do
    if [[ -d "$prefixPath$dir/Pepper Data/Shockwave Flash/WritableRoot/#SharedObjects/" ]]; then
        findFile="$prefixPath$dir/Pepper Data/Shockwave Flash/WritableRoot/#SharedObjects/static.youku.com"
        if [ -f $findFile ]; then
            echo "发现static.youku.com文件"
            echo "开始删除Chrome配置文件：static.youku.com"
            # echo $findFile
            rm -rf "$findFile"
            if [ $? -eq 0 ]; then
                echo "删除成功"
            else
                echo -e "\033[31m删除失败！\033[0m"
                echo $findFile
                echo -e "\033[31m禁用优酷广告失败！\033[0m"
                exit 3
            fi
        fi
        echo "创建空文件：static.youku.com"
        touch "$findFile"
        echo "创建成功"
    fi
done

echo "开始禁用Youku广告服务器地址"
hosts=`cat /etc/hosts`
result=$(echo $hosts | grep "#禁用优酷广告服务器Start"  | grep "#禁用优酷广告服务器End")
if [[ "$result" != "" ]]; then
    echo "已禁用优酷广告服务器，无需重复禁用"
else
    echo "
#禁用优酷广告服务器Start
127.0.0.1       atm.youku.com
127.0.0.1       fvid.atm.youku.com
127.0.0.1       html.atm.youku.com
127.0.0.1       valb.atm.youku.com
127.0.0.1       valc.atm.youku.com
127.0.0.1       valf.atm.youku.com
127.0.0.1       valo.atm.youku.com
127.0.0.1       valp.atm.youku.com
127.0.0.1       vid.atm.youku.com
127.0.0.1       walp.atm.youku.com
127.0.0.1       lstat.youku.com
127.0.0.1       speed.lstat.youku.com
127.0.0.1       static.lstat.youku.com
127.0.0.1       urchin.lstat.youku.com
127.0.0.1       stat.youku.com
#禁用优酷广告服务器End
" >> /etc/hosts
    echo "禁用广告服务器成功"
fi

echo -e "\033[32m所有操作完成，优酷广告已被清除。请打开Chrome测试效果。\033[0m"