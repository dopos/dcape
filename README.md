<p align="center">
  <span>English</span> |
  <a href="README.ru.md#doposdcape">Pусский</a>
</p>

---
# dopos/dcape
> Docker-compose application environment

[![GitHub Release][1]][2]
![GitHub code size in bytes][3]
[![GitHub license][4]][5]

[1]: https://img.shields.io/github/release/dopos/dcape.svg
[2]: https://github.com/dopos/dcape/releases
[3]: https://img.shields.io/github/languages/code-size/dopos/dcape.svg
[4]: https://img.shields.io/github/license/dopos/dcape.svg
[5]: LICENSE

[Dcape](https://github.com/dopos/dcape) is a set of files for [make](https://www.gnu.org/software/make/) and [docker-compose](https://docs.docker.com/compose/), designed to solve the following tasks:

* using `make up` run applications which needs
  * **shared port** (ex. 80)
  * **database**
* using `git push` **deploy applications remotely** on single or several computers
* **manage app configs** through API or web-interface
* **limit** via given user group **access** to used applications interfaces
* support for letsencrypt **wildcard-domains**
* **manage docker objects**

## Applications

For solving of above-mentioned tasks **dcape** uses docker-images of the following applications:

* **shared port**  - [traefik](https://traefik.io/)
  * **database** - [postgresql](https://www.postgresql.org) 
* **deploy applications remotely** - [drone](https://github.com/drone) (on every computer) and [gitea](https://gitea.io/) on someone
* **manage app configs** - [enfist](https://github.com/apisite/app-enfist)
* **limit access** - [narra](https://github.com/dopos/narra), [gitea](https://gitea.io/) organization used as user group
* **wildcard-domains** - [powerdns](https://www.powerdns.com/)
* **manage docker objects** - [portainer](https://portainer.io/)

## Usage examples

### Deploy app local

Requirements:
* linux computer with docker and dcape
* hostnames registered in /etc/hosts or internal DNS (for example - `mysite.dev.lan`, `www.mysite.dev.lan`) pointing to this computer

#### Static site with nginx

```bash
$ git clone -b v2 --single-branch --depth 1 https://github.com/dopos/dcape-app-nginx-sample.git
..
$ cd dcape-app-nginx-sample
$ make init up APP_SITE=mysite.dev.lan
..
Creating mysite-dev-lan_www_1 ... done
```

That's all - `http://mysite.dev.lan/` and `http://www.mysite.dev.lan/` are working.

### Install dcape without gitea

Requirements:
* linux computer with docker and [dependensies](#Dependensies) installed
* DNS records for wildcard-domain `*.srv1.domain.tld`
* Gitea $TOKEN created

```bash
MY_HOST=${MY_HOST:-srv1.domain.tld}
MY_IP=${MY_IP:-192.168.23.10}
LE_ADMIN=${LE_ADMIN:-admin@domain.tld}
GITEA_URL=${GITEA_URL:-https://git.domain.tld}
GITEA_ORG=${GITEA_ORG:-dcape}
GITEA_USER=${GITEA_USER:-admin}

$ git clone -b v2 --single-branch --depth 1 https://github.com/dopos/dcape.git
..
$ cd dcape
$ make install ACME=wild DNS=wild DCAPE_DOMAIN=$MY_HOST \
  TRAEFIK_ACME_EMAIL=${LE_ADMIN} \
  NARRA_GITEA_ORG=${GITEA_ORG} \
  DRONE_ADMIN=${GITEA_USER} \
  PDNS_LISTEN=${MY_IP}:53 \
  GITEA=${GITEA_URL}
..
Running dc command: up -d db powerdns traefik narra enfist drone portainer
Dcape URL: https://srv1.domain.tld
------------------------------------------
Creating network "dcape" with driver "bridge"
Creating dcape_narra_1         ... done
Creating dcape_db_1            ... done
Creating dcape_drone-compose_1 ... done
Creating dcape_portainer_1     ... done
Creating dcape_traefik_1       ... done
Creating dcape_drone-rd_1      ... done
Creating dcape_drone_1         ... done
Creating dcape_powerdns_1      ... done
Creating dcape_enfist_1        ... done

```

That's all - server `srv1.domain.tld` ready for apps deployment, used **dcape** applications are accessible via `https://srv1.domain.tld`.

## Dependensies

* [linux](https://ubuntu.com/download)
* [docker](https://docs.docker.com/engine/install/ubuntu/)
* `sudo apt -y install git make sed curl jq`

## Documentation

See [dopos.github.io/dcape](https://dopos.github.io/en/dcape)

## License

The MIT License (MIT), see [LICENSE](LICENSE).

Copyright (c) 2020 Aleksei Kovrizhkin <lekovr+dopos@gmail.com>