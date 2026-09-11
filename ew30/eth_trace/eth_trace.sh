#!/bin/bin/sh

LOG_FILE="/www/html/eth_trace.log"

# 設定訊號捕獲，讓腳本接到停止指令時能聯即乾淨退出
RUNNING=1
trap 'RUNNING=0' TERM INT

extract_hex_value() {
  local text="$1"
  local match

  match=$(echo "$text" | grep -oE '0x0*([0-9A-Fa-f]+)' | head -n 1 | sed -E 's/0x0*([0-9A-Fa-f]+)/\1/')

  if [ -n "$match" ]; then
    echo "$match"
  else
    echo "N/A"
  fi
}

get_file_val() {
  if [ -f "$1" ]; then
    cat "$1"
  else
    echo "0"
  fi
}

# 若日誌檔不存在，則寫入包含新欄位的 CSV 標頭
if [ ! -f "$LOG_FILE" ]; then
  echo "timestamp,uptime,eth0_speed,eth0_down_count,eth0_up_count,curr_snr_a,curr_snr_b,curr_snr_c,curr_snr_d,min_snr_a,min_snr_b,min_snr_c,min_snr_d,eth_mnt_proc,eth_mnt_resync,eth_mnt_100m" > "$LOG_FILE"
fi

while [ "$RUNNING" -eq 1 ]; do
  TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
  UPTIME=$(awk '{print int($1)}' /proc/uptime)
  
  ETH0_SPEED=$(get_file_val "/sys/class/net/eth0/speed")
  ETH0_DOWN=$(get_file_val "/sys/class/net/eth0/carrier_down_count")
  ETH0_UP=$(get_file_val "/sys/class/net/eth0/carrier_up_count")

  CURR_SNR_A=$(extract_hex_value "$(mii_mgr_cl45 -g -p 0x6 -d 0x1 -r 0x85 2>/dev/null | awk '{print $NF}')")
  CURR_SNR_B=$(extract_hex_value "$(mii_mgr_cl45 -g -p 0x6 -d 0x1 -r 0x86 2>/dev/null | awk '{print $NF}')")
  CURR_SNR_C=$(extract_hex_value "$(mii_mgr_cl45 -g -p 0x6 -d 0x1 -r 0x87 2>/dev/null | awk '{print $NF}')")
  CURR_SNR_D=$(extract_hex_value "$(mii_mgr_cl45 -g -p 0x6 -d 0x1 -r 0x88 2>/dev/null | awk '{print $NF}')")

  MIN_SNR_A=$(extract_hex_value "$(mii_mgr_cl45 -g -p 0x6 -d 0x1 -r 0x89 2>/dev/null | awk '{print $NF}')")
  MIN_SNR_B=$(extract_hex_value "$(mii_mgr_cl45 -g -p 0x6 -d 0x1 -r 0x8a 2>/dev/null | awk '{print $NF}')")
  MIN_SNR_C=$(extract_hex_value "$(mii_mgr_cl45 -g -p 0x6 -d 0x1 -r 0x8b 2>/dev/null | awk '{print $NF}')")
  MIN_SNR_D=$(extract_hex_value "$(mii_mgr_cl45 -g -p 0x6 -d 0x1 -r 0x8c 2>/dev/null | awk '{print $NF}')")

  ETH_MNT_PROC=$(ps | grep '[e]th_monitor' | wc -l)
  ETH_MNT_RESYNC=$(get_file_val "/tmp/.eth_mnt_resync")
  ETH_MNT_100M=$(get_file_val "/tmp/.eth_mnt_100m")

  echo "${TIMESTAMP},${UPTIME},${ETH0_SPEED},${ETH0_DOWN},${ETH0_UP},${CURR_SNR_A},${CURR_SNR_B},${CURR_SNR_C},${CURR_SNR_D},${MIN_SNR_A},${MIN_SNR_B},${MIN_SNR_C},${MIN_SNR_D},${ETH_MNT_PROC},${ETH_MNT_RESYNC},${ETH_MNT_100M}" >> "$LOG_FILE"

  sleep 1 &
  wait $!
done