#! /bin/bash
#
# 文档说明： https://www.showdoc.cc/page/741656402509783
#
api_key="3908ec22d46f39acfaefa57c749f6a8c1922149318"  #api_key
api_token="ac407c1e1ae31541a90967436ebe03f21268215532"  #api_token
url="https://www.showdoc.cc/server/?s=/api/open/fromComments" #同步到的url。使用www.showdoc.cc的不需要修改，使用开源版的请修改
#
# 如果第一个参数是目录，则使用参数目录。若无，则使用脚本所在的目录。
if [[ -z "$1" ]] || [[ ! -d "$1" ]] ; then #目录判断，如果$1不是目录或者是空，则使用当前目录
    current_dir=$(dirname $(readlink -f $0))
else
    current_dir=$(cd $1; pwd)
fi

# 递归搜索文件
searchFile() {
    old_IFS="$IFS"
    IFS=$'\n'            #IFS修改
    for check_file in $1/*
    do
        file_size=`ls -l ${check_file} | awk '{ print $5 }'`
        maxsize=$((1048576))  # 1M以下的文本文件才会被扫描
        if [[ -f "$check_file" ]] &&  [[ ${file_size} -le ${maxsize} ]] && [[ -n $(file ${check_file} | grep text) ]] ; then # 只对text文件类型操作
            echo "正在扫描 $check_file"
            result=$(sed -n -e '/ApiDoc/,/EndApiDoc/p' ${check_file}) # 正则匹配
        if [[ ! -z "$result" ]] ; then
            txt=$(sed -n -e '/ApiDoc/,/EndApiDoc/p' ${check_file})
            if  [[ ${txt} =~ ":url" ]] && [[ ${txt} =~ ":title" ]]; then
                echo -e "\033[32m $check_file 扫描到内容 , 正在生成文档 \033[0m "
                # 通过接口生成文档
curl -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8'  "${url}" --data-binary @- <<CURL_DATA
from=shell&api_key=${api_key}&api_token=${api_token}&content=${txt}
CURL_DATA
                fi
            fi
        fi

        if [[ -d ${check_file} ]] ; then
            searchfile ${check_file}
        fi
    done
    IFS="$old_IFS"
}

#执行搜索
searchFile ${current_dir}

#
sys=$(uname)
if [[ ${sys} =~ "MS"  ]] || [[ ${sys} =~ "MINGW"  ]] || [[ ${sys} =~ "win"  ]] ; then
    read -s -n1 -p "按任意键继续 ... " # win环境下为照顾用户习惯，停顿一下
fi

