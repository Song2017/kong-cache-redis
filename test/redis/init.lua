local redis = require "resty.redis"

local kong = kong

local function is_present(str)
    return str and str ~= "" and str ~= null
end

local sock_opts = {}

return function(conf)
    local red = redis:new()
    red:set_timeout(conf.redis_timeout)

    sock_opts.pool = conf.redis_database and conf.redis_host .. ":" .. conf.redis_port .. ":" .. conf.redis_database
    local ok, err = red:connect(conf.redis_host, conf.redis_port, sock_opts)
    kong.log.debug("connection pool:", sock_opts.pool)
    if not ok then
        kong.log.err("failed to connect to Redis: ", err)
        return nil, err
    end

    local times, err = red:get_reused_times()
    if err then
        kong.log.err("failed to get connect reused times: ", err)
        return nil, err
    end

    if times == 0 then
        if is_present(conf.redis_password) then
            local ok, err = red:auth(conf.redis_password)
            if not ok then
                kong.log.err("failed to auth Redis: ", err)
                return nil, err
            end
        end

        if conf.redis_database ~= 0 then
            -- Only call select first time, since we know the connection is shared
            -- between instances that use the same redis database

            local ok, err = red:select(conf.redis_database)
            if not ok then
                kong.log.err("failed to change Redis database: ", err)
                return nil, err
            end
        end
    end
    return red
end

