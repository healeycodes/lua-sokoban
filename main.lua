local deepcopy = require('deepcopy')

-- game states
local PLAYING = 'PLAYING'
local COMPLETE = 'COMPLETE'
local CREDITS = 'CREDITS'

-- objects              (traditional terms)
local POT = 'p' --       box
local CHARACTER = 'c' -- player
local FLOOR = '.' --     nothing
local TREE = 't' --      wall
local SWITCH = 's' --    goal

local game = {
    level = nil,
    maps = {},
    objects = {},
    board = nil,
    state = nil,
    state_change_time = 0,
    previous_boards = {}
}
local render_scale = 4
local tile_size = 16

-- debug logger
function p(x)
    local inspect = require('inspect')
    print(inspect(x))
end

function love.load()
    love.window.setTitle('Sokoban')
    -- don't blur pixel graphics
    love.graphics.setDefaultFilter("nearest", "nearest")

    game.maps = require('maps')
    game.objects = require('objects')

    -- all maps are the same size (all square too)
    -- so base the size off the first map
    local side_length = #game.maps[1] * 4
    love.window.setMode(side_length * tile_size, side_length * tile_size)

    -- start first map
    change_level(1)
end

function love.keyreleased(key)
    if game.state ~= PLAYING then return end
    local c = object_pos(CHARACTER, game.board.items)[1]
    if key == "up" then
        character_move(c.x, c.y, c.x, c.y - 1)
    elseif key == "down" then
        character_move(c.x, c.y, c.x, c.y + 1)
    elseif key == "left" then
        character_move(c.x, c.y, c.x - 1, c.y)
    elseif key == "right" then
        character_move(c.x, c.y, c.x + 1, c.y)
    elseif key == "r" then
        change_level(game.level)
    elseif key == "z" then
        undo_move()
    end
end

function love.draw()
    for y, rank in pairs(game.board.environment) do
        for x, environment_obj in pairs(rank) do
            local image

            -- render environment first
            if environment_obj == FLOOR then
                image = game.objects.get_image('floor', game.level)
            elseif environment_obj == SWITCH then
                image = game.objects.get_image('switch')
            elseif environment_obj == TREE then
                image = game.objects.get_image('tree', game.level)
            end

            -- render items on top of the environment
            local item_obj = game.board.items[y][x]
            if item_obj == POT then
                image = game.objects.get_image('pot')
            elseif item_obj == CHARACTER then
                image = game.objects.get_image('character')
            end

            local x_pos = 4 * (x - 1) * tile_size
            local y_pos = 4 * (y - 1) * tile_size
            love.graphics.draw(image, x_pos, y_pos, 0, render_scale)
        end
    end

    local text = "move: arrow keys, undo move: z, restart level: r\n" ..
                     "level: " .. game.level .. '/' .. #game.maps .. '\ntime: ' ..
                     math.floor(love.timer.getTime()) .. 's'
    love.graphics.print({{1, 1, 1, 1}, text}, 5, 5)

    -- pause input and keep completed level on the screen
    -- after 0.75 sec, change level and accept input again
    if game.state == COMPLETE and love.timer.getTime() > game.state_change_time +
        0.75 then
        if game.level == #game.maps then
            game.state = CREDITS
            state_change_time = love.timer.getTime()
        else
            change_level(game.level + 1)
        end
    end

    -- if we're at the credits screen, show it!
    if game.state == CREDITS then
        love.graphics.clear()
        local w, h = love.window.getMode()
        love.graphics.print('game complete!\ntime: ' ..
                                math.floor(state_change_time) .. 's',
                            w / 2 - 50, h / 2 - 50)
    end
end

function check_solved()
    local pots = object_pos(POT, game.board.items)
    local switches = object_pos(SWITCH, game.board.environment)

    -- there's the same number of pots and switches
    -- and they're in a deterministic order
    -- so we can just check for equality
    for i, pot in ipairs(pots) do
        if pot.x ~= switches[i].x or pot.y ~= switches[i].y then
            return false
        end
    end
    return true
end

function change_level(level)
    game.level = level
    game.board = game.maps.load_level(game.level)
    game.state = PLAYING
    game.state_change_time = love.timer.getTime()
    game.previous_boards = {}
end

-- cycle back through board states for the current level
function undo_move()
    if #game.previous_boards > 0 then
        game.board = table.remove(game.previous_boards)
    end
end

function character_move(cx, cy, tx, ty)
    local previous_board = deepcopy(game.board)

    -- check out of bounds
    local target = object_at(tx, ty, game.board.environment)
    if target == nil then return end

    -- character can move into empty space where there are no items
    if (object_at(tx, ty, game.board.environment) == FLOOR or
        object_at(tx, ty, game.board.environment) == SWITCH) and
        object_at(tx, ty, game.board.items) == FLOOR then
        object_swap(cx, cy, tx, ty, game.board.items)

        -- character can't move into a pot but might be able to push it
    elseif object_at(tx, ty, game.board.items) == POT then
        character_push(cx, cy, tx, ty)
    end

    if check_solved() == true then
        game.state = COMPLETE
        game.state_change_time = love.timer.getTime()
    end

    table.insert(game.previous_boards, previous_board)
end

function character_push(cx, cy, tx, ty)
    -- find push target
    local px = tx + (tx - cx)
    local py = ty + (ty - cy)

    -- we can only push pots into empty space (that's still in bounds)
    if object_at(px, py, game.board.items) == FLOOR and
        (object_at(px, py, game.board.environment) == FLOOR or
            -- or onto a switch
            object_at(px, py, game.board.environment) == SWITCH) then

        -- swap pot and empty
        object_swap(tx, ty, px, py, game.board.items)
        -- swap character and the pots previous position
        object_swap(cx, cy, tx, ty, game.board.items)
    end
end

function object_pos(obj, t)
    local ret = {}
    for y, rank in pairs(t) do
        for x, i in pairs(rank) do
            if i == obj then ret[#ret + 1] = {x = x, y = y} end
        end
    end
    if #ret == 0 then return nil end
    return ret
end

function object_at(x, y, t)
    if t[y] == nil then return nil end
    if t[y][x] == nil then return nil end
    return t[y][x]
end

function object_swap(x1, y1, x2, y2, t)
    t[y1][x1], t[y2][x2] = t[y2][x2], t[y1][x1]
end

return game
