local utils = {}

-- https://stackoverflow.com/a/16077650
function utils.deepcopy(o, seen)
    seen = seen or {}
    if o == nil then return nil end
    if seen[o] then return seen[o] end

    local no
    if type(o) == 'table' then
        no = {}
        seen[o] = no

        for k, v in next, o, nil do
            no[utils.deepcopy(k, seen)] = utils.deepcopy(v, seen)
        end
        setmetatable(no, utils.deepcopy(getmetatable(o), seen))
    else -- number, string, boolean, etc
        no = o
    end
    return no
end

function utils.concat_values(t1, t2)
    local t3 = {}
    if t1 then for _, v in ipairs(t1) do table.insert(t3, v) end end
    if t2 then for _, v in ipairs(t2) do table.insert(t3, v) end end
    return t3
end

return utils
