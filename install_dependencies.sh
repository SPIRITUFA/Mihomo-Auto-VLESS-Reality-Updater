#!/bin/sh

# Обновление репозиториев
echo "[INFO] Updating repositories..."
opkg update || { echo "[ERROR] Failed to update repositories"; exit 1; }

# Установка необходимых пакетов
echo "[INFO] Installing required packages..."
opkg install curl openssl grep awk vim || { echo "[ERROR] Failed to install packages"; exit 1; }

# Создание каталога для скрипта
echo "[INFO] Creating necessary directories..."
mkdir -p /opt/bin /opt/etc/mihomo/proxy-providers

# Скачивание install_dependencies.sh
echo "[INFO] Downloading the install_dependencies.sh script..."
curl -L --silent --show-error --fail "https://raw.githubusercontent.com/SPIRITUFA/Mihomo-Auto-VLESS-Reality-Updater/main/install_dependencies.sh" -o /opt/bin/install_dependencies.sh || { echo "[ERROR] Failed to download install_dependencies.sh"; exit 1; }

# Сделать скрипт исполняемым
echo "[INFO] Setting execute permissions for the install_dependencies.sh script..."
chmod +x /opt/bin/install_dependencies.sh || { echo "[ERROR] Failed to set execute permissions"; exit 1; }

# Запуск скрипта для установки зависимостей
echo "[INFO] Running the install_dependencies.sh script..."
/opt/bin/install_dependencies.sh || { echo "[ERROR] Failed to run install_dependencies.sh"; exit 1; }

# Завершение установки
echo "[INFO] Installation complete! The script is ready to run."
