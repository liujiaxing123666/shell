#!/bin/bash
sed '/^$/d' link.txt 2>&1
printf "%-20s %-10s %-10s %-20s\n" 网址 状态码 能否通 AAAA
for link in `cat link.txt`
do
	curl -6 -L $link > /dev/null 2>&1
	if [ $? -ne 0 ]
	then
		no="不通"
	else
		no="通"
	fi
	code=`curl -I -m 10 -o /dev/null -s -w %{http_code} $link`
	ipv6_aaaa=`dig aaaa $link | grep AAAA | grep : | head -1 | awk '{print $5}'`
	printf "%-20s %-10s %-10s %-20s \n" $link $code $no $ipv6_aaaa
done
