require("player")

function love.load()
    love.physics.setMeter(64)
    world = love.physics.newWorld(0, 0, true)
    world:setCallbacks(beginContact, endContact, preSolve, postSolve)
    t, shakeDuration, shakeMagnitude = 0, -1, 0 -- initialization for camera shaking parameters
    MAX_TOUCHING = 3 -- number of times the bullets can bounce before die

    -- Generate map
    MapGenerator = require("MapGenerator")
    mapgen = MapGenerator:new(100, 100, 5, 64)
    mapgen:doDrunkardsWalk(0.3)
    mapgen:exportToFile("test.txt")

    -- centre of map
    centre_map_x = math.floor(mapgen.sizeX * mapgen.cellsize / 2)
    centre_map_y = math.floor(mapgen.sizeY * mapgen.cellsize / 2)

    objects = {}
    -- stores objects to draw and physics
    objects.static = {} -- static world objects
    objects.head= {} -- player
    initializePlayer(objects.head, centre_map_x, centre_map_y)
    initializeMap(objects.static)

    -- contains the bullets
    objects.bullets = {} -- contains bullets currently flying
    objects.bullet_touching = {} -- number of times a bullet touches an object [bullet.f:getUserData()] = #times_touched
    bullet_amount = 0 -- amount of bullets

    -- love.window.setMode(mapgen.sizeX * mapgen.cellsize, mapgen.sizeY * mapgen.cellsize)

    -- create enemies
    enemy_counter = 0
    Enemy = require("enemy")
    objects.enemies = {}
    for i = 1, 3 do

        -- declare spawnpoints
        local spawnX
        local spawnY

        -- find valid spawnpositions
        while true do
            spawnX = math.random(1, mapgen.sizeX)
            spawnY = math.random(1, mapgen.sizeY)

            -- if spawnpoint is a path then its a valid spawnpoint
            if mapgen.grid[spawnX][spawnY] == 1 then
                break
            end
        end

        -- translate valid block to valid ws-coordinates
	    spawnX = ((spawnX - 1) * mapgen.cellsize) + (mapgen.cellsize / 2)
	    spawnY = ((spawnY - 1) * mapgen.cellsize) + (mapgen.cellsize / 2)

        -- set enemies
	    objects.enemies[i] = Enemy:new(enemy_counter, spawnX, spawnY, 32, 300, world)
	    enemy_counter = enemy_counter + 1
    end

    -- load textures
    wall = love.graphics.newImage("/assets/bricks/bricks_0.png")
    rock = love.graphics.newImage("/assets/rock texture.png")
    rock2 = love.graphics.newImage("/assets/brick texture 2.png")
    brick = love.graphics.newImage("/assets/brick texture.png")
    dirt = love.graphics.newImage("/assets/dirt1.jpg")
end

function love.update(dt)
    world:update(dt)
    if t < shakeDuration then
        t = t + dt
    end

    headbody = objects.head.body -- player body
    kybrd = love.keyboard -- keyboard object
    mouse = love.mouse
    -- get current position
    head_x, head_y = headbody:getPosition()
    -- get current velocity
    x_cur, y_cur = headbody:getLinearVelocity()
    -- update player angle and velocity
    headbody:setLinearVelocity(getPlayerVelocity(x_cur, y_cur, kybrd))
    headbody:setAngle(getPlayerAngle(mouse, headbody)) 
    -- update player angle and velocity
    headbody:setLinearVelocity(getPlayerVelocity(x_cur, y_cur, kybrd))
    -- shoot if necessary
    if shouldShoot(mouse) then
        bullet_amount = (bullet_amount + 1) % 1000000 -- count number of bullets
        addBullet(tostring(bullet_amount)) -- give it as a unique id
        -- TODO:  graphics.translate within the shoot method without passing translate_x and y
        local translate_x, translate_y = getTranslate() -- translation coordinates
        shoot(headbody, translate_x, translate_y, 
            objects.head.shape:getRadius(), 
            mouse, objects.bullets[table.getn(objects.bullets)].b)
    end

    processBullets()
    -- dont rotate the player
    headbody:setAngularVelocity(0)

    for i = 1, 3 do
	    objects.enemies[i]:update(head_x, head_y, objects.head.body:getX(), objects.head.body:getY())
    end

end

-- processes the physics of bullets
function processBullets()
    for i=1,#objects.bullets do
        local vel_x, vel_y = objects.bullets[i].b:getLinearVelocity()
        local vel_length = math.sqrt(vel_x * vel_x + vel_y * vel_y)
        if vel_length < bullet_speed then
            vel_x = (bullet_speed / vel_length) * vel_x
            vel_y = (bullet_speed / vel_length) * vel_y
            objects.bullets[i].b:setLinearVelocity(vel_x, vel_y)
        end
    end
end

-- gets camera translation to map from screen space to world space
function getTranslate()
    return -objects.head.body:getX() + love.graphics.getWidth()/2, -objects.head.body:getY() + love.graphics.getHeight()/2
end

function love.draw()
    love.graphics.clear()
    love.graphics.reset()

    -- screen bounds in world space
    local x_bound_min = math.floor(objects.head.body:getX() - love.graphics:getWidth() / 2 - mapgen.cellsize)
    local y_bound_min = math.floor(objects.head.body:getY() - love.graphics:getHeight() / 2 - mapgen.cellsize)
    local x_bound_max = math.floor(objects.head.body:getX() + love.graphics:getWidth() / 2 + mapgen.cellsize)
    local y_bound_max = math.floor(objects.head.body:getY() + love.graphics:getHeight() / 2  + mapgen.cellsize)

    -- move according to player
    love.graphics.translate(getTranslate())
    -- draw the world
    drawWorld(x_bound_min, y_bound_min, x_bound_max, y_bound_max)
    -- draw the bullets
    drawBullets(x_bound_min, y_bound_min, x_bound_max, y_bound_max)
    -- shake the screen
    --shakeScreen()

    --love.graphics.translate(math.floor(objects.head.body:getX() - love.graphics.getWidth() / 2), math.floor(objects.head.body:getY() - love.graphics.getHeight() / 2))
    local headbody = objects.head.body
    xH, yH = headbody:getPosition()
    xH = xH - love.graphics.getWidth() / 2
    yH = yH - love.graphics.getHeight() / 2
    -- draw enemies
    for i=1,3 do
	    objects.enemies[i]:draw(xH, yH)
    end

    love.graphics.setColor(1,1,1)
    -- draw the player
    love.graphics.circle("line", objects.head.body:getX() , objects.head.body:getY(), objects.head.shape:getRadius())
end

function initializePlayer(player_container, player_x, player_y)
    player_container.body = love.physics.newBody(world, player_x, player_y, "dynamic")
    player_container.body:setMass(1)
    player_container.body:setAngularVelocity(0)
    player_container.shape = love.physics.newCircleShape(10)
    player_container.fixture = love.physics.newFixture(player_container.body, player_container.shape)
    player_container.fixture:setRestitution(0)
    player_container.fixture:setUserData("head")
end

-- init map in world
function initializeMap(world_blocks)
    key = 0 -- key to access index
    for i = 1, mapgen.sizeX do -- for each coordinate combination
        for j = 1, mapgen.sizeY do

            -- if path, ignore
            if mapgen.grid[i][j] ~= 1 then
                -- map index to world space
                local worldX = (i - 1) * mapgen.cellsize
                local worldY = (j - 1) * mapgen.cellsize

                key = key + 1
                -- initialize the body of a static block
                world_blocks[key] = {}
                world_blocks[key].body = love.physics.newBody(world, worldX, worldY, "static")
                world_blocks[key].shape = love.physics.newRectangleShape(mapgen.cellsize, mapgen.cellsize)
            end

            -- for each block change properties
            if mapgen.grid[i][j] == -1 then
                world_blocks[key].fixture = love.physics.newFixture(world_blocks[key].body, world_blocks[key].shape)
                world_blocks[key].fixture:setUserData("indestructible")
            end
            if mapgen.grid[i][j] == 0 then
                world_blocks[key].fixture = love.physics.newFixture(world_blocks[key].body, world_blocks[key].shape)
                world_blocks[key].fixture:setUserData("wall")
            end
        end
    end
end

-- draws block
function drawMapBlock(i)
    -- choose texture per block
    local texture = nil
    if objects.static[i].fixture:getUserData() == "wall" then
        texture = rock2
    else
        texture  = brick
    end

    -- draw polygon and texture
    love.graphics.polygon("fill", objects.static[i].body:getWorldPoints(objects.static[i].shape:getPoints()))
    love.graphics.draw(texture, math.floor(objects.static[i].body:getX() - mapgen.cellsize / 2), math.floor(objects.static[i].body:getY() - mapgen.cellsize / 2))
end

-- draws the world
function drawWorld(x_bound_min, y_bound_min, x_bound_max, y_bound_max)
    for i = 1, #objects.static do
        local rect_x, rect_y = objects.static[i].body:getPosition() -- get rectangle position
        -- if draw iff not out of bounds
        if rect_x > x_bound_min and rect_x < x_bound_max and rect_y < y_bound_max and rect_y > y_bound_min then
            drawMapBlock(i)
        end
    end
end

function startShake(duration, magnitude)
    t, shakeDuration, shakeMagnitude = 0, duration or 1, magnitude or 5
end

-- adds a bullet to the bullet array: objects.bullets
function addBullet(name)
    bullet = {}
    objects.bullet_touching[name] = 0
    -- dynamic bullet at whatever coordinates
    bullet.b = love.physics.newBody(world, 10, 10, "dynamic")
    bullet.s = love.physics.newCircleShape(objects.head.shape:getRadius() * 0.5) -- shape of the bullet
    bullet.f = love.physics.newFixture(bullet.b,bullet.s) -- add physics
    bullet.f:setRestitution(0.2) -- determine how bouncy this be
    bullet.f:setUserData(name) -- unique id of the bullet
    bullet.b:setActive(false)
    bullet.b:setBullet(true)
    bullet.touched = 0
    table.insert(objects.bullets, bullet)
end

-- collision callbacks
function beginContact(a, b, coll)
    -- update number of times a bullet touched
    if tonumber(b:getUserData()) ~= nil then
	if string.sub(a:getUserData(), 1, 5) == "enemy" then
	        -- delete the enemy
		local idx = tonumber(string.sub(a:getUserData(), 6))
		print("enemy died:" .. idx)
        -- objects.enemies[idx].destroy()
        -- table.remove(objects.enemies[idx])
	    else
	        -- bounce off wall
            	objects.bullet_touching[b:getUserData()] = objects.bullet_touching[b:getUserData()] + 1
	    end
    elseif tonumber(a:getUserData()) ~= nil then
	    if string.sub(a:getUserData(), 1, 5) == "enemy" then
            -- delete the enemy
        else
            objects.bullet_touching[a:getUserData()] = objects.bullet_touching[a:getUserData()] + 1
        end
    end
end

function endContact(a, b, coll)

end

function preSolve(a, b, coll)

end

function postSolve(a, b, coll, normalimpulse, tangentimpulse)

end
--end of collision callbacks


-- shakes the screen
function shakeScreen()
    if t < shakeDuration and #objects.bullets > 1 then -- if we bullets exist
        startShake(0.5, 100) -- shake
    end
    if t < shakeDuration then -- if duration not passed
        local dx = love.math.random(-shakeMagnitude, shakeMagnitude) -- shake randomly
        local dy = love.math.random(-shakeMagnitude, shakeMagnitude)
        love.graphics.translate(dx, dy) -- move the camera
    end
end

function drawBullets(x_bound_min, y_bound_min, x_bound_max, y_bound_max)
    for i=#objects.bullets,1,-1 do
        -- get location of the bullet
        local bullet_x, bullet_y = objects.bullets[i].b:getPosition()
        -- if out of bounds for screen
        if tonumber(objects.bullet_touching[objects.bullets[i].f:getUserData()]) > MAX_TOUCHING then -- if the number of touchings more than 5
            -- destroy the bullet
            objects.bullets[i].b:destroy()
            -- remove it from the array
            table.remove(objects.bullets, i)
            --table.remove(objects.bullet_touching, objects.bullets[i].f:getUserData())
        else
            -- draw the bullet
            love.graphics.circle("fill", objects.bullets[i].b:getX(), objects.bullets[i].b:getY(), objects.bullets[i].s:getRadius())
        end
    end
end

