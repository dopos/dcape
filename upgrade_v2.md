# Upgrade dcape v2 to v3

Апгрейд заключается в том, чтобы развернуть v3 с конфигами из v2 и перенести из v2 каталог var.
При апгрейде сервисы dcape будут ненадолго остановлены, остальные приложения не затрагиваются.

Надо учесть, что v3 для CI/CD использует woodpecker вместо drone, но миграция БД не производится, т.е. деплой приложений (и линк с gitea) надо будет повторно настроить

## Этап 1. Подготовка конфигурации

Исходные данные: dcape развернут в `/opt/dcape`

```sh
cd /opt
git clone https://github.com/dopos/dcape.git dcape3
cd dcape3
cp ../dcape/.env ./.env.bak
sed -i "s|DCAPE_VAR=var|#DCAPE_VAR=var|" ./env.bak
make config-upgrade
```

Dcape развернут, конфиги готовы. Можно проверить и двигаться дальше

## Этап 2. Переезд

```sh
cd /opt/dcape
make down
cd ..
mv dcape dcape2
mv dcape3 dcape
mv dcape2/var dcape
cd dcape
make up
```

В этом месте может возникнуть ошибка вида
 network dcape_intra was found but has incorrect label com.docker.compose.network set to "dcape_intra"

Это связано с тем, что при docker не определяет сети dcape,dcape_intra как свои.

Решение:

Если сеть не используется, ее можно удалить командой
```
docker network rm dcape_intra
```

Для сети dcape (ее не удалить, если есть запущенные контейнры) проблема решается добавлением в docker-compose.yml строки `external: true` (блок networks/default)

## Этап 3. Донастройка

В этот момент БД уже доступна и можно провести инициализацию CI/CD:

```sh
make after-upgrade
make up
```

### Корректировка реквизитов drone в gitea

В списке приложений (/user/settings/applications) находим drone в блоке "Управление приложениями OAuth2"
и там меняем "URI переадресации"

Пример:
* Было: https://drone.cx.elfire.ru/login
* Стало: https://cicd.cx.elfire.ru/authorize



