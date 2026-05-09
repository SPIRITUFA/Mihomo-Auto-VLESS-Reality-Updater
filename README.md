# Мануал по скрипту и установке зависимостей для **Entware** с использованием **vi** редактора

Этот документ предоставляет подробное руководство по использованию и настройке скрипта для автоматического обновления конфигурации прокси-серверов в **Mihomo**. Скрипт скачивает и обрабатывает данные из JSON, получая информацию о прокси-серверах, проверяя задержку и страну, а затем обновляет файл конфигурации YAML.

---

## Оглавление

1. [Введение](#1-введение)
2. [Установка зависимостей](#2-установка-зависимостей)

   1. [Обновление репозиториев и установка зависимостей](#21-обновление-репозиториев-и-установка-зависимостей)
   2. [Установка **vim** (редактор vi)](#22-установка-vim-редактор-vi)
3. [Создание и сохранение скрипта](#3-создание-и-сохранение-скрипта)

   1. [Открытие файла для редактирования](#31-открытие-файла-для-редактирования)
   2. [Вставка скрипта](#32-вставка-скрипта)
   3. [Сохранение и выход](#33-сохранение-и-выход)
4. [Настройка прав доступа](#4-настройка-прав-доступа)
5. [Запуск скрипта](#5-запуск-скрипта)
6. [Автоматизация с использованием Cron](#6-автоматизация-с-использованием-cron)
7. [Проверка обновлений](#7-проверка-обновлений)
8. [Заключение](#8-заключение)

---

## 1. Введение

Скрипт предназначен для работы в среде **Entware**. Он обрабатывает список прокси-серверов (VLESS), скачивает данные, проверяет их и обновляет конфигурацию. Скрипт использует такие утилиты, как `curl`, `openssl`, `awk`, `grep` и другие для выполнения этих задач.

---

## 2. Установка зависимостей

Перед использованием скрипта необходимо установить несколько зависимостей, чтобы гарантировать корректную работу.

### 2.1 Обновление репозиториев и установка зависимостей

1. Подключитесь к устройству через SSH.
2. Выполните следующие команды для обновления репозиториев и установки необходимых пакетов:

```sh
opkg update
opkg install curl openssl grep awk vim
```

### 2.2 Установка **vim** (редактор vi)

Если у вас еще не установлен редактор **vi** (или **vim**), установите его с помощью команды:

```sh
opkg install vim
```

---

## 3. Создание и сохранение скрипта

### 3.1 Открытие файла для редактирования

Используйте **vi** для создания и редактирования файла скрипта.

```sh
vi /opt/bin/update_mihomo.sh
```

### 3.2 Вставка скрипта

Нажмите `i` для входа в режим редактирования и вставьте весь код скрипта.

```sh
#!/bin/sh

URL="https://raw.githubusercontent.com/tiagorrg/vless-checker/main/docs/keys.json"

OUT="/opt/etc/mihomo/proxy-providers/proxies.yaml"
TMP="/tmp/proxies.yaml"

JSON="/tmp/keys.json"
JSONTMP="/tmp/keys.json.tmp"

LAT="/tmp/latency.txt"
CACHE="/tmp/geo_cache.txt"

COUNT=0

mkdir -p /opt/etc/mihomo/proxy-providers

trap 'rm -f "$TMP" "$LAT" "${LAT}.sorted" "$JSONTMP"' EXIT

echo "[INFO] downloading JSON..."

curl -L --silent --show-error --fail "$URL" -o "$JSONTMP" || exit 1
mv "$JSONTMP" "$JSON"

[ ! -s "$JSON" ] && echo "[ERROR] empty JSON" && exit 1

> "$LAT"
[ ! -f "$CACHE" ] && touch "$CACHE"

# =========================
# FLAGS
# =========================
get_flag() {
  case "$1" in
         # Europe
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

    # Asia
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

    # North America
    CA) echo "🇨🇦" ;; CR) echo "🇨🇷" ;; CU) echo "🇨🇺" ;;
    DO) echo "🇩🇴" ;; SV) echo "🇸🇻" ;; GT) echo "🇬🇹" ;;
    HT) echo "🇭🇹" ;; HN) echo "🇭🇳" ;; JM) echo "🇯🇲" ;;
    MX) echo "🇲🇽" ;; NI) echo "🇳🇮" ;; PA) echo "🇵🇦" ;;
    US) echo "🇺🇸" ;;

    # South America
    AR) echo "🇦🇷" ;; BO) echo "🇧🇴" ;; BR) echo "🇧🇷" ;;
    CL) echo "🇨🇱" ;; CO) echo "🇨🇴" ;; EC) echo "🇪🇨" ;;
    GY) echo "🇬🇾" ;; PY) echo "🇵🇾" ;; PE) echo "🇵🇪" ;;
    SR) echo "🇸🇷" ;; UY) echo "🇺🇾" ;; VE) echo "🇻🇪" ;;

    # Africa
    DZ) echo "🇩🇿" ;; AO) echo "🇦🇴" ;; CM) echo "🇨🇲" ;;
    EG) echo "🇪🇬" ;; ET) echo "🇪🇹" ;; GH) echo "🇬🇭" ;;
    KE) echo "🇰🇪" ;; LY) echo "🇱🇾" ;; MA) echo "🇲🇦" ;;
    NG) echo "🇳🇬" ;; ZA) echo "🇿🇦" ;; TN) echo "🇹🇳" ;;
    UG) echo "🇺🇬" ;; ZW) echo "🇿🇼" ;;

    # Oceania
    AU) echo "🇦🇺" ;; NZ) echo "🇳🇿" ;; FJ) echo "🇫🇯" ;;
  esac
}

# =========================
# GEO CACHE
# =========================
get_country() {
  server="$1"

  cached=$(grep -m1 "^$server|" "$CACHE" 2>/dev/null | cut -d'|' -f2)

  [ -n "$cached" ] && {
    echo "$cached"
    return
  }

  geo=$(curl -s --max-time 2 "http://ip-api.com/json/$server")
  cc=$(echo "$geo" | grep -o '"countryCode":"[^"]*' | cut -d'"' -f4)

  [ -z "$cc" ] && cc="XX"

  echo "$server|$cc" >> "$CACHE"

  tail -n 1000 "$CACHE" > "${CACHE}.tmp" && mv "${CACHE}.tmp" "$CACHE"

  echo "$cc"
}

# =========================
# TLS LATENCY
# =========================
get_latency() {
  host="$1"
  port="$2"
  sni="$3"

  start=$(date +%s)

  timeout 2 openssl s_client \
    -connect "$host:$port" \
    -servername "$sni" \
    </dev/null >/dev/null 2>&1

  end=$(date +%s)

  echo $(( (end - start) * 1000 ))
}

# =========================
# PARSE
# =========================
echo "[INFO] parsing nodes..."

grep -oE 'vless://[^"]+' "$JSON" | sort -u | while IFS= read -r line; do

  echo "$line" | grep -q "@" || continue

  uuid=$(echo "$line" | sed -n 's|vless://\([^@]*\)@.*|\1|p')
  server=$(echo "$line" | sed -n 's|vless://[^@]*@\([^:]*\):.*|\1|p')
  port=$(echo "$line" | sed -n 's|.*:\([0-9]*\).*|\1|p')

  pbk=$(echo "$line" | sed -n 's|.*pbk=\([^&]*\).*|\1|p')
  sid=$(echo "$line" | sed -n 's|.*sid=\([^&]*\).*|\1|p')
  sni=$(echo "$line" | sed -n 's|.*sni=\([^&#]*\).*|\1|p')

  sid=$(echo "$sid" | cut -d'#' -f1)
  sni=$(echo "$sni" | cut -d'#' -f1)

  [ -z "$server" ] && continue
  [ -z "$port" ] && continue
  [ -z "$uuid" ] && continue
  [ -z "$pbk" ] && continue
  [ -z "$sid" ] && continue
  [ -z "$sni" ] && continue

  echo "$pbk" | grep -qE "^[A-Za-z0-9_-]{40,80}$" || continue
  echo "$sid" | grep -qE "^[0-9a-fA-F]{4,}$" || continue

  echo "[TEST] $server:$port"

  ms=$(get_latency "$server" "$port" "$sni")

  [ "$ms" -gt 1200 ] && continue

  cc=$(get_country "$server")
  flag=$(get_flag "$cc")

  echo "$ms|$cc|$server|$port|$uuid|$pbk|$sid|$sni|$flag" >> "$LAT"

done

sort -t"|" -k1,1n -k3,3 "$LAT" | awk -F'|' '!seen[$3]++' > "${LAT}.sorted"

echo "proxies:" > "$TMP"

while IFS="|" read -r ms cc server port uuid pbk sid sni flag; do

COUNT=$((COUNT+1))

cat >> "$TMP" <<EOF
- name: "$flag $cc | $server:$port (${ms} ms)"
  type: vless
  server: $server
  port: $port
  uuid: $uuid
  network: tcp
  tls: true
  udp: true
  servername: $sni
  flow: xtls-rprx-vision
  client-fingerprint: chrome
  reality-opts:
    public-key: "$pbk"
    short-id: "$sid"

EOF

done < "${LAT}.sorted"

# =========================
# APPLY + RELOAD
# =========================
if grep -q "server:" "$TMP"; then

  if ! cmp -s "$TMP" "$OUT"; then
    cp "$OUT" "$OUT.bak" 2>/dev/null
    mv "$TMP" "$OUT"

    echo "[INFO] YAML UPDATED"

    curl -s -X POST http://127.0.0.1:9090/proxies >/dev/null 2>&1

    echo "[INFO] Mihomo reloaded"

  else
    rm -f "$TMP"
    echo "[INFO] no changes"
  fi

else
  rm -f "$TMP"
  echo "[ERROR] invalid YAML blocked"
fi

echo "[INFO] total nodes: $COUNT"
```

### 3.3 Сохранение и выход

* После того как вставили код, нажмите `Esc` для выхода из режима редактирования.
* Введите `:wq` и нажмите `Enter`, чтобы сохранить и выйти.

---

## 4. Настройка прав доступа

Необходимо дать права на выполнение скрипта:

```sh
chmod +x /opt/bin/update_mihomo.sh
```

---

## 5. Запуск скрипта

Для запуска скрипта выполните команду:

```sh
/opt/bin/update_mihomo.sh
```

---

## 6. Автоматизация с использованием Cron

Если вы хотите автоматизировать выполнение скрипта, можно добавить его в cron:

```sh
crontab -e
```

Добавьте строку для выполнения скрипта каждые 30 минут:

```sh
*/30 * * * * /opt/bin/update_mihomo.sh
```

---

## 7. Проверка обновлений

После выполнения скрипта проверьте файл конфигурации:

```sh
cat /opt/etc/mihomo/proxy-providers/proxies.yaml
```

---

## 8. Заключение

Теперь у вас есть полностью настроенный скрипт для автоматического обновления конфигурации прокси-серверов в Mihomo.
