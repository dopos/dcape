# Варианты настройки DNS

## /etc/hosts, для локального использования

```bash
grep -q git.dev.lan /etc/hosts || \
sudo bash -c 'cat >> /etc/hosts <<EOF

127.0.0.1 dev.lan
127.0.0.1 git.dev.lan
127.0.0.1 drone.dev.lan
127.0.0.1 port.dev.lan
127.0.0.1 ns.dev.lan

EOF
'
```

## dnsmasq, для локального использования
```bash
sudo bash -c 'echo "address=/.dev.lan/127.0.0.1" > /etc/NetworkManager/dnsmasq.d/dev.lan.conf'
sudo service network-manager reload
```

## DNS зона, индивидуальная регистрация

```
srv1.domain.tld.        A       192.168.23.10
git.srv1.domain.tld.    A       192.168.23.10
drone.srv1.domain.tld.  A       192.168.23.10
port.srv1.domain.tld.   A       192.168.23.10
ns.srv1.domain.tld.     A       192.168.23.10
```

## DNS зона, wildcard-domain

```
srv1.domain.tld.        A       192.168.23.10
*.srv1.domain.tld.      A       192.168.23.10
```

## DNS зона, wildcard-domain с выделенным сервером для поддержки wildcard сертификатов Let's Encrypt

Для регистрации wildcard сертификатов traefik редактирует зону по АПИ. Чтобы не давать ему доступ к основной DNS-зоне, можно для каждого сервера создать выделенную зону (в примере - `srv1.domain.tld`) и директивой `CNAME` делегировать управление сертификатами этой зоны отдельному серверу (в примере - серверу `ns.srv1.domain.tld`, т.е. локальному DNS). Используемая в **dcape v2** версия traefik это уже поддерживает.

```
srv1.domain.tld.                    A       192.168.23.10
*.srv1.domain.tld.                  A       192.168.23.10

acme-srv1.domain.tld.               NS       ns.srv1.domain.tld
_acme-challenge.srv1.domain.tld.    CNAME    acme-srv1.domain.tld
_acme-challenge.*.srv1.domain.tld.  CNAME    acme-srv1.domain.tld
```

Команда инициализации **dcape** для этого примера:

```bash
make init ACME=wild DNS=wild DCAPE_DOMAIN=srv1.domain.tld \
  TRAEFIK_ACME_EMAIL=admin@domain.tld \
  PDNS_LISTEN=192.168.23.10:53
```
В `PDNS_LISTEN` порт изменен на стандартный (по умолчанию: 54) и задан ip, чтобы не возникало конфликта с локальным резолвером.

См. также: [настройка связки taefik-powerdns](/apps/traefik/Makefile#L98) для `DNS=wild`