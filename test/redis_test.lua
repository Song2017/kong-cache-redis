-- If you're not sure your plugin is executing, uncomment the line below and restart Kong
-- then it will throw an error which indicates the plugin is being loaded at least.
-- assert(ngx.get_phase() == "timer", "The world is coming to an end!")
---------------------------------------------------------------------------------------------
-- In the code below, just remove the opening brackets; `[[` to enable a specific handler
--
-- The handlers are based on the OpenResty handlers, see the OpenResty docs for details
-- on when exactly they are invoked and what limitations each handler has.
---------------------------------------------------------------------------------------------
local redquery = require "lab_space.test.redquery"
local util = require "lab_space.test.util"

local function concat_lists(t1, t2)
    for _, v in ipairs(t2) do
        table.insert(t1, v)
    end
    return t1
end

local function get_consumer_store_service(r, consumer, store, service)
    return r:getIdsByFields("consumer_store_service", {"store", store}, {"service", service}, {"consumer", consumer})[1]
end

function build_nomad_request()
    local path = "/hawk/track/{storeid}" --kong.request.get_path()
    local http_method = "POST" --kong.request.get_method()

    local r = redquery:new()
    r:connect("r-6nnis6swel6d3c7g8e.redis.rds.aliyuncs.com", 6379, "PS4*5$ecxv9J8$^JEHU5xEPE")

    local wildcard_paths = r:getAllFields("path", "path") --/envoy/order/{storeid}
    local path_match, params = util.match_path(path, wildcard_paths) --/envoy/order/{storeid}  order123
    local store_shortname = "SMK474"--params["storeid"] --SMK474
    if store_shortname == nil then
        store_shortname = ""
    end
    -- local consumer_name = kong.request.get_headers()["x-consumer-username"]

    -- METHOD nomad2:method.name#GET.index
    local method_id = r:getIdsByFields("method", {"name", http_method})[1] -- 0

    -- PATH nomad2:path.path#/envoy/order/{storeid}.index
    local path_id = r:getIdsByFields("path", {"path", path_match})[1] -- 0

    -- SERVICE nomad2:method_path.method#1.path#1.index
    local method_path_id = r:getIdsByFields("method_path", {"method", method_id}, {"path", path_id})[1] -- 0
    -- nomad2:method_path#0:service
    local service = r:getRelationship("service", {"method_path", method_path_id})[1] -- 0
    local service_name = r:getValue("service", service)["name"] -- track_event

    -- CONSUMER nomad2:consumer.username#smk-test.index
    local consumer_id = r:getIdsByFields("consumer", {"username", consumer_name})[1] -- 0

    -- STORE nomad2:store.shortname#SMK474.index
    local store_id = r:getIdsByFields("store", {"shortname", store_shortname})[1] --0

    -- PLATFORM
    local consumer_store_service_id
    if not (store_id == nil) then
        --nomad2:consumer_store_service.consumer#0.service#0.store#0.index
        consumer_store_service_id = get_consumer_store_service(r, consumer_id, store_id, service)
    end

    local acting_store_id = store_id
    if consumer_store_service_id == nil then
        -- nomad2:store.shortname#.index
        acting_store_id = r:getIdsByFields("store", {"shortname", ""})[1]
        consumer_store_service_id = get_consumer_store_service(r, consumer_id, acting_store_id, service)
        if consumer_store_service_id == nil then
            return  "Config is not correct for this consumer/store"
        end
    end
    -- nomad2:consumer_store_service#0:platform
    local platforms = r:getRelationship("platform", {"consumer_store_service", consumer_store_service_id})
    local platform_names = {}
    for i, v in ipairs(platforms) do
        -- nomad2:platform#0
        table.insert(platform_names, r:getValue("platform", v)["name"])
    end

    -- STORE_PLATFORM --
    local consumer_store_platforms = {}
    for i, v in ipairs(platforms) do
        consumer_store_platforms =
            concat_lists(
            consumer_store_platforms,
                    -- nomad2:consumer_store_platform.consumer#0.platform#0.store#0.index
            r:getIdsByFields("consumer_store_platform", {"store", acting_store_id}, {"platform", v}, {"consumer", consumer_id})
        )
    end

    -- SECRETS
    local secret_ids = {}
    for _, v in ipairs(consumer_store_platforms) do
        --nomad2:consumer_store_platform#?:secret
        secret_ids = concat_lists(secret_ids, r:getRelationship("secret", {"consumer_store_platform", v}))
    end

    local secrets = {}
    for i, v in ipairs(secret_ids) do
        --nomad2:secret#1
        local s = r:getValue("secret", v)
        secrets[s["name"]] = s["value"]
    end

    -- CONFIGS
    local config_ids = {}
    for _, v in ipairs(consumer_store_platforms) do
        config_ids = concat_lists(config_ids, r:getRelationship("config", {"consumer_store_platform", v}))
    end
    local configs = {}
    for i, v in ipairs(config_ids) do
        local c = r:getValue("config", v)
        configs[c["name"]] = c["value"]
    end

    -- ENGINE
    local last_engine = nil
    local engine_ids = {}

    for _, v in ipairs(platforms) do
        --nomad2:platform_service.platform#1.service#1.index
        local platform_service = r:getIdsByFields("platform_service", {"platform", v}, {"service", service})[1]
        table.insert(engine_ids, r:getRelationship("engine", {"platform_service", platform_service})[1])
    end

    for _, v in ipairs(engine_ids) do
        local engine = r:getValue("engine", v)["nomad"]
        if (not (engine == last_engine)) and (not (last_engine == nil)) then
            return nil
        end
        last_engine = engine
    end

    local nomad_request = {
        platform = platform_names,
        path = path,
        action = service_name,
        http_method = http_method,
        auth = {
            keys = secrets
        },
        config = {
            keys = configs
        },
        request = {
        },
        store_id = store_shortname,
    }

    return nomad_request
end

local nomad_request = build_nomad_request()