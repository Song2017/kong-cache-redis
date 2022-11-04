--local redis = require "resty.redis"

local Redquery = {}

local function pack(...)
    return {n = select("#", ...), ...}
end

local function relationshipName(target, parameter, value)
    print('-----------relationshipName')
    local r = string.format("nomad2:%s#%s:%s", parameter, value, target)
    print(r)
    return r
end

local function valueName(key, value)
    print('-----------valueName')
    local r = string.format("nomad2:%s#%s", key, value)
    print(r)
    return r
end

local function indexNoRangeName(entity, fieldVals)
    local name = string.format("nomad2:%s.", entity)
    table.sort(
        fieldVals,
        function(a, b)
            return a[1] < b[1]
        end
    )
    for _, v in ipairs(fieldVals) do
        name = name .. v[1] .. "#" .. v[2] .. "."
    end
    return name .. "index"
end

local function indexAllName(entity, field)
    return string.format("nomad2:%s.%s.index.all", entity, field)
end

local function getValue(s, key, value)
    print(valueName(key, value))
    --local rResponse, err = s.red:hgetall(valueName(key, value))
    --if not rResponse then
    --    error(err)
    --end
    --if next(rResponse) == nil then
    --    return {}
    --end
    --local response = {}
    --local i = 1
    --while rResponse[i] do
    --    response[rResponse[i]] = rResponse[i + 1]
    --    i = i + 2
    --end
    --return response
end

local function getIdsByFields(s, entity, fieldVals)
    print(indexNoRangeName(entity, fieldVals))
    --local ids, err = s.red:smembers(indexNoRangeName(entity, fieldVals))
    --if not ids then
    --    error(err)
    --end
    --return ids
end

function Redquery:close()
    local ok, err = self.red:close()
    if not ok then
        error(err)
    end
end

function Redquery:new()
    local rq = {}
    setmetatable(rq, self)
    self.__index = self
    --self.red = redis:new()
    return rq
end

function Redquery:connect(address, port, password)
    local ok, err = self.red:connect(address, port)
    if not ok then
        error(err)
    end
    if not (password == nil) then
        local ok, err = self.red:auth(password)
        if not ok then
            error(err)
        end
    end
    self.red:set_timeouts(1000, 1000, 1000)
end

function Redquery:getValue(key, value)
    return getValue(self, key, value)
end

function Redquery:getRelationship(target, ...)
    local parameters = pack(...)
    local indexes = {}
    for k, v in ipairs(parameters) do
        local relationshipName = relationshipName(target, v[1], v[2])
        table.insert(indexes, relationshipName)
    end

    local set, err = self.red:sinter(unpack(indexes))
    if not set then
        error(err)
    end
    return set
end

function Redquery:getAllFields(entity, field)
    local index, err = self.red:zrange(indexAllName(entity, field), 0, -1)
    if not index then
        error(err)
    end
    if next(index) == nil then
        return nil
    end
    return index
end

function Redquery:getIdsByFields(entity, ...)
    local parameters = pack(...)
    return getIdsByFields(self, entity, parameters)
end

--return Redquery

local r = Redquery:new()
--local method_id = r:getIdsByFields("method", {"name", http_method})[1] -- 0
--local method_id = r:getIdsByFields("path", {"path", "/envoy/order/{storeid}"})[1]
--local method_path_id = r:getIdsByFields("method_path", {"method", 0}, {"path", 0})
--local service = r:getRelationship("service", {"method_path", 0})[1]
--local service_name = r:getValue("service", 0)["name"]
--r:getIdsByFields("consumer", {"username", 0})
--r:getIdsByFields("store", {"shortname", "SMK474"})
--r:getIdsByFields("consumer_store_service", {"store", 0}, {"service", 0}, {"consumer", 0})
--r:getIdsByFields("store", {"shortname", "0"})
--r:getRelationship("platform", {"consumer_store_service", 0})
--r:getIdsByFields("consumer_store_platform", {"store", 0}, {"platform", v}, {"consumer", 0})
--r:getValue("platform", 0)
--r:getIdsByFields("consumer_store_platform", {"store", 0}, {"platform", 0}, {"consumer", 0})
--r:getRelationship("secret", {"consumer_store_platform", 1})
--r:getValue("secret", 1)
--r:getRelationship("config", {"consumer_store_platform", 1})
--r:getValue("config", 1)
--r:getIdsByFields("platform_service", {"platform", 1}, {"service", 1})
--r:getRelationship("engine", {"platform_service", 1})
r:getValue("engine", v)