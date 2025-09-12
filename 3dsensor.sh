#!/bin/bash

ADDR=0x1D

while true; do
    # x
    msb=$(i2cget -y 1 $ADDR 0x01 b)
    lsb=$(i2cget -y 1 $ADDR 0x02 b)
    raw=$(( ((msb<<8 | lsb) >> 4) ))
    if [ $raw -gt 2047 ]; then
        raw=$((raw-4096))
    fi
    x=$(echo "scale=3; $raw/1024" | bc)
    
    # y
    msb=$(i2cget -y 1 $ADDR 0x03 b)
    lsb=$(i2cget -y 1 $ADDR 0x04 b)
    raw=$(( ((msb<<8 | lsb) >> 4) ))
    if [ $raw -gt 2047 ]; then
        raw=$((raw-4096))
    fi
    y=$(echo "scale=3; $raw/1024" | bc)

    # z
    msb=$(i2cget -y 1 $ADDR 0x05 b)
    lsb=$(i2cget -y 1 $ADDR 0x06 b)
    raw=$(( ((msb<<8 | lsb) >> 4) ))
    if [ $raw -gt 2047 ]; then
        raw=$((raw-4096))
    fi
    z=$(echo "scale=3; $raw/1024" | bc)

    echo "$(date +%s), X=${x}g, Y=${y}g, Z=${z}g"
    sleep 0.1
done
