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

# Проверка на существующие подписки в use
EXISTING_SUBSCRIPTION=$(grep -oP 'subscription-\d+' "$CONFIG_FILE")

# Нахождение максимального номера подписки
MAX_SUBSCRIPTION=$(echo "$EXISTING_SUBSCRIPTION" | sed -E 's/[^0-9]//g' | sort -n | tail -n 1)
NEXT_SUBSCRIPTION=$((MAX_SUBSCRIPTION + 1))

# Строки, которые нужно добавить
SUBSCRIPTION_CONTENT="
  - subscription-$NEXT_SUBSCRIPTION
"

# Проверка на существование строки 'use:' после 'proxy-groups:'
if grep -q "proxy-groups:" "$CONFIG_FILE"; then
    echo "[INFO] Добавление новой подписки в proxy-groups..."

    # Если строка use существует, то добавляем подписку
    sed -i "/proxy-groups:/,/use:/s/^\(.*use:\)/\1\n$SUBSCRIPTION_CONTENT/" "$CONFIG_FILE" || { echo "[ERROR] Не удалось добавить подписку в $CONFIG_FILE"; exit 1; }
else
    echo "[ERROR] Не найден раздел proxy-groups в $CONFIG_FILE"
    exit 1
fi

# Добавление подписки в config.yaml
echo "[INFO] Обновление завершено успешно!"
exit 0
