#!/bin/sh
#
# Crawl Baidu MM Picture
# Source code visit https://github.com/jsbd/crawl-mm.git
# 
#

BASE_DIR=~/image.baidu.com
BASE_LOG=~/image.baidu.com/log
DEST_DIR=~/image.baidu.com/images

REFERER=http://image.baidu.com/search/index\?tn\=baiduimage\&ipn\=r\&ct\=201326592\&cl\=2\&lm\=-1\&st\=-1\&fm\=result\&fr=\&sf\=1\&fmq\=1460948912979_R\&pv\=\&ic\=0\&nc\=1\&z\=\&se\=1\&showtab\=0\&fb\=0\&width\=\&height\=\&face\=0\&istype\=2\&itg\=0\&uptype\=urlsearch\&ie\=utf-8\&word\=%E7%BE%8E%E5%A5%B3
INDEX_URL=http://image.baidu.com/search/index\?tn\=baiduimage\&ipn\=r\&ct\=201326592\&cl\=2\&lm\=-1\&st\=-1\&fm\=result\&fr\=\&sf\=1\&fmq\=1460944349681_R\&pv\=\&ic\=0\&nc\=1\&z\=\&se\=1\&showtab\=0\&fb\=0\&width\=\&height\=\&face\=0\&istype\=2\&itg\=0\&ie\=utf-8\&word\=%E7%BE%8E%E5%A5%B3\#z\=0\&pn\=\&ic\=0\&st\=-1\&face\=0\&s\=0\&lm\=-1
AVATARJSON_URL=http://image.baidu.com/search/avatarjson\?tn\=resultjsonavatarnew\&ie\=utf-8\&word\=%E7%BE%8E%E5%A5%B3\&cg\=girl\&rn\=60\&itg\=0\&z\=0\&fr\=\&width\=\&height\=\&lm\=-1\&ic\=0\&s\=0\&st\=-1

echo "Job will start, wait..."
mkdir -p $BASE_DIR/{log,images}

# 模拟访问百度图片首页的搜索功能
echo "start crawl image index url -> [$INDEX_URL]"
curl $INDEX_URL > $BASE_LOG/content-index.resp
echo "start crawl image index url -> [$INDEX_URL] ok."

# 根据首页的返回内容解析首页图片的地址和GSMcode
# 因为后续页面是根据AJAX动态加载的,所以相应的访问地址和解析情况不一样,需要分开处理
echo "start analysis image url from $BASE_LOG/content-index.resp"
cat $BASE_LOG/content-index.resp |grep objURL |awk -F '"' '{print $4}' >  $BASE_LOG/result-index.url
GSM=`cat $BASE_LOG/content-index.resp |grep gsm |awk -F '"' '{print $2}'`

echo "analysis image url from $BASE_LOG/content-index.resp ok."
sleep 5

echo "we get GSM code is [$GSM] and some url like this...."
cat $BASE_LOG/result-index.url


for (( i = 30; i < 60 * 1000; i+=60 )); do
    # 根据前面获取到的GSMcode构造JSON请求地址
    # pn值是根据Firebug调试时访问百度的情况来填写的,首页首次访问时默认展现30张图,之后每次异步请求服务器时返回的是60张，所以递增值是60累加的
    JSONURL="${AVATARJSON_URL}&gsm=$GSM&pn=$i"

    # 存储服务器的响应内容和提取后的链接到设置的log目录中
    echo "start get [$JSONURL]."
    curl $JSONURL > $BASE_LOG/content-$i.resp
    GSM=`jq '.gsm' $BASE_LOG/content-$i.resp |awk -F '"' '{print $2}' |xargs echo`
    jq '.imgs' $BASE_LOG/content-$i.resp |grep objURL |awk -F '"' '{print $4}' >  $BASE_LOG/result-$i.url
    
    echo "analysis image url from $BASE_LOG/content-$i.resp ok."
    echo "we get GSM code is [$GSM] and some url like this...."

    # 间歇3秒钟，避免请求太过频繁了……
    sleep 3
    cat $BASE_LOG/result-$i.url

done

# 最后一步，将图片下载到设置的image目录当中
cat $BASE_LOG/*.url |xargs wget -P $DEST_DIR

echo "Ok, your mm images has download finished, have a good time.(^_^)"
exit 0
