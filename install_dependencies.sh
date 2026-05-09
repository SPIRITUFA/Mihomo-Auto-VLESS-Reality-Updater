#!/bin/sh

# Убедитесь, что скрипт не работает с символами возврата каретки
sed -i 's/\r//' "$0"

# Обновление репозиториев
echo "[INFO] Updating repositories..."
opkg update || echo "[ERROR] Failed to update repositories."

# Установка необходимых пакетов
echo "[INFO] Installing required packages..."
opkg install curl || echo "[ERROR] curl installation failed."
opkg install grep || echo "[ERROR] grep installation failed."

# Проверка наличия awk и vim, установка их вручную, если они отсутствуют
echo "[INFO] Checking for missing packages (awk, vim)..."
if ! opkg list-installed | grep -q "awk"; then
    echo "[INFO] Installing awk manually..."
    # Если пакеты не установлены, установите их вручную или через другие репозитории
fi

if ! opkg list-installed | grep -q "vim"; then
    echo "[INFO] Installing vim manually..."
    # Если пакеты не установлены, установите их вручную или через другие репозитории
fi

# Скачивание обновленного скрипта
echo "[INFO] Downloading the update script..."
cat << 'EOF' > /opt/bin/update_mihomo.sh
#!/bin/sh
URL="https://raw.githubusercontent.com/SPIRITUFA/Mihomo-Auto-VLESS-Reality-Updater/main/update_mihomo.sh"
OUT="/opt/etc/mihomo/proxy-providers/proxies.yaml"
TMP="/tmp/proxies.yaml"
JSON="/tmp/keys.json"
JSONTMP="/tmp/keys.json.tmp"
LAT="/tmp/latency.txt"
CACHE="/tmp/geo_cache.txt"
COUNT=0

trap 'rm -f "$TMP" "$LAT" "${LAT}.sorted" "$JSONTMP"' EXIT

echo "[INFO] downloading JSON..."
curl -L --silent --show-error --fail "$URL" -o "$JSONTMP" || exit 1
mv "$JSONTMP" "$JSON"

[ ! -s "$JSON" ] && echo "[ERROR] empty JSON" && exit 1

> "$LAT"
[ ! -f "$CACHE" ] && touch "$CACHE"

get_flag() {
  case "$1" in
    # Европа
    AL) echo "🇦🇱" ;; AD) echo "🇦🇩" ;; AM) echo "🇦🇲" ;;
    AT) echo "🇦🇹" ;; AZ) echo "🇦🇿" ;; BY) echo "🇧🇾" ;;
    BE) echo "🇧🇪" ;; BA) echo "🇧🇦" ;; BG) echo "🇧🇬" ;;
    HR) echo "🇭🇷" ;; CY) echo "🇨🇾" ;; CZ) echo "🇨🇿" ;;
    DK) echo "🇩🇰" ;; EE) echo "🇪🇪" ;; FI) echo "🇫🇮" ;;
    FR) echo "🇫🇷" ;; GE) echo "🇬🇪" ;; DE) echo "🇩🇪" ;;
    GR) echo "🇬🇷" ;; HU) echo "🇭🇺" ;; IS) echo "🇮🇸" ;;
    IE) echo "🇮🇪" ;; IT) echo "🇮🇹" ;; LV) echo "🇱🇻" ;;
    LI) echo "🇱🇮" ;; LT) echo "🇱🇹" ;; LU) echo "🇱🇺" ;;
    MT) echo "🇲🇹" ;; MD) echo "🇲🇩" ;; MC) echo "🇲🇨" ;;
    ME) echo "🇲🇪" ;; NL) echo "🇳🇱" ;; MK) echo "🇲🇰" ;;
    NO) echo "🇳🇴" ;; PL) echo "🇵🇱" ;; PT) echo "🇵🇹" ;;
    RO) echo "🇷🇴" ;; RU) echo "🇷🇺" ;; SM) echo "🇸🇲" ;;
    RS) echo "🇷🇸" ;; SK) echo "🇸🇰" ;; SI) echo "🇸🇮" ;;
    ES) echo "🇪🇸" ;; SE) echo "🇸🇪" ;; CH) echo "🇨🇭" ;;
    TR) echo "🇹🇷" ;; UA) echo "🇺🇦" ;; GB) echo "🇬🇧" ;;
    VA) echo "🇻🇦" ;;

    # Азия
    AF) echo "🇦🇫" ;; BH) echo "🇧🇭" ;; BD) echo "🇧🇩" ;;
    BT) echo "🇧🇹" ;; BN) echo "🇧🇳" ;; KH) echo "🇰🇭" ;;
    CN) echo "🇨🇳" ;; HK) echo "🇭🇰" ;; IN) echo "🇮🇳" ;;
    ID) echo "🇮🇩" ;; IR) echo "🇮🇷" ;; IQ) echo "🇮🇶" ;;
    IL) echo "🇮🇱" ;; JP) echo "🇯🇵" ;; JO) echo "🇯🇴" ;;
    KZ) echo "🇰🇿" ;; KW) echo "🇰🇼" ;; KG) echo "🇰🇬" ;;
    LA) echo "🇱🇦" ;; LB) echo "🇱🇧" ;; MY) echo "🇲🇾" ;;
    MV) echo "🇲🇻" ;; MN) echo "🇲🇳" ;; MM) echo "🇲🇲" ;;
    NP) echo "🇳🇵" ;; KP) echo "🇰🇵" ;; KR) echo "🇰🇷" ;;
    OM) echo "🇴🇲" ;; PK) echo "🇵🇰" ;; PH) echo "🇵🇭" ;;
    QA) echo "🇶🇦" ;; SA) echo "🇸🇦" ;; SG) echo "🇸🇬" ;;
    LK) echo "🇱🇰" ;; SY) echo "🇸🇾" ;; TW) echo "🇹🇼" ;;
    TJ) echo "🇹🇯" ;; TH) echo "🇹🇭" ;; TM) echo "🇹🇲" ;;
    AE) echo "🇦🇪" ;; UZ) echo "🇺🇿" ;; VN) echo "🇻🇳" ;;
    YE) echo "🇾🇪" ;;

    # Северная Америка
    CA) echo "🇨🇦" ;; CR) echo "🇨🇷" ;; CU) echo "🇨🇺" ;;
    DO) echo "🇩🇴" ;; SV) echo "🇸🇻" ;; GT) echo "🇬🇹" ;;
    HT) echo "🇭🇹" ;; HN) echo "🇭🇳" ;; JM) echo "🇯🇲" ;;
    MX) echo "🇲🇽" ;; NI) echo "🇳🇮" ;; PA) echo "🇵🇦" ;;
    US) echo "🇺🇸" ;;

    # Южная Америка
    AR) echo "🇦🇷" ;; BO) echo "🇧🇴" ;; BR) echo "🇧🇷" ;;
    CL) echo "🇨🇱" ;; CO) echo "🇨🇴" ;; EC) echo "🇪🇨" ;;
    GY) echo "🇬🇾" ;; PY) echo "🇵🇾" ;; PE) echo "🇵🇪" ;;
    SR) echo "🇸🇷" ;; UY) echo "🇺🇾" ;; VE) echo "🇻🇪" ;;

    # Африка
    DZ) echo "🇩🇿" ;; AO) echo "🇦🇴" ;; CM) echo "🇨🇲" ;;
    EG) echo "🇪🇬" ;; ET) echo "🇪🇹" ;; GH) echo "🇬🇭" ;;
    KE) echo "🇰🇪" ;; LY) echo "🇱🇾" ;; MA) echo "🇲🇦" ;;
    NG) echo "🇳🇬" ;; ZA) echo "🇿🇦" ;; TN) echo "🇹🇳" ;;
    UG) echo "🇺🇬" ;; ZW) echo "🇿🇼" ;;

    # Океания
    AU) echo "🇦🇺" ;; NZ) echo "🇳🇿" ;; FJ) echo "🇫🇯" ;;
  esac
}

# Запуск обновления
echo "[INFO] Running the update script..."
/opt/bin/update_mihomo.sh
EOF

# Устанавливаем права на выполнение для скрипта
chmod +x /opt/bin/update_mihomo.sh

# Запуск скрипта
/opt/bin/update_mihomo.sh

echo "[INFO] Installation complete! Script has been executed."
