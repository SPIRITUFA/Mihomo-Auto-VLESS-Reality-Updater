#!/bin/bash

# =======================
#  Mihomo Auto Installer
#  Скрипт установки для Mihomo
# =======================
LOGFILE="/tmp/mihomo_install.log"
REPO_URL="https://raw.githubusercontent.com/SPIRITUFA/Mihomo-Auto-VLESS-Reality-Updater/main"
RETRY_COUNT=3
WAIT_TIME=5
SUCCESS=0

echo "[INFO] Start installing dependencies..." | tee -a $LOGFILE

# Функция для логирования с меткой времени
log_info() {
  echo "[INFO] $(date) - $1" | tee -a $LOGFILE
}

# Функция для установки пакетов через opkg с retry
install_with_retry() {
  local command="$1"
  local count=0

  while [ $count -lt $RETRY_COUNT ]; do
    $command
    if [ $? -eq 0 ]; then
      log_info "Команда '$command' выполнена успешно!"
      SUCCESS=1
      break
    else
      count=$((count+1))
      log_info "Попытка $count не удалась, пробуем снова..."
      sleep $WAIT_TIME
    fi
  done

  if [ $SUCCESS -eq 0 ]; then
    log_info "Ошибка при выполнении команды '$command' после $RETRY_COUNT попыток."
    exit 1
  fi
}

# Шаг 1: Обновление opkg репозиториев
log_info "Обновление репозиториев opkg..."
install_with_retry "opkg update"

# Шаг 2: Добавление вашего кастомного репозитория
log_info "Добавление кастомного репозитория для Mihomo..."
mkdir -p /opt/etc/opkg
echo "src/gz MihomoAuto ${REPO_URL}/packages" > /opt/etc/opkg/MihomoAuto.conf

# Шаг 3: Обновление репозиториев после добавления
log_info "Обновление всех репозиториев..."
install_with_retry "opkg update"

# Шаг 4: Установка зависимостей и скриптов из вашего репозитория
log_info "Установка скриптов и зависимостей из репозитория..."

install_with_retry "opkg install curl vim"

# Шаг 5: Завершающий этап — проверка установки
log_info "Проверка установки..."

# Печать успешного завершения
log_info "Скрипт успешно выполнен!"
echo "[INFO] Скрипт установки завершён успешно." | tee -a $LOGFILE