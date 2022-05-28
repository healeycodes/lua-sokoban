local asset_dir = 'assets'
local tiles = asset_dir .. '/kenny_nl_monochrome_rpg/'
local objects = {}

-- http://sokobano.de/wiki/index.php?title=Level_format
objects.WALL = '#'
objects.PLAYER = '@'
objects.PLAYER_ON_GOAL = '+'
objects.BOX = '$'
objects.BOX_ON_GOAL = '*'
objects.GOAL = '.'
objects.FLOOR = ' '

local assets = {}
assets[objects.PLAYER] = {love.graphics.newImage(tiles .. 'tile_0122.png')}
assets[objects.FLOOR] = {
    love.graphics.newImage(tiles .. 'tile_0000.png'),
    love.graphics.newImage(tiles .. 'tile_0017.png'),
    love.graphics.newImage(tiles .. 'tile_0019.png')
}
assets[objects.WALL] = {
    love.graphics.newImage(tiles .. 'tile_0013.png'),
    love.graphics.newImage(tiles .. 'tile_0014.png'),
    love.graphics.newImage(tiles .. 'tile_0015.png'),
    love.graphics.newImage(tiles .. 'tile_0016.png'),
    love.graphics.newImage(tiles .. 'tile_0030.png')
}
assets[objects.BOX] = {love.graphics.newImage(tiles .. 'tile_0135.png')}
assets[objects.GOAL] = {love.graphics.newImage(tiles .. 'tile_0084.png')}

function objects.get_image(name, entropy)
    entropy = entropy or 1

    -- deterministic per level
    math.randomseed(entropy)
    return assets[name][math.random(#assets[name])]
end

return objects
