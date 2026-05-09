#!/bin/bash

# Убираем символы возврата каретки (для предотвращения ошибок на Linux)
sed -i 's/\r//' $0

# Функция для установки пакетов
install_package() {
    local package=$1
    echo "Устанавливаю $package..."
    opkg install $package || echo "Ошибка при установке $package"
}

# Обновление репозиториев opkg
echo "[INFO] Обновление репозиториев..."
opkg update || { echo "[ERROR] Не удалось обновить репозитории"; exit 1; }

# Установка curl, awk, vim и других необходимых пакетов
echo "[INFO] Установка необходимых пакетов..."
install_package "curl"
install_package "grep"
install_package "awk"
install_package "vim"

# Проверка наличия необходимых файлов
echo "[INFO] Проверка наличия необходимых файлов..."
PROXY_FILE="/opt/etc/mihomo/proxy-providers/proxies.yaml"
if [ ! -f "$PROXY_FILE" ]; then
    echo "[INFO] Файл proxies.yaml не найден, создаю..."
    # Создание файла proxies.yaml, если его нет
    touch "$PROXY_FILE"
else
    echo "[INFO] Файл proxies.yaml уже существует, пропускаем создание."
fi

# Загружаем обновление скрипта, если нужно
UPDATE_SCRIPT="https://raw.githubusercontent.com/SPIRITUFA/Mihomo-Auto-VLESS-Reality-Updater/main/update_script.sh"
echo "[INFO] Загружаю скрипт обновления..."
curl -sSL "$UPDATE_SCRIPT" -o /tmp/update_script.sh || { echo "[ERROR] Не удалось загрузить обновление"; exit 1; }

# Даем права на выполнение скрипта и запускаем его
chmod +x /tmp/update_script.sh
echo "[INFO] Запуск скрипта обновления..."
/tmp/update_script.sh || { echo "[ERROR] Не удалось запустить обновление"; exit 1; }

echo "[INFO] Установка завершена успешно!"
exit 0
