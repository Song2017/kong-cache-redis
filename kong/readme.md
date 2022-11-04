## start with docker
### postgres数据库模式
1. start postgres database
```
docker run -dt --name kong-database  -p 5432:5432 \
                -e "POSTGRES_USER=kong" -e "POSTGRES_PASSWORD=Passw0rd" \
                -e "POSTGRES_DB=kong" -e "POSTGRES_HOST_AUTH_METHOD=trust" \
                postgres:9.6
```
2. prepare db
```
docker run --rm \
    --link kong-database:kong-database \
    -e "KONG_LOG_LEVEL=debug" \
    -e "KONG_DATABASE=postgres" \
    -e "KONG_PG_HOST=kong-database" -e "KONG_PG_PASSWORD=Passw0rd" \
    -e "KONG_CASSANDRA_CONTACT_POINTS=kong-database" \
    kong:2.2.0-alpine kong migrations bootstrap
```
3. start kong
```
docker run -dt --name kong -v $PWD/kong/kong.conf:/etc/kong/kong.conf \
    -v $PWD/kong:/home/custom/kong \
    --link kong-database:kong-database \
    -e "KONG_PG_HOST=kong-database" \
    -e "KONG_LOG_LEVEL=info" \
    -e "KONG_ADMIN_LISTEN=0.0.0.0:8001, 0.0.0.0:8444 ssl" \
    -p 8000:8000  -p 8443:8443  -p 8001:8001  -p 8444:8444 \
    kong:2.2.0-alpine
```
### Configuring a Service
https://docs.konghq.com/gateway-oss/2.2.x/getting-started/configuring-a-grpc-service/
1. add service
即Kong用来指代其管理的上游API和微服务的名称
```
curl -i -X POST \
  --url http://localhost:8001/services/ \
  --data 'name=example-service' \
  --data 'url=http://mockbin.org/request'
```
2. add route
路线指定到达Kong后如何将请求发送到其service。单个服务可以具有多个路由。
```
curl -i -X POST \
  --url http://localhost:8001/services/example-service/routes \
  --data 'hosts[]=example.com'
```
3. 通过Kong转发您的请求
```
curl -i -X GET \
  --url http://localhost:8000/ \
  --header 'Host: example.com'
```
### Enabling Plugins
添加app code auth插件 key-auth
```
curl -i -X POST \
  --url http://localhost:8001/services/example-service/plugins/ \
  --data 'name=key-auth'

curl -i -X GET \
  --url http://localhost:8000/ \
  --header 'Host: example.com'
```

### Adding Consumers
添加通过app code
```
curl -i -X POST \
  --url http://localhost:8001/consumers/ \
  --data "username=Jason"

add key
curl -i -X POST \
  --url http://localhost:8001/consumers/Jason/key-auth/ \
  --data 'key=ENTER_KEY_HERE'

curl -i -X GET \
  --url http://localhost:8000 \
  --header "Host: example.com" \
  --header "apikey: ENTER_KEY_HERE"
```
### Plugin Development Guide
1. Implementing custom logic
 kong.plugins.<plugin_name>.<module_name>
    module_name:  handler.lua, schema.lua
2. (un)Installing your plugin
```
!! docker run -v $PWD/kong:/home/custom/kong
kong.conf
lua_package_path = /etc/?.lua;./?.lua;./?/init.lua;;
plugins = bundled,my-custom-plugin
```
3. Enabling custom plugins
route&service should be prepared: example-service
```
curl -i -X POST \
  --url http://localhost:8001/services/ \
  --data 'name=example-service' \
  --data 'url=http://mockbin.org/request'

curl -i -X POST \
  --url http://localhost:8001/services/example-service/routes \
  --data 'hosts[]=example.com'

curl -i -X POST \
  --url http://localhost:8001/services/example-service/plugins/ \
  --data 'name=my-custom-plugin' \
  -d "config.environment=development"

curl -i -X GET \
  --url http://localhost:8000/ \
  --header 'Host: example.com'
```

test Kong Cache with custom plugin: check value of X-API-Key 
```
hset ht field val0
curl -i -X GET \
  --url http://localhost:8000/ \
  --header 'Host: example.com' \
  --header 'x-cache-auth: cache_name' 

hset ht field val1
curl -i -X GET \
  --url http://localhost:8000/ \
  --header 'Host: example.com' \
  --header 'x-cache-auth: cache_name'
curl -i -X GET \
  --url http://localhost:8000/ \
  --header 'Host: example.com' \
  --header 'x-del-auth: cache_name'
curl -i -X GET \
  --url http://localhost:8000/ \
  --header 'Host: example.com' \
  --header 'x-cache-auth: cache_name'
```

### 无数据库模式
KONG_DATABASE=off 模式下不能创建新的services
```
database = off
declarative_config = /kong/kong.yml
```


## Run pgadmin
```
docker run -p 80:80 \
    -e 'PGADMIN_DEFAULT_EMAIL=user@domain.com' \
    -e 'PGADMIN_DEFAULT_PASSWORD=SuperSecret' \
    -e 'PGADMIN_CONFIG_ENHANCED_COOKIE_PROTECTION=True' \
    -e 'PGADMIN_CONFIG_LOGIN_BANNER="Authorised users only!"' \
    -e 'PGADMIN_CONFIG_CONSOLE_LOG_LEVEL=10' \
    -d dpage/pgadmin4
```

## Setup Redis
```
# docker run -dt --name redis -p 6379:6379 redis:6 redis-server
> docker exec -it redis redis-cli
> hset ht field val_original
```
