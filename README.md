# kong-cache-redis
Kong cache with redis. And we can have a try with docker-compose easily.

## Start Kong with Docker Compose
Bring up kong cluster
```bash
docker-compose -f docker-compose.kong.yml up
```

## Kong Cache with Redis
1. [Custom Kong Plugin](./kong/readme.md#plugin-development-guide)
2. [Test Kong Cache](./kong/readme.md#test-kong-cache)