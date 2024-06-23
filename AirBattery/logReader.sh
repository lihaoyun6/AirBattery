IFS=$'\n'
data=`log show --process bluetoothd --info --last $1|grep -E "com.apple.bluetooth:Server.GATT|com.apple.bluetooth:CBStackDeviceMonitor"`
for i in `echo "$data"|grep "Battery"|grep -v "VID 0x004C"`
do
	time=`echo $i|awk '{print $1"T"$2}'`
	name=`echo $i|grep -o ", Nm '.*', PID"|sed "s/, Nm '//g;s/', PID//g"`
	type=`echo $i|grep -o ", DvT [A-z]*"|sed "s/, DvT //g"`
    batt=`echo $i|grep -o ", Battery M [+-]*[0-9]*%"|grep -o "\d*"`
	stat=`echo $i|grep -o ", Battery M [+-]*[0-9]*%"|grep -Eo "\+|\-"`
	mac=`echo $i|grep -o ", BDA [A-z0-9:]*"|sed "s/, BDA //g"`
	vid=`echo $i|grep -o ", VID 0x[A-z0-9]*"|sed "s/, VID //g"`
	pid=`echo $i|grep -o ", PID 0x[A-z0-9]*"|sed "s/, PID //g"`
	if [ "x$batt" != "x" ]; then
		echo "{\"time\": \"$time\", \"vid\": \"$vid\", \"pid\": \"$pid\", \"type\": \"$type\", \"mac\": \"$mac\", \"name\": \"$name\", \"level\": $batt, \"status\": \"$stat\"}"
	fi
done
devData=`echo "$data"|grep -E "statedump: 0x001A Characteristic Value|statedump: 0x001D Characteristic Value"|grep -o "\[[A-z0-9 ]*\]"|sed 's/\[ //g;s/ \]//g'|awk '{if (NR%2==1) {line=$0} else {print line, $0}}'`
times=`echo "$data"|grep -E "statedump: 0x001D Characteristic Value"|awk '{print $1"T"$2}'`
if [ `echo "$devData"|wc -l` = `echo "$times"|wc -l` ];then
    btData=`/usr/sbin/system_profiler SPBluetoothDataType`
    for i in `paste -d ' ' <(echo "$times") <(echo "$devData")`
    do
        if [ `echo $i|wc -w|tr -d " "` = "9" ];then
            time=`echo $i|awk '{print $1}'`
            batt=`echo $i|awk '{print "0x"$NF}'`
            vid=`echo $i|awk '{print "0x"$4$3}'`
            pid=`echo $i|awk '{print "0x"$6$5}'`
            name=`echo "$btData"|grep -B3 $pid|sed -n '1p'|sed 's/^ *//g;s/:$//g'`
            type=`echo "$btData"|grep -A5 $pid|grep "Minor Type: "|sed 's/^ *Minor Type: //g'`
            mac=`echo "$btData"|grep -B2 $pid|sed -n '1p'|sed 's/^ *Address: //g;s/:$//g'`
            echo "{\"time\": \"$time\", \"vid\": \"$vid\", \"pid\": \"$pid\", \"type\": \"$type\", \"mac\": \"$mac\", \"name\": \"$name\", \"level\": $(($batt)), \"status\": \"?\"}"
        fi
    done
fi
