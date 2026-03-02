#!/bin/bash

#需要修改的变量
max_proc=4
pro_name=boostx
base_path=$(cd `dirname $0`; pwd)
#$1指tar文件目录
read_path=$1
#car文件路径
output_path=/storage01/car_data
#json文件临时路径
json_path=/storage01/car_json/joyme_100t
#json文件最终路径
finally_json_path=/root/joyme_100t/prepare-boost

check_name=${read_path##*/}.list
if [ ! -f $base_path/$pro_name ]; then
    echo "not found $base_path/$pro_name"
    exit
fi

{
    [ -e /tmp/fd3 ] || mkfifo /tmp/fd3
    exec 333<>/tmp/fd3
    rm -rf /tmp/fd3
    for ((i=1;i<=$max_proc;i++)); do
        echo >&333
    done
}

function token_333()
{
    [ -e /tmp/fd3 ] || mkfifo /tmp/fd3
    exec 333<>/tmp/fd3
    rm -rf /tmp/fd3
    for ((i=1;i<=$max_proc;i++)); do
        echo >&333
    done
}

function read_dir()
{
    if [ ! -d $output_path/ ]; then
        mkdir -p $output_path/
        echo "output_path: $output_path/"
    else
        echo "output_path: $output_path/"
    fi
    if [ ! -d $json_path/ ]; then
        mkdir -p $json_path/
        echo "json_path: $json_path/"
    else
        echo "json_path: $json_path/"
    fi
    for file in `ls $1`; do
        if [ -d $1/$file ]; then
            read_dir $1/$file
        else
            sleep 1
            read -u333
            {
                if [ $(grep "$file" $json_path/*|wc -l) -ne 0 ]; then
                    echo "file is already make car and skip this file: $file"
                    echo >&333
                    continue
                else
                    start=$(date +%s)
                    start_time=$(date +%Y%m%d%H%M%S)
                    file_size=$(ls -lrt --block-size=g $1/$file|awk '{print $5}'|sed 's/G//g')
                    if [ "$file_size" != "" ] && [ $(expr $file_size \>= 16) -eq 1 ] && [ $(expr $file_size \<= 32) -eq 1 ]
                    then
                            echo "car_name: $file.car"  > $json_path/$file.json
                            echo "$base_path/$pro_name generate-car ${read_path%/*}/$1/$file $output_path/$file.car"
                            $base_path/$pro_name generate-car ${read_path%/*}/$1/$file $output_path/$file.car >> $json_path/$file.json
                            if [ $? -ne 0 ]
                            then
                                    echo "$file生成payload_cid失败"
                            fi
                            wait
                            echo "$base_path/$pro_name commp $output_path/$file.car"
                            $base_path/$pro_name commp $output_path/$file.car >> $json_path/$file.json
                            if [ $? -ne 0 ]
                            then
                                    echo "$file生成commp_cid失败"
                            fi
                            commp_cid=$(cat $json_path/$file.json |grep 'CommP CID:'|awk  '{print $NF}')
                            mv $output_path/$file.car $output_path/$commp_cid.car
                            if [ -f "$output_path/$commp_cid.car" ];
                            #if [ -f "$output_path/$file.car" ];
                            then
                                    is_car=success
                                    sudo rm -rf ${read_path}/$file
                                    echo $file >> $json_path/$check_name
                                    mv $json_path/$file.json $finally_json_path/
                             else
                                     is_car="file failure"
                             fi
                    else
                            is_car="size failure"
                    fi
                    end=$(date +%s)
                    end_time=$(date +%Y%m%d%H%M%S)
                    time=$[ $end - $start ]
                    echo "{\"start_time\": \"$start_time\", \"end_time\": \"$end_time\", \"use_time\": \"$time\", \"file_name\": \"$1/$file\", \"file_size\": \"$file_size\", \"is_car\": \"$is_car\"}"
                    echo >&333
                fi
            } &
        fi
        #break
done
}

function main()
{
    total_start=$(date +%s)
    total_start_time=$(date +%Y%m%d%H%M%S)

    if [ "$read_path" != "" ]; then
        token_333
        cd ${read_path%/*}
        if [ ! -d ./logs ]; then
            sudo mkdir ./logs
            sudo chmod 777 ./logs
        fi
        read_dir ${read_path##*/}
        wait
        exec 333<&-
        exec 333>&-
    else
        echo "please input read_path"
    fi

    total_end=$(date +%s)
    total_end_time=$(date +%Y%m%d%H%M%S)
    total_time=$[ $total_end - $total_start ]
    echo "{\"total_start_time\": \"$total_start_time\", \"total_end_time\": \"$total_end_time\", \"total_use_time\": \"$total_time\"}"
}

main >$base_path/read_dir_$(date +%Y%m%d%H%M%S).log


#while控制并发
