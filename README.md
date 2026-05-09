---

# 🛠️ Мануал по установке и настройке **Mihomo Auto VLESS Reality Updater**

Этот мануал поможет вам быстро и удобно настроить автоматическое обновление конфигурации прокси-серверов для **Mihomo** с использованием **Entware**. Скрипт загрузит актуальные данные о прокси-серверах, проверит их на задержку, страну и обновит конфигурационный файл в автоматическом режиме.

---

## 📑 Оглавление

1. [📝 Введение](#1-введение)
2. [⚙️ Автоматическая установка и настройка](#2-автоматическая-установка-и-настройка)
3. [📡 Тестирование на устройствах](#3-тестирование-на-устройствах)
4. [🔧 Ручная установка](#4-ручная-установка) (Скрыто)

---

## 1. 📝 Введение

**Mihomo Auto VLESS Reality Updater** — это скрипт, предназначенный для работы в среде **Entware**, который автоматически обновляет список прокси-серверов в формате YAML. Скрипт выполняет следующие задачи:

* 🌍 Скачивает данные о прокси-серверах с удалённого источника.
* ⏱ Проверяет задержку (latency) и страну сервера.
* 🔄 Обновляет конфигурационный файл, добавляя только качественные и быстрые серверы.

Для выполнения этих задач скрипт использует такие утилиты, как `curl`, `openssl`, `awk`, `grep` и другие.

⚠️ **Важно:** Перед установкой убедитесь, что на вашем роутере уже установлены **Entware** и **Mihomo**. Скрипт работает только при наличии этих программ на устройстве. Если их нет, вам необходимо предварительно установить их.

---

## 2. ⚙️ Автоматическая установка и настройка

Чтобы ускорить процесс установки и настройки всего необходимого для работы скрипта, достаточно выполнить одну команду:

### 📥 Выполнение команды для автоматической установки:

```sh id="1uzl3v"
curl -sSL https://raw.githubusercontent.com/SPIRITUFA/Mihomo-Auto-VLESS-Reality-Updater/main/install_dependencies.sh | bash
```

### 🛠️ Что делает эта команда:

* 🔽 **Загружает и выполняет скрипт** для установки всех необходимых зависимостей.
* ⚙️ **Устанавливает все зависимости**, включая `curl`, `openssl`, `awk`, `vim` и другие утилиты, которые необходимы для работы.
* 🔓 **Даёт права на выполнение** для скриптов.
* 🚀 **Автоматически настраивает и запускает** скрипт, обеспечивая правильную работу с конфигурацией прокси-серверов.

После выполнения этой команды все компоненты будут установлены, а ваш скрипт настроен и готов к использованию.

---

## 3. 📡 Тестирование на устройствах

Скрипт был протестирован на следующих устройствах:

* **Keenetic Giga KN-1011**
* **Keenetic Giga KN-1012**
* **NetCraze Ultra NC-1812**

Эти роутеры продемонстрировали стабильную работу скрипта, включая автоматическое обновление конфигурации и корректную обработку прокси-серверов.

---

## 4. 🔧 Ручная установка

<details>
  <summary>Нажмите для развертывания инструкции по ручной установке</summary>

### 4.1 Установка зависимостей

Для работы скрипта необходимо установить несколько зависимостей. Откройте терминал и выполните следующие шаги:

1. Подключитесь к вашему устройству через SSH.
2. Выполните обновление репозиториев:

```sh id="qfimm1"
opkg update
```

3. Установите необходимые пакеты:

```sh id="5jj0lh"
opkg install curl openssl grep gawk vim
```

Эти пакеты обеспечат корректную работу скрипта.

### 4.2 Создание и настройка скрипта

1. **Откройте файл для редактирования**:

   Используйте **vim** или **vi** для создания нового файла:

   ```sh
   vi /opt/bin/update_mihomo.sh
   ```

2. **Вставьте код скрипта**:

   Нажмите `i` для перехода в режим редактирования и вставьте следующий код:

   ```sh
   #!/bin/sh

   URL="https://raw.githubusercontent.com/SPIRITUFA/Mihomo-Auto-VLESS-Reality-Updater/main/keys.json"
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
     [ -n "$cached" ] && { echo "$cached"; return; }

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

3. **Сохраните и выйдите**:

   Нажмите `Esc`, затем введите `:wq` и нажмите `Enter`.

### 🔓 Настройка прав доступа

Чтобы скрипт был исполнимым, задайте права на выполнение:

```sh id="76b7y4"
chmod +x /opt/bin/update_mihomo.sh
```

</details>

---
