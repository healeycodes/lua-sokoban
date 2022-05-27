local asset_dir = 'assets'
local tiles = asset_dir .. '/kenny_nl_monochrome_rpg/'
local objects = {}

objects['character'] = {love.graphics.newImage(tiles .. 'tile_0122.png')}
objects['floor'] = {
    love.graphics.newImage(tiles .. 'tile_0000.png'),
    love.graphics.newImage(tiles .. 'tile_0017.png'),
    love.graphics.newImage(tiles .. 'tile_0019.png')
}
objects['tree'] = {
    love.graphics.newImage(tiles .. 'tile_0013.png'),
    love.graphics.newImage(tiles .. 'tile_0014.png'),
    love.graphics.newImage(tiles .. 'tile_0015.png'),
    love.graphics.newImage(tiles .. 'tile_0016.png'),
    love.graphics.newImage(tiles .. 'tile_0030.png')
}
objects['pot'] = {love.graphics.newImage(tiles .. 'tile_0135.png')}
objects['switch'] = {love.graphics.newImage(tiles .. 'tile_0084.png')}

function objects.get_image(name, entropy)
    entropy = entropy or 1

    -- deterministic per level
    math.randomseed(entropy)
    return objects[name][math.random(#objects[name])]
end

return objects
