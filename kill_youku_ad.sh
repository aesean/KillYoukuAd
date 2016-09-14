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
os=`uname`
# 不同的操作系统Chrome配置文件路径不同，这里判断Linux和Mac，然后取不同的配置路径。shell的变量作用域是全局的，所以这里可以在case里面定义prefixPath
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

# 这里主要是避免文件夹名称带有空格，被forin分割的情况。
IFS=$(echo -en "\n\b")
cd $prefixPath
# 纪录下当前路径，待会儿需要切换回来
currentDir=`pwd`
# 这里默认处理Default文件夹就可以了，但是如果Chrome浏览器有登录Google帐号，而且帐号不止一个，这里就需要处理类似Profile 1，Profile 2等目录了。
for dir in `ls . | grep -E "Default|Profile"`
do
    # 如果存在类似Peppre Data这样的子目录，则基本判定是我们需要处理的目录。
    if [[ -d "./$dir/Pepper Data/Shockwave Flash/WritableRoot/#SharedObjects/" ]]; then
        cd "./$dir/Pepper Data/Shockwave Flash/WritableRoot/#SharedObjects/"
        # 这里需要在当前目录的所有子目录里创建文件：static.youku.com
        # 这里做遍历主要是实际测试，这里的子目录名称不确定，所以这里就比较暴力的遍历处理所有子目录。
        for l in `ls .`
        do
            rm -rf "./$l/static.youku.com"
            if [ $? -eq 0 ]; then
                echo "删除Chrome配置文件：static.youku.com，成功"
            else
                echo -e "\033[31m删除失败！\033[0m"
                echo "`pwd`/$l/static.youku.com"
                echo -e "\033[31m禁用优酷广告失败！\033[0m"
                exit 3
            fi
            echo "创建空文件：static.youku.com"
            touch "./$l/static.youku.com"
            # 添加只读权限，防止死灰复燃
            chmod 400 "./$l/static.youku.com"
            echo "创建成功"
        done
    fi
    cd $currentDir
done

echo "开始禁用Youku广告服务器地址"
hosts=`cat /etc/hosts`
# 添加flag，标记自己添加的东西，方便做重复判断和后续删除。
result=$(echo $hosts | grep "#禁用优酷广告服务器Start"  | grep "#禁用优酷广告服务器End")
if [[ "$result" != "" ]]; then
    echo "已禁用优酷广告服务器，无需重复禁用"
else
    if [ $UID -ne 0 ]; then
        if [ !`expect -c 'set timeout 1; spawn sudo date; expect "assword" { exit 3; } interact' > /dev/null 2>&1` ]; then
            echo -e "\033[31m需要超级用户权限修改本地hosts文件，请输入操作系统登录密码。注意输入密码的时候，输入的字符是不会显示的，也不会显示星号。如果想要直接退出请按:Ctrl+C\033[0m"
        fi 
    fi
    # hosts需要su权限
    sudo bash -c 'echo "
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
" >> /etc/hosts'
    if [ $? -ne 0 ]; then
        echo -e "\033[31m禁用广告服务器失败！\033[0m"
        exit 6
    else
        echo "禁用广告服务器成功"
    fi
fi

echo -e "\033[32m所有操作完成，优酷广告已被清除。请打开Chrome测试效果。\033[0m"
exit 0