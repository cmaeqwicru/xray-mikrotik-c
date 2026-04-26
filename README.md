# xray-mikrotik

Запуск Xray VLESS Reality в контейнере на MikroTik RouterOS с автоматической настройкой маршрутизации.

## Конфигуратор

**https://cmaeqwicru.github.io/xray-mikrotik-c/configurator.html**

Вставьте VLESS-ссылку — конфигуратор сгенерирует готовый скрипт для вставки в терминал MikroTik.

## Что делает скрипт

1. Создаёт скрипт удаления (`<prefix>-remove`)
2. Настраивает сеть контейнера: veth-интерфейс, маршрутизацию, NAT
3. Добавляет контейнер с образом `ghcr.io/cmaeqwicru/xray-mikrotik:latest`
4. Настраивает DNS и правила маршрутизации для выбранных сервисов

После вставки дождитесь загрузки образа и запустите контейнер:
```
/container start [find hostname=<prefix>]
```

## Сценарии маршрутизации

- **DNS FWD** — выбранные сервисы через VPN по DNS-записям
- **Не-RU трафик** — весь нероссийский трафик через VPN
- **Только туннель** — ручная настройка адресного листа

## Добавление домена (DNS FWD)

Чтобы добавить домен в маршрутизацию после установки, выполните на роутере:

```
/ip dns static add name=example.com type=FWD forward-to=GoogleDNS match-subdomain=yes address-list=xray-vless comment=xray-vless-dns
```

- `name` — домен (без `www`, с `match-subdomain=yes` покрывает все поддомены)
- `forward-to` — имя DoH-форвардера, созданного скриптом (`GoogleDNS`, `CloudFlare` и т.д.)
- `address-list` — имя адресного листа (совпадает с префиксом установки, по умолчанию `xray-vless`)

После добавления сбросьте кэш DNS и откройте сайт с устройства:

```
/ip dns cache flush
```

## Требования

- RouterOS 7.22+ с поддержкой контейнеров
- Лицензия L4 или выше (для контейнеров)
- Минимум 256 МБ RAM

## Удаление

```
/system/script/run <prefix>-remove
```

## Образ

Мультиархитектурный образ собирается автоматически через GitHub Actions при обновлении `Containers/`.

Поддерживаемые архитектуры: `linux/amd64`, `linux/arm64`, `linux/arm/v7`

Компоненты: [Xray-core](https://github.com/XTLS/Xray-core) + [tun2socks](https://github.com/xjasonlyu/tun2socks)
