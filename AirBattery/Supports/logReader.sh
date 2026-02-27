if [ "x$1" = "xmac" ]; then
    # Tightened predicate with correct precedence and reduced scope
    PRED='subsystem == "com.apple.bluetooth" AND (category == "CBStackDeviceMonitor" OR category == "Server.GATT") AND (eventMessage CONTAINS "Battery" OR eventMessage CONTAINS "statedump: 0x0011" OR eventMessage CONTAINS "statedump: 0x0014" OR eventMessage CONTAINS "statedump: 0x001A" OR eventMessage CONTAINS "statedump: 0x001D")'

    # Prefer START_TS (absolute time) if provided; otherwise fall back to a short --last window ($2)
    if [ -n "$START_TS" ]; then
        data=$(/usr/bin/nice -n 19 /usr/bin/log show --style compact --info --predicate "$PRED" --start "$START_TS")
        if [ "x$data" = "x" ]; then
            data=$(/usr/bin/log show --style compact --info --predicate "$PRED" --start "$START_TS")
        fi
    else
        WINDOW="${2:-10m}"
        data=$(/usr/bin/nice -n 19 /usr/bin/log show --style compact --info --predicate "$PRED" --last "$WINDOW")
        if [ "x$data" = "x" ]; then
            data=$(/usr/bin/log show --style compact --info --predicate "$PRED" --last "$WINDOW")
        fi
    fi
    btData=`/usr/sbin/system_profiler SPBluetoothDataType`

    #data=`log show --process bluetoothd --info --last $1|grep -E "com.apple.bluetooth:Server.GATT.*statedump|com.apple.bluetooth:CBStackDeviceMonitor.*Battery"`
    while IFS= read -r i
    do
        [ "x$i" = "x" ] && continue
        time=`echo "$i"|awk '{print $1"T"$2}'`
        name=`echo "$i"|grep -o ", PrNm [^,]*"|sed "s/, PrNm //g"`
        if [ "x$name" = "x" ]; then
            name=`echo "$i"|grep -o ", Nm '.*', PID"|sed "s/, Nm '//g;s/', PID//g"`
        fi
        if [ "x$name" = "x" ]; then
            name=`echo "$i"|grep -o ", Nm [^,]* , PID"|sed "s/, Nm //g;s/ , PID//g"`
        fi
        type=`echo "$i"|grep -o ", DvT [A-z]*"|sed "s/, DvT //g"`
        batt=`echo "$i"|grep -o ", Battery M [+-]*[0-9]*%"|grep -o "[0-9]*"`
        stat=`echo "$i"|grep -o ", Battery M [+-]*[0-9]*%"|grep -Eo "\+|\-"`
        mac=`echo "$i"|grep -o ", BDA [A-z0-9:]*"|sed "s/, BDA //g"`
        vid=`echo "$i"|grep -o ", VID 0x[A-z0-9]*"|sed "s/, VID //g"`
        pid=`echo "$i"|grep -o ", PID 0x[A-z0-9]*"|sed "s/, PID //g"`
        if [ "x$batt" != "x" ]; then
            echo "{\"time\": \"$time\", \"vid\": \"$vid\", \"pid\": \"$pid\", \"type\": \"$type\", \"mac\": \"$mac\", \"name\": \"$name\", \"level\": $batt, \"status\": \"$stat\"}"
        fi
    done < <(echo "$data"|grep "Battery"|grep -v "VID 0x004C")

    # Newer macOS/BLE HID path:
    # 0x0011 = PnP ID (vid/pid/version), 0x0014 = Battery Level (0x2A19)
    cur_vid=""
    cur_pid=""
    while IFS= read -r line
    do
        [ "x$line" = "x" ] && continue

        if echo "$line" | grep -q "statedump: 0x0011 Characteristic Value"; then
            payload=`echo "$line"|sed -n 's/.*\[ \(.*\) \].*/\1/p'`
            set -- $payload
            if [ "$#" -ge 7 ]; then
                cur_vid="0x$3$2"
                cur_pid="0x$5$4"
            fi
            continue
        fi

        if echo "$line" | grep -q "statedump: 0x0014 Characteristic Value"; then
            [ "x$cur_pid" = "x" ] && continue
            bhex=`echo "$line"|sed -n 's/.*0x0014 Characteristic Value \[ \([0-9A-Fa-f][0-9A-Fa-f]\) \].*/\1/p'`
            [ "x$bhex" = "x" ] && continue
            batt=$((16#$bhex))
            if [ "$batt" -lt 0 ] || [ "$batt" -gt 100 ]; then continue; fi

            time=`echo "$line"|awk '{print $1"T"$2}'`
            type=`echo "$btData"|grep -A5 "$cur_pid"|grep "Minor Type: "|sed 's/^ *Minor Type: //g'|sed -n '1p'`
            mac=`echo "$btData"|grep -B2 "$cur_pid"|grep "Address: "|sed 's/^ *Address: //g'|sed -n '1p'`
            name=`echo "$btData"|grep -B3 "$cur_pid"|sed -n '1p'|sed 's/^ *//g;s/:$//g'`
            if [ "x$name" = "x" ] && [ "x$type" != "x" ] && [ "x$mac" != "x" ]; then name="$type ($mac)"; fi
            if [ "x$mac" != "x" ]; then
                echo "{\"time\": \"$time\", \"vid\": \"$cur_vid\", \"pid\": \"$cur_pid\", \"type\": \"$type\", \"mac\": \"$mac\", \"name\": \"$name\", \"level\": $batt, \"status\": \"?\"}"
            fi
        fi
    done < <(echo "$data"|grep -E "statedump: 0x0011 Characteristic Value|statedump: 0x0014 Characteristic Value")

    devData=`echo "$data"|grep -E "statedump: 0x001A Characteristic Value|statedump: 0x001D Characteristic Value"|grep -o "\[[A-z0-9 ]*\]"|sed 's/\[ //g;s/ \]//g'|awk '{if (NR%2==1) {line=$0} else {print line, $0}}'|awk 'length($0) == 23'`
    times=`echo "$data"|grep -E "statedump: 0x001D Characteristic Value"|awk '{print $1"T"$2}'`
    if [ `echo "$devData"|wc -l` = `echo "$times"|wc -l` ];then
        while IFS= read -r i
        do
            [ "x$i" = "x" ] && continue
            if [ `echo "$i"|wc -w|tr -d " "` = "9" ];then
                time=`echo "$i"|awk '{print $1}'`
                batt=`echo "$i"|awk '{print "0x"$NF}'`
                vid=`echo "$i"|awk '{print "0x"$4$3}'`
                pid=`echo "$i"|awk '{print "0x"$6$5}'`
                name=`echo "$btData"|grep -B3 $pid|sed -n '1p'|sed 's/^ *//g;s/:$//g'`
                type=`echo "$btData"|grep -A5 $pid|grep "Minor Type: "|sed 's/^ *Minor Type: //g'`
                mac=`echo "$btData"|grep -B2 $pid|sed -n '1p'|sed 's/^ *Address: //g;s/:$//g'`
                echo "{\"time\": \"$time\", \"vid\": \"$vid\", \"pid\": \"$pid\", \"type\": \"$type\", \"mac\": \"$mac\", \"name\": \"$name\", \"level\": $(($batt)), \"status\": \"?\"}"
            fi
        done < <(paste -d ' ' <(echo "$times") <(echo "$devData"))
    fi
else
    syslog=$1
    type=$2
    id=$3
    
    data=`$syslog $type -u $id --process SpringBoard -m '"Accessory Category" = Pencil;' -T SpringBoard`
    batt=`echo "$data"|grep "Current Capacity"|grep -o "[0-9]*"|sed -n '$p'`
    stat=`echo "$data"|grep "Is Charging"|grep -o "[0-9]*"|sed -n '$p'`
    model=`echo "$data"|grep "Product ID"|grep -o "[0-9]*"|sed -n '$p'`
    vendor=`echo "$data"|grep "Vendor ID"|grep -v Source|grep -o "[0-9]*"|sed -n '$p'`
    if [ x"$vendor" = "x76" ]; then vendor="Apple"; else vendor="Other"; fi
    
    #data=`$syslog $type -u $id -m 'name = Pencil' --process SpringBoard -T SpringBoard|tr ';' '\n'`
    #batt=`echo "$data"|grep "percentCharge ="|grep -o "[0-9]*"|sed -n '$p'`
    #stat=`echo "$data"|grep "charging ="|tr -d " "|sed 's/charging=//g'|sed -n '$p'`
    #model=`echo "$data"|grep "productIdentifier ="|grep -o "[0-9]*"|sed -n '$p'`
    #vendor=`echo "$data"|grep "vendor ="|tr -d " "|sed 's/vendor=//g'|sed -n '$p'`
    #if [ x"$stat" = "xYES" ]; then stat=1; else stat=0; fi
    echo "{\"level\": $batt, \"status\": $stat, \"model\": \"$model\", \"vendor\": \"$vendor\"}"
fi
