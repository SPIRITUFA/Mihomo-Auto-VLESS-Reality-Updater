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

# =========================
# Добавление задачи в cron
# =========================
echo "[INFO] Проверка cron..."

# Проверяем, установлен ли cron
if ! command -v crond &> /dev/null; then
    echo "[INFO] Cron не установлен, устанавливаю..."
    opkg install cron || { echo "[ERROR] Не удалось установить cron"; exit 1; }
    /etc/init.d/cron start || { echo "[ERROR] Не удалось запустить cron"; exit 1; }
else
    echo "[INFO] Cron уже установлен"
fi

# Проверяем, есть ли уже задачи в cron
EXISTING_CRON_JOBS=$(crontab -l 2>/dev/null)

# Если задач в cron нет, добавляем первую задачу
if [ -z "$EXISTING_CRON_JOBS" ]; then
    echo "[INFO] Задачи в cron не найдены, добавляю задачу..."
    CRON_JOB="*/30 * * * * /tmp/update_mihomo.sh"
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
else
    echo "[INFO] Задачи в cron уже существуют. Добавляю задачу следующей."

    # Считаем, сколько задач в cron, чтобы добавить задачу следующей
    JOB_COUNT=$(echo "$EXISTING_CRON_JOBS" | wc -l)
    
    # Если задач несколько, добавляем новую задачу после существующих
    CRON_JOB="*/30 * * * * /tmp/update_mihomo.sh"
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
fi

echo "[INFO] Задача cron добавлена!"
exit 0
