local map_dir = 'maps'
local maps = {}

function parse_maps(s)
    local ranks = {}
    for line in s:gmatch("[^\r\n]+") do
        rank = {}
        for part in line:gmatch("%S+") do rank[#rank + 1] = part end
        ranks[#ranks + 1] = rank
    end
    return ranks
end

local map_files = love.filesystem.getDirectoryItems(map_dir)
table.sort(map_files)
for name in pairs(map_files) do
    contents, _ = love.filesystem.read(map_dir .. '/' .. map_files[name])
    maps[name] = parse_maps(contents)
end

function maps.load_level(name)
    local items = {}
    local environment = {}
    for y, line in ipairs(maps[name]) do
        items[y] = {}
        environment[y] = {}
        for x, object in ipairs(line) do
            if object == 'c' or object == 'p' then
                items[y][x] = object
                environment[y][x] = '.'
            else
                items[y][x] = '.'
                environment[y][x] = object
            end
        end
    end
    return {items = items, environment = environment}
end

return maps
