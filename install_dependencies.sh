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

# Загружаем скрипт обновления с GitHub и сохраняем его в /opt/bin/
UPDATE_SCRIPT_URL="https://raw.githubusercontent.com/SPIRITUFA/Mihomo-Auto-VLESS-Reality-Updater/main/update_mihomo.sh"
echo "[INFO] Загружаю скрипт обновления..."
curl -sSL "$UPDATE_SCRIPT_URL" -o /opt/bin/update_mihomo.sh || { echo "[ERROR] Не удалось загрузить обновление"; exit 1; }

# Даем права на выполнение скрипта
chmod +x /opt/bin/update_mihomo.sh
echo "[INFO] Запуск скрипта обновления..."
/opt/bin/update_mihomo.sh || { echo "[ERROR] Не удалось запустить обновление"; exit 1; }

# =========================
# Добавление задачи в cron
# =========================

# Проверяем, установлен ли cron
if ! command -v crond &> /dev/null; then
    echo "[INFO] Cron не установлен, устанавливаю..."
    opkg install cron || { echo "[ERROR] Не удалось установить cron"; exit 1; }
    /etc/init.d/cron start || { echo "[ERROR] Не удалось запустить cron"; exit 1; }
else
    echo "[INFO] Cron уже установлен"
fi

# Проверяем, есть ли уже задача в cron для обновления
EXISTING_CRON_JOBS=$(crontab -l 2>/dev/null)
CRON_JOB="*/30 * * * * /opt/bin/update_mihomo.sh"

if echo "$EXISTING_CRON_JOBS" | grep -q "$CRON_JOB"; then
    echo "[INFO] Задача cron для обновления уже существует, пропускаем установку."
else
    echo "[INFO] Задачи cron для обновления не найдены, добавляю задачу..."
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "[INFO] Задача cron добавлена!"
fi

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
    
    # Проверяем наличие подписки в блоке use
    if ! grep -q "subscription-$NEXT_SUBSCRIPTION" "$CONFIG_FILE"; then
        # Добавляем новую подписку в блок use, если ее нет
        sed -i "/proxy-groups:/,/proxies:/s/\(.*use:\)/\1\n$NEW_SUBSCRIPTION/" "$CONFIG_FILE" || { echo "[ERROR] Не удалось добавить подписку в proxy-groups"; exit 1; }
    else
        echo "[INFO] Подписка subscription-$NEXT_SUBSCRIPTION уже существует в proxy-groups."
    fi
    
else
    echo "[INFO] Блок proxy-groups не найден, добавляю новый блок..."
    
    # Если блок proxy-groups не существует, добавляем его с единственной подпиской
    cat >> "$CONFIG_FILE" <<EOF

proxy-groups:
  - name: '🚀Auto-Best'
    type: url-test
    use:
      - subscription-$NEXT_SUBSCRIPTION
    exclude-filter: "(?i)RU|Осталось трафика"
    url: https://www.gstatic.com/generate_204
    interval: 300
    tolerance: 50

EOF
fi

# =========================
# Добавление 🚀Auto-Best в блоки с DIRECT
# =========================
echo "[INFO] Добавление 🚀Auto-Best в блоки с DIRECT..."

# Для каждого блока, который содержит 'DIRECT', добавляем '🚀Auto-Best' в секцию 'proxies', если такого еще нет
gawk '
  /proxies:/ {
    in_proxies = 1
    proxies_found = 0
  }
  # Если строка закомментирована, пропускаем
  /#proxies:/ { in_proxies = 0 }
  in_proxies && /DIRECT/ && !proxies_found {
    print "      - 🚀Auto-Best"
    proxies_found = 1
  }
  { print }
' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

echo "[INFO] Обновление завершено успешно!"
exit 0
