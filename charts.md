# dcape charts

## Arch

```mermaid
%%{init: {"flowchart": {"defaultRenderer": "elk", "curve": "linear"}} }%%
flowchart TD
  subgraph web[Internet]
    wc[Web client]
    le[Lets Encrypt]
    devops[DevOps]
  end
  subgraph dcape[DCAPE]
    auth[narra]
    cicd[woodpecker]
    config[enfist]
    db[postgres]
    manager[portainer]
    ns[powerdns]
    router[traefik]
    vcs[gitea]
    app

    wc-- Request -->router
    router-- certificates -->le
    le-- dns-01 -->ns
    router-- dns-01 -->ns
    router-- auth for private -->auth
    auth-- OAuth2 -->vcs
    vcs-- Deploy request -->cicd
    cicd-- Config request -->config
    router--Request -->app
    auth-- Access granted -->router
    vcs-- vcs data -->db
    cicd-- cicd data -->db
    config-- config data -->db
    ns-- zone data -->db

    devops-- dashboard --> router
    devops-- dashboard --> ns
    devops-- config --> config
    devops-- docker manage --> manager
    devops-- app repo manage --> vcs
    devops-- CICD manage --> cicd
    

  end
```
## Install dcape

```bash
MY_HOST=demo.dcape.ru
LE_ADMIN=admin@dcape.ru

git clone https://github.com/dopos/dcape.git
cd dcape
make install ACME=wild DNS=wild DCAPE_DOMAIN=${MY_HOST} \
  TRAEFIK_ACME_EMAIL=${LE_ADMIN} PDNS_LISTEN=$(dig +short $MY_HOST):53
make echo-gitea-admin-pass
```

TODO: скринкаст окна браузера, где мы

* создаем сервер у хостера
* заходим в консоль
* ставим гит и докер
* запускаем инсталл
* после установки - проверяем все сервисы

## Install app (1st Deploy)

```mermaid
%%{init: {"flowchart": { "curve": "linear"}} }%%
sequenceDiagram
    autonumber
    participant A as DevOps
    participant G as Gitea
    participant W as Woodpecker
    participant C as Enfist
    participant D as Docker
    participant T as Traefik
    participant LE as LetsEncrypt

    A->>G: Create repo
    A->>W: Activate repo
    W->>G: Install webhook
    A->>G: Push changes
    G->>W: Begin deploy
    W->>G: > Get repo clone
    W->>C: < Get .env for repo--branch
    C->>W: NOT_FOUND
    W->>C: > Generated .env.sample
    W->>A: Deploy aborted: config
    A->>C: < Get .env.sample
    A->>C: > Edited .env
    A->>W: Repeat job
    W->>C: < Get .env for repo--branch
    Note right of W: Run docker compose with .env
    D->>T: New container
    T->>LE: < Request certificate
    Note left of T: Service is ready

```

## Update

```mermaid
%%{init: {"flowchart": { "curve": "linear"}} }%%
sequenceDiagram
    autonumber
    participant A as DevOps
    participant G as Gitea
    participant W as Woodpecker
    participant C as Enfist

    A->>G: Push changes
    G->>W: Begin deploy
    W->>G: > Get repo clone
    W->>C: < Get .env for repo--branch
    Note right of W: Run docker compose with .env
    Note left of W: Service is ready

```

## Serve

```mermaid
%%{init: {"flowchart": { "curve": "linear"}} }%%
sequenceDiagram
  autonumber
  participant U as User
  participant T as Traefik
  participant N as Narra
  participant G as Gitea
  participant A as Application
  U->>T: HTTPS request
  loop if URL protected
    T->>N: access request
    N->>G: OAuth2
    N->>T: <Accept. User=%USER%
  end
  T->>A: HTTP request
  A->>T: HTTP response
  T->>U: HTTPS response
```
