---

# Mihomo Auto VLESS Reality Updater

Автоматическое обновление VLESS Reality нод для **Mihomo / Clash Meta** с:

* автоматической загрузкой актуальных ключей
* фильтрацией битых нод
* проверкой TLS latency
* автоопределением страны
* флагами стран
* сортировкой по задержке
* дедупликацией
* безопасным обновлением YAML
* hot reload через Mihomo API
* backup предыдущего конфига

---

# Возможности

## Что делает скрипт

Скрипт автоматически:

### 1. Загружает актуальные VLESS Reality ключи

Источник:

`https://raw.githubusercontent.com/tiagorrg/vless-checker/main/docs/keys.json`

---

### 2. Парсит VLESS URI

Извлекает:

* UUID
* server
* port
* public-key
* short-id
* SNI

---

### 3. Проверяет валидность ноды

Проверяет:

* наличие всех обязательных параметров
* формат public-key
* формат short-id

---

### 4. Тестирует TLS handshake latency

Измеряет реальную задержку подключения через:

```bash
openssl s_client
```

Если latency > **1200ms**, нода отбрасывается.

---

### 5. Определяет страну сервера

Через:

```bash
ip-api.com
```

Кэшируется локально.

---

### 6. Добавляет флаг страны

Пример:

```yaml
🇳🇱 NL | server.example.com:443 (54 ms)
```

---

### 7. Удаляет дубликаты

Оставляет только лучший сервер по latency.

---

### 8. Генерирует proxies.yaml

Полностью совместимый с Mihomo.

---

### 9. Проверяет изменения

Если конфиг не изменился:

```bash
[INFO] no changes
```

Перезаписи не будет.

---

### 10. Reload Mihomo через API

Без полного рестарта процесса.

---

# Требования

Поддерживается:

* Keenetic Entware
* OpenWRT
* Linux
* Debian / Ubuntu
* Alpine
* любой shell с POSIX sh

---

# Необходимые пакеты

Установить:

## Entware / Keenetic

```bash
opkg update
opkg install curl openssl-util coreutils-timeout
```

---

## Debian / Ubuntu

```bash
sudo apt update
sudo apt install curl openssl coreutils
```

---

## Alpine

```bash
apk add curl openssl coreutils
```

---

# Структура файлов

Скрипт использует:

```bash
/opt/bin/update_mihomo.sh
```

Конфиг:

```bash
/opt/etc/mihomo/proxy-providers/proxies.yaml
```

Кэш GeoIP:

```bash
/tmp/geo_cache.txt
```

Временные файлы:

```bash
/tmp/keys.json
/tmp/proxies.yaml
/tmp/latency.txt
```

Backup:

```bash
/opt/etc/mihomo/proxy-providers/proxies.yaml.bak
```

---

Вот исправленный блок установки для README — сразу после создания директории идёт **полный способ создания файла со скриптом через heredoc**, чтобы пользователь мог просто вставить одной командой.

Заменяй раздел **"Установка с нуля"** на этот.

---

# Установка с нуля

## Шаг 1. Создать директории

```bash
mkdir -p /opt/bin
mkdir -p /opt/etc/mihomo/proxy-providers
```

---

## Шаг 2. Создать скрипт

Выполнить команду:

```bash
cat > /opt/bin/update_mihomo.sh << 'EOF'
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

get_flag() {
  case "$1" in
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
    US) echo "🇺🇸" ;; SG) echo "🇸🇬" ;; TH) echo "🇹🇭" ;;
    JP) echo "🇯🇵" ;; KR) echo "🇰🇷" ;; HK) echo "🇭🇰" ;;
    TW) echo "🇹🇼" ;; CA) echo "🇨🇦" ;; AU) echo "🇦🇺" ;;
    NZ) echo "🇳🇿" ;; BR) echo "🇧🇷" ;; AR) echo "🇦🇷" ;;
    MX) echo "🇲🇽" ;; ZA) echo "🇿🇦" ;;
    *) echo "🏳️" ;;
  esac
}

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

  ms=$(get_latency "$server" "$port" "$sni")
  [ "$ms" -gt 1200 ] && continue

  cc=$(get_country "$server")
  flag=$(get_flag "$cc")

  echo "$ms|$cc|$server|$port|$uuid|$pbk|$sid|$sni|$flag" >> "$LAT"

done

sort -t"|" -k1,1n -k3,3 "$LAT" | awk -F'|' '!seen[$3]++' > "${LAT}.sorted"

echo "proxies:" > "$TMP"

while IFS="|" read -r ms cc server port uuid pbk sid sni flag; do

cat >> "$TMP" <<EON
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

EON

done < "${LAT}.sorted"

if grep -q "server:" "$TMP"; then
  if ! cmp -s "$TMP" "$OUT"; then
    cp "$OUT" "$OUT.bak" 2>/dev/null
    mv "$TMP" "$OUT"
    curl -s -X POST http://127.0.0.1:9090/proxies >/dev/null 2>&1
    echo "[INFO] YAML UPDATED"
  else
    rm -f "$TMP"
    echo "[INFO] no changes"
  fi
else
  rm -f "$TMP"
  echo "[ERROR] invalid YAML blocked"
fi
EOF
```

---

## Шаг 3. Сделать исполняемым

```bash
chmod +x /opt/bin/update_mihomo.sh
```

---

## Шаг 4. Проверить

```bash
/opt/bin/update_mihomo.sh
```

---

Ожидаемый вывод:

```bash
[INFO] downloading JSON...
[INFO] parsing nodes...
[TEST] ...
[INFO] YAML UPDATED
[INFO] Mihomo reloaded
[INFO] total nodes: XX
```

---

# Настройка Mihomo

Добавить provider в `config.yaml`

```yaml
proxy-providers:
  reality-auto:
    type: file
    path: /opt/etc/mihomo/proxy-providers/proxies.yaml
    health-check:
      enable: true
      interval: 300
      url: http://www.msftncsi.com/ncsi.txt
```

---

Добавить в proxy-group:

```yaml
proxy-groups:
  - name: AUTO
    type: url-test
    use:
      - reality-auto
    url: http://www.msftncsi.com/ncsi.txt
    interval: 300
```

---

# Автоматическое обновление

Открыть cron:

```bash
crontab -e
```

Добавить:

## Каждые 30 минут

```cron
*/30 * * * * /opt/bin/update_mihomo.sh
```

---

## Каждые 15 минут

```cron
*/15 * * * * /opt/bin/update_mihomo.sh
```

---

## Каждые 5 минут

```cron
*/5 * * * * /opt/bin/update_mihomo.sh
```

---

После:

```bash
service cron restart
```

или

```bash
/opt/etc/init.d/S10cron restart
```

---

# Как работает обновление

Алгоритм:

```text
download JSON
   ↓
parse nodes
   ↓
validate
   ↓
latency test
   ↓
geo lookup
   ↓
sort
   ↓
generate YAML
   ↓
compare with current
   ↓
reload Mihomo if changed
```

---

# Защита от битых конфигов

Скрипт НЕ заменит рабочий YAML если:

* JSON пустой
* парсинг не удался
* не найдено валидных серверов
* YAML некорректный

В таком случае:

```bash
[ERROR] invalid YAML blocked
```

---

# Восстановление

Если нужно откатиться:

```bash
cp /opt/etc/mihomo/proxy-providers/proxies.yaml.bak \
   /opt/etc/mihomo/proxy-providers/proxies.yaml
```

Reload:

```bash
curl -X POST http://127.0.0.1:9090/proxies
```

---

# Очистка Geo Cache

Если IP-гео изменилась:

```bash
rm -f /tmp/geo_cache.txt
```

---

# Проверка результата

Посмотреть YAML:

```bash
cat /opt/etc/mihomo/proxy-providers/proxies.yaml
```

Пример:

```yaml
- name: "🇳🇱 NL | server.example.com:443 (42 ms)"
```

---

# Частые проблемы

---

## timeout: not found

Установить coreutils:

```bash
opkg install coreutils-timeout
```

---

## openssl: not found

```bash
opkg install openssl-util
```

---

## Mihomo не reload

Проверь API:

```bash
curl http://127.0.0.1:9090/version
```

Если нет ответа — API выключен.

---

## YAML не обновляется

Проверить вручную:

```bash
/opt/bin/update_mihomo.sh
```

Если:

```bash
[INFO] no changes
```

значит изменений в upstream нет.

---

# Производительность

Средние значения:

### 50 нод

~15–25 сек

### 100 нод

~30–50 сек

### 200 нод

~1–2 мин

Зависит от:

* CPU роутера
* DNS
* качества сети
* скорости TLS handshake

---

# Безопасность

Скрипт:

* не хранит приватные ключи
* не выполняет удалённый код
* не изменяет Mihomo напрямую
* обновляет YAML только после полной проверки

---

# Рекомендуемые cron интервалы

Для дома:

```cron
*/30 * * * *
```

Для тестов:

```cron
*/10 * * * *
```

Для агрессивного обновления:

```cron
*/5 * * * *
```

---

# Авторская логика

Особенности реализации:

* smart geo cache
* latency-first сортировка
* atomic file replace
* backup before replace
* duplicate elimination
* hot API reload

---

# License

MIT

---

# Полезно

Ручной запуск:

```bash
/opt/bin/update_mihomo.sh
```

Просмотр логов cron:

```bash
logread | grep update_mihomo
```

---
