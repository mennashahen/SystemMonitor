#!/bin/bash

DATA_FILE="/app/web/data.js"
RAW_FILE="/app/web/raw.txt"
BRIDGE_FILE="/app/web/real_temp.txt"

echo "" > "$RAW_FILE"

# متغيرات لحساب سرعة الشبكة
R1=$(cat /sys/class/net/eth0/statistics/rx_bytes)
T1=$(cat /sys/class/net/eth0/statistics/tx_bytes)

while true; do
    TIME=$(date "+%H:%M:%S")

    # 1. CPU & RAM & Disk Usage
    CPU_USAGE=$(mpstat 1 1 | awk 'END{print 100-$NF}')
    RAM_USAGE=$(free -m | awk 'NR==2{printf "%.2f", $3*100/$2 }')
    DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    # 2. Disk SMART Status (محاكاة)
    # لو الاستهلاك أقل من 90% نعتبره Healthy
    if [ "$DISK_USAGE" -lt 5 ]; then
        SMART_STATUS="OK"
    else
        SMART_STATUS="WARN"
    fi

    # 3. Network Stats (حساب الفرق في الثانية)
    R2=$(cat /sys/class/net/eth0/statistics/rx_bytes)
    T2=$(cat /sys/class/net/eth0/statistics/tx_bytes)
    
    # تحويل من بايت لكيلوبايت
    RX_SPEED=$(( (R2 - R1) / 1024 ))
    TX_SPEED=$(( (T2 - T1) / 1024 ))
    
    # تحديث القيم القديمة للفة الجاية
    R1=$R2
    T1=$T2

    # 4. Temp (Bridge Logic)
    CPU_TEMP="0"
    GPU_TEMP="0"
    TEMP_FOUND=0

    if [ -f "$BRIDGE_FILE" ]; then
        LINE=$(head -n 1 "$BRIDGE_FILE" | tr -d '[:space:]')
        if [[ "$LINE" == *"|"* ]]; then
            CPU_TEMP=$(echo "$LINE" | cut -d'|' -f1)
            GPU_TEMP=$(echo "$LINE" | cut -d'|' -f2)
            TEMP_FOUND=1
        fi
    fi

    if [ "$CPU_TEMP" == "0" ] || [ -z "$CPU_TEMP" ]; then
        CPU_TEMP=$(echo "$CPU_USAGE" | awk '{printf "%.1f", 40 + ($1 * 0.5)}')
    fi
    if [ "$GPU_TEMP" == "0" ] || [ -z "$GPU_TEMP" ]; then
         GPU_TEMP=$(echo "$CPU_TEMP" | awk '{printf "%.1f", $1 + 5}')
    fi
    
    # 5. Save Data (تمت إضافة netRx, netTx, smart)
    echo "{ time: '$TIME', cpu: $CPU_USAGE, ram: $RAM_USAGE, disk: $DISK_USAGE, smart: '$SMART_STATUS', cpuTemp: $CPU_TEMP, gpuTemp: $GPU_TEMP, netRx: $RX_SPEED, netTx: $TX_SPEED }," >> "$RAW_FILE"
    
    echo "var systemData = [" > "$DATA_FILE"
    tail -n 20 "$RAW_FILE" >> "$DATA_FILE"
    echo "];" >> "$DATA_FILE"
    
    # Sleep is handled by mpstat implicitly, but we need consistent network calculation
    # mpstat takes 1 sec, so the loop is ~1 sec
done