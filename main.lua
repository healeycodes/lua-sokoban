-- don't blur pixel graphics
love.graphics.setDefaultFilter("nearest", "nearest")
love.window.setTitle('Sokoban')

local objects = require('objects')
local utils = require('utils')

-- game states
local PLAYING = 'PLAYING'
local COMPLETE = 'COMPLETE'
local CREDITS = 'CREDITS'

local game = {
    level = nil,
    maps = require('maps'),
    board = nil,
    state = nil,
    state_change_time = 0,
    previous_boards = {}, -- previous board state (for undo)
    effort = {}, -- count moves/pushes per level,
    score = {} -- game score (overall moves/pushes)
}
local render_scale = 4
local tile_size = 16

-- debug logger
function p(x)
    local inspect = require('inspect')
    print(inspect(x))
end

function love.load() change_level(1) end

function love.keyreleased(key)
    if game.state ~= PLAYING then return end
    local c = object_pos(objects.PLAYER, game.board.items)[1]
    if key == "up" then
        player_move(c.x, c.y, c.x, c.y - 1)
    elseif key == "down" then
        player_move(c.x, c.y, c.x, c.y + 1)
    elseif key == "left" then
        player_move(c.x, c.y, c.x - 1, c.y)
    elseif key == "right" then
        player_move(c.x, c.y, c.x + 1, c.y)
    elseif key == "r" then
        -- clear score
        game.effort = {}
        -- clean reset
        change_level(game.level)
    elseif key == "z" then
        undo_move()
    elseif key == "s" then
        love.filesystem.setIdentity("screenshot_example")
        love.graphics.captureScreenshot(os.time() .. ".png")
    end
end

function love.draw()
    for y, rank in pairs(game.board.environment) do
        for x, environment_obj in pairs(rank) do
            local image

            -- render environment first
            if environment_obj == objects.FLOOR then
                image = objects.get_image(objects.FLOOR, x * y)
            elseif environment_obj == objects.GOAL then
                image = objects.get_image(objects.GOAL)
            elseif environment_obj == objects.WALL then
                image = objects.get_image(objects.WALL, x * y)
            end

            -- render items on top of the environment
            local item_obj = game.board.items[y][x]
            if item_obj == objects.BOX then
                image = objects.get_image(objects.BOX)
            elseif item_obj == objects.PLAYER then
                image = objects.get_image(objects.PLAYER)
            end

            local x_pos = 4 * (x - 1) * tile_size
            local y_pos = 4 * (y - 1) * tile_size
            love.graphics.draw(image, x_pos, y_pos, 0, render_scale)
        end
    end

    local text = "controls: arrow keys, undo move: z, restart level: r\n" ..
                     "level: " .. game.level .. '/' .. #game.maps ..
                     ' (moves/pushes: ' .. score(game.effort) .. ')'
    love.graphics.print({{1, 1, 1, 1}, text}, 5, 5)

    -- pause input and keep completed level on the screen
    -- after 0.75 sec, change level and accept input again
    if game.state == COMPLETE and love.timer.getTime() > game.state_change_time +
        0.75 then

        -- on level change, or game win, store the score
        game.score = utils.concat_values(game.score, game.effort)
        -- reset for next level (if any)
        game.effort = {}

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
        love.graphics.print('game complete!\nscore (moves/pushes): ' ..
                                score(game.score), w / 2 - 60, h / 2 - 50)
    end
end

function check_solved()
    local boxes = object_pos(objects.BOX, game.board.items)
    local goals = object_pos(objects.GOAL, game.board.environment)

    -- there's the same number of boxes and goals
    -- and they're in a deterministic order
    -- so we can just check for equality
    for i, box in ipairs(boxes) do
        if box.x ~= goals[i].x or box.y ~= goals[i].y then return false end
    end
    return true
end

function change_level(level)
    game.level = level
    game.board = game.maps.load_level(game.level)
    game.state = PLAYING
    game.state_change_time = love.timer.getTime()
    game.previous_boards = {}

    -- base the window size off the first map
    local side_length_y = #game.board.environment * 4
    local side_length_x = #game.board.environment[1] * 4
    love.window.setMode(side_length_x * tile_size, side_length_y * tile_size)
end

-- cycle back through board states for the current level
function undo_move()
    if #game.previous_boards > 0 then
        game.board = table.remove(game.previous_boards)
    end
end

function player_move(cx, cy, tx, ty)
    local previous_board = utils.deepcopy(game.board)

    -- check out of bounds
    local target = object_at(tx, ty, game.board.environment)
    if target == nil then return end

    -- player can move into empty space where there are no items
    if (object_at(tx, ty, game.board.environment) == objects.FLOOR or
        object_at(tx, ty, game.board.environment) == objects.GOAL) and
        object_at(tx, ty, game.board.items) == objects.FLOOR then
        object_swap(cx, cy, tx, ty, game.board.items)
        table.insert(game.effort, 'm')

        -- player can't move into a box but might be able to push it
    elseif object_at(tx, ty, game.board.items) == objects.BOX then
        if player_push(cx, cy, tx, ty) == true then
            table.insert(game.effort, 'm')
            table.insert(game.effort, 'p')
        else
            -- player_move was noop, don't store in history
            return
        end
    else
        -- player_move was noop, don't store in history
        return
    end

    if check_solved() == true then
        game.state = COMPLETE
        game.state_change_time = love.timer.getTime()
    end

    table.insert(game.previous_boards, previous_board)
end

function player_push(cx, cy, tx, ty)
    -- find push target
    local px = tx + (tx - cx)
    local py = ty + (ty - cy)

    -- we can only push objects.BOXs into empty space (that's still in bounds)
    if object_at(px, py, game.board.items) == objects.FLOOR and
        (object_at(px, py, game.board.environment) == objects.FLOOR or
            -- or onto a switch
            object_at(px, py, game.board.environment) == objects.GOAL) then

        -- swap objects.BOX and empty
        object_swap(tx, ty, px, py, game.board.items)
        -- swap objects.PLAYER and the objects.BOXs previous position
        object_swap(cx, cy, tx, ty, game.board.items)
        return true
    end
    return false
end

function score(l)
    local moves = 0
    local pushes = 0
    for _, v in pairs(l) do
        if v == 'm' then
            moves = moves + 1
        elseif v == 'p' then
            pushes = pushes + 1
        end
    end
    return moves .. '/' .. pushes
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
