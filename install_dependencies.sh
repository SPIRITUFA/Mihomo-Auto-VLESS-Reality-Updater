#!/bin/sh

# Удаляем символы возврата каретки
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

# Запуск обновления
echo "[INFO] Running the update script..."
/opt/bin/update_mihomo.sh
EOF

# Устанавливаем права на выполнение для скрипта
chmod +x /opt/bin/update_mihomo.sh

# Запуск скрипта
/opt/bin/update_mihomo.sh

echo "[INFO] Installation complete! Script has been executed."
