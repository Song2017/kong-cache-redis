local util = {}

function match_path(path, templates)
    if path == "" or next(templates) == nil then
        return nil
    end

    for _, t in ipairs(templates) do
        local vars = {}
        for wildcard in t:gmatch("{%w+}") do
            table.insert(vars, wildcard:sub(2, -2))
        end

        local path_regex = t:gsub("{%w+}", "[%%w%%.]+")
        if path:match("^" .. path_regex .. "$") then
            local wildcard_matches = {}
            if next(vars) then
                local vars_regex = t:gsub("{%w+}", "([%%w%%.]+)")

                local vals = {path:match(vars_regex)}
        
                for i, v in ipairs(vals) do
                    wildcard_matches[vars[i]] = v
                end
            end
            return t, wildcard_matches
        end
    end
    return nil
end


local path_match, params = match_path('/envoy/order/order123', {'/envoy/order/{storeid}'})
print(path_match, params["storeid"])