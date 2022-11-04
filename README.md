# LabSpace
lab space.

## Development
Bring up kong cluster:
```bash
docker-compose -f docker-compose.kong.yml up
```

## PGAdmin
### Access to PgAdmin: 
* **URL:** [http://localhost:5050](http://localhost:5050)
* **Username:** user@domain.com (as a default)
* **Password:** SuperSecret (as a default)

### Add a new server in PgAdmin:
* **PostgresHost** as `POSTGRES_HOST`, by default: `kong-database`

## Kong
1. [Configuring a Service](./kong/readme.md#configuring-a-service)
2. [Enabling Plugins](./kong/readme.md#enabling-plugins)
3. [Adding Consumers](./kong/readme.md#adding-consumers)
4. [Enabling Plugins](./kong/readme.md#plugin-development-guide)