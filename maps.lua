local objects = require('objects')
local map_dir = 'maps'
local maps = {}

function parse_maps(s)
    local ranks = {}
    for line in s:gmatch("[^\r\n]+") do
        rank = {}
        for part in line:gmatch(".") do rank[#rank + 1] = part end
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
            if object == objects.PLAYER or object == objects.BOX then
                items[y][x] = object
                environment[y][x] = objects.FLOOR
            elseif object == objects.FLOOR or object == objects.WALL or object ==
                objects.GOAL then
                items[y][x] = objects.FLOOR
                environment[y][x] = object
            end

            -- handle double stacked objects like PLAYER_ON_GOAL and BOX_ON_GOAL
            if object == objects.PLAYER_ON_GOAL then
                items[y][x] = objects.PLAYER
                environment[y][x] = objects.GOAL
            elseif object == objects.BOX_ON_GOAL then
                items[y][x] = objects.BOX
                environment[y][x] = objects.GOAL
            end
        end
    end
    return {items = items, environment = environment}
end

return maps
