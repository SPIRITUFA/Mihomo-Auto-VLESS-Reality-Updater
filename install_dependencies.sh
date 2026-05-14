#!/bin/sh

# =========================================
# Установка зависимостей и updater Mihomo
# =========================================

# Функция установки пакетов
install_package() {
    local package="$1"

    echo "[INFO] Устанавливаю $package..."

    opkg install "$package" || {
        echo "[ERROR] Ошибка установки $package"
        return 1
    }
}

# Проверка Entware
if [ ! -x /opt/bin/opkg ]; then
    echo "[ERROR] Entware не установлен!"
    exit 1
fi

# Добавляем Entware в PATH
export PATH=/opt/bin:/opt/sbin:$PATH

# =========================================
# Обновление репозиториев
# =========================================

echo "[INFO] Обновление репозиториев Entware..."

opkg update || {
    echo "[ERROR] Не удалось обновить репозитории"
    exit 1
}

# =========================================
# Установка зависимостей
# =========================================

echo "[INFO] Установка необходимых пакетов..."

install_package "curl"
install_package "grep"
install_package "gawk"
install_package "vim"
install_package "cron"

# =========================================
# Загрузка update_mihomo.sh
# =========================================

UPDATE_SCRIPT_URL="https://raw.githubusercontent.com/SPIRITUFA/Mihomo-Auto-VLESS-Reality-Updater/main/update_mihomo.sh"

echo "[INFO] Загружаю update_mihomo.sh..."

curl -fsSL "$UPDATE_SCRIPT_URL" -o /opt/bin/update_mihomo.sh || {
    echo "[ERROR] Не удалось скачать update_mihomo.sh"
    exit 1
}

# =========================================
# Исправление старого URL keys.json
# =========================================

echo "[INFO] Проверяю URL keys.json..."

sed -i \
's|https://raw.githubusercontent.com/tiagorrg/vless-checker/main/keys.json|https://raw.githubusercontent.com/tiagorrg/vless-checker/main/docs/keys.json|g' \
/opt/bin/update_mihomo.sh

chmod +x /opt/bin/update_mihomo.sh

# Проверка исправления
if grep -q "main/docs/keys.json" /opt/bin/update_mihomo.sh; then
    echo "[INFO] URL keys.json исправлен"
else
    echo "[WARNING] URL keys.json не найден"
fi

# =========================================
# Запуск updater
# =========================================

echo "[INFO] Запуск update_mihomo.sh..."

/opt/bin/update_mihomo.sh || {
    echo "[ERROR] Ошибка выполнения update_mihomo.sh"
    exit 1
}

# =========================================
# Настройка cron
# =========================================

echo "[INFO] Настройка cron..."

# Проверка crond
if ! command -v crond >/dev/null 2>&1; then
    echo "[ERROR] crond не найден"
else
    echo "[INFO] crond найден"
fi

# Запуск cron для Entware
if [ -x /opt/etc/init.d/S10cron ]; then
    /opt/etc/init.d/S10cron enable
    /opt/etc/init.d/S10cron start
fi

# Cron задача
CRON_JOB="*/30 * * * * /opt/bin/update_mihomo.sh"

# Проверяем наличие задачи
EXISTING_CRON_JOBS=$(crontab -l 2>/dev/null)

if echo "$EXISTING_CRON_JOBS" | grep -Fq "$CRON_JOB"; then
    echo "[INFO] Cron задача уже существует"
else
    echo "[INFO] Добавляю cron задачу..."

    (
        crontab -l 2>/dev/null
        echo "$CRON_JOB"
    ) | crontab -

    echo "[INFO] Cron задача добавлена"
fi

# =========================================
# Завершение
# =========================================

echo "[INFO] Установка и настройка завершены успешно!"

exit 0
