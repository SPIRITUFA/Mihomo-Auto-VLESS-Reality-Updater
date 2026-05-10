#!/bin/bash

# Убираем символы возврата каретки (для предотвращения ошибок на Linux)
sed -i 's/\r//' "$0"

# Функция для установки пакетов через opkg (Entware)
install_package() {
    local package=$1
    echo "Устанавливаю $package..."
    opkg install "$package" || echo "Ошибка при установке $package"
}

# Обновление репозиториев opkg (Entware)
echo "[INFO] Обновление репозиториев..."
opkg update || { echo "[ERROR] Не удалось обновить репозитории"; exit 1; }

# Установка curl, grep, gawk и vim
echo "[INFO] Установка необходимых пакетов..."
install_package "curl"
install_package "grep"
install_package "gawk"
install_package "vim"

# Загружаем скрипт обновления с GitHub
UPDATE_SCRIPT_URL="https://raw.githubusercontent.com/SPIRITUFA/Mihomo-Auto-VLESS-Reality-Updater/main/update_mihomo.sh"
echo "[INFO] Загружаю скрипт обновления..."
curl -sSL "$UPDATE_SCRIPT_URL" -o /tmp/update_mihomo.sh || { echo "[ERROR] Не удалось загрузить обновление"; exit 1; }

# Даем права на выполнение скрипта и запускаем его
chmod +x /tmp/update_mihomo.sh
echo "[INFO] Запуск скрипта обновления..."
/tmp/update_mihomo.sh || { echo "[ERROR] Не удалось запустить обновление"; exit 1; }

# Добавляем задачу в cron для обновления каждые 30 минут
CRON_JOB="*/30 * * * * /tmp/update_mihomo.sh"
(crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

# =========================
# Добавление подписки в config.yaml
# =========================
CONFIG_FILE="/opt/etc/mihomo/config.yaml"
PROXY_FILE="/opt/etc/mihomo/proxy-providers/proxies.yaml"

# Создаем бекап файла config.yaml перед его изменением
BACKUP_CONFIG_FILE="/opt/etc/mihomo/config.yaml.bak"
echo "[INFO] Создание бекапа файла config.yaml..."
cp "$CONFIG_FILE" "$BACKUP_CONFIG_FILE" || { echo "[ERROR] Не удалось создать бекап файла $CONFIG_FILE"; exit 1; }

# Получаем список существующих подписок из файла
EXISTING_SUBSCRIPTIONS=$(grep -oP 'subscription-\d+' "$CONFIG_FILE" || echo "")

# Нахождение максимального номера подписки
MAX_SUBSCRIPTION=$(echo "$EXISTING_SUBSCRIPTIONS" | sed -E 's/[^0-9]//g' | sort -n | tail -n 1)
NEXT_SUBSCRIPTION=$((MAX_SUBSCRIPTION + 1))

# Строки для добавления новой подписки
NEW_SUBSCRIPTION="  - subscription-$NEXT_SUBSCRIPTION"

# Проверяем, существует ли блок proxy-groups
if grep -q "proxy-groups:" "$CONFIG_FILE"; then
    echo "[INFO] Добавление новой подписки в proxy-groups..."
    
    # Если блок уже существует, вставляем новую подписку в use:
    sed -i "/proxy-groups:/,/proxies:/s/^\(.*use:\)/\1\n$NEW_SUBSCRIPTION/" "$CONFIG_FILE" || { echo "[ERROR] Не удалось добавить подписку в proxy-groups"; exit 1; }

else
    echo "[INFO] Блок proxy-groups не найден, добавляю новый блок..."
    
    # Если блок proxy-groups не существует, добавляем его вместе с новой подпиской
    cat >> "$CONFIG_FILE" <<EOF

proxy-groups:
  - name: '🚀Auto-Best'
    type: url-test
    use:
      - subscription
      - subscription-2
      - subscription-3
      - subscription-4
      - subscription-5
    exclude-filter: "(?i)RU|Осталось трафика"
    url: https://www.gstatic.com/generate_204
    interval: 300
    tolerance: 50

EOF

    # Добавляем нашу новую подписку в use
    sed -i "/proxy-groups:/,/use:/s/^\(.*use:\)/\1\n$NEW_SUBSCRIPTION/" "$CONFIG_FILE" || { echo "[ERROR] Не удалось добавить подписку в новый блок proxy-groups"; exit 1; }
fi

# Добавление новой подписки в блок proxy-groups
echo "[INFO] Обновление завершено успешно!"
exit 0
