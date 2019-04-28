function tmpGunBullet()
    local bullet = {}
    bullet.b = love.physics.newBody(world, 10, 10, "dynamic")
    bullet.s = love.physics.newCircleShape(player.shape:getRadius() * 0.5)
    bullet.f = love.physics.newFixture(bullet.b, bullet.s) -- add physics
    bullet.f:setRestitution(0.2) -- determine how bouncy this be
    bullet.b:setActive(false)
    bullet.b:setBullet(true)
    return bullet
end

function love.load()
    -- player constants
    local PLAYER_VELOCITY = 200
    local HEALTH = 100

    love.physics.setMeter(64)
    world = love.physics.newWorld(0, 0, true)
    world:setCallbacks(beginContact, endContact, preSolve, postSolve)
    t, shakeDuration, shakeMagnitude = 0, -1, 0 -- initialization for camera shaking parameters

    -- Generate map
    MapGenerator = require("MapGenerator")
    mapgen = MapGenerator:new(42, 42, 5, 64)
    mapgen:doDrunkardsWalk(0.2)
    mapgen:exportToFile("test.txt")
    -- centre of map
    mapCenterX = mapgen.sizeX * mapgen.cellsize / 2
    mapCenterY = mapgen.sizeY * mapgen.cellsize / 2

    -- create gun
    GunCreator = require("gun")
    tmpGun_bullet_creator = {
        create = tmpGunBullet
    }

    colorTest = {244, 219, 0}
    tmpGun = GunCreator:new(0.3, 0.5, 9, 13, "assets/sounds/gun_fire.wav", tmpGun_bullet_creator, colorTest, 1)

    PlayerCreator = require("player")
    player = PlayerCreator:new(PLAYER_VELOCITY, tmpGun, mapCenterX, mapCenterY, HEALTH, world)

    objects = {}
    -- stores objects to draw and physics
    objects.static = {} -- static world objects
    initializeMap(objects.static)

    -- contains the bullets
    objects.bullets = {} -- contains bullets currently flying
    objects.bulletTouching = {} -- number of times a bullet touches an object [bullet.f:getUserData()] = #times_touched
    bulletCount = 0 -- amount of bullets

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

    musicTrack = love.audio.newSource("/assets/sounds/track.mp3", "static")
    musicTrack:setLooping(true)
    musicTrack:play()
end

function love.update(dt)
    world:update(dt)
    tmpGun:update(dt)

    if t < shakeDuration then
        t = t + dt
    end

    local kybrd = love.keyboard -- keyboard object
    mouse = love.mouse
    player:update(dt, kybrd)
    local curGun = player:getGun()

    if curGun:shouldShoot(mouse) then
        local translateX, translateY = getTranslate()
        bulletCount = (bulletCount + 1) % 10000

        local bullet = curGun:shoot(player.body,
                        player.shape:getRadius(),
                        mouse:getX() + math.abs(translateX),
                        mouse:getY() + math.abs(translateY))

        bullet.f:setUserData(tostring(bulletCount))
        objects.bulletTouching[tostring(bulletCount)] = 0
        table.insert(objects.bullets, bullet)
    end

    processBullets(curGun.speed)

    for i = 1, 3 do
        objects.enemies[i]:update(player.body:getX(), player.body:getY())
    end

end

-- processes the physics of bullets
function processBullets(speedCap)
    for i = 1, #objects.bullets do
        local velX, velY = objects.bullets[i].b:getLinearVelocity()
        local velLength = math.sqrt(velX * velX + velY * velY)

        if velLength < speedCap then
            velX = (speedCap / velLength) * velX
            velY = (speedCap / velLength) * velY
            objects.bullets[i].b:setLinearVelocity(velX, velY)
        end
    end
end

-- gets camera translation to map from screen space to world space
function getTranslate()
    return -player.body:getX() + love.graphics.getWidth()/2, - player.body:getY() + love.graphics.getHeight()/2
end

function love.draw()
    love.graphics.clear()
    love.graphics.reset()

    -- screen bounds in world space
    local minBoundX = math.floor(player.body:getX() - love.graphics:getWidth() / 2 - mapgen.cellsize)
    local minBoundY = math.floor(player.body:getY() - love.graphics:getHeight() / 2 - mapgen.cellsize)
    local maxBoundX = math.floor(player.body:getX() + love.graphics:getWidth() / 2 + mapgen.cellsize)
    local maxBoundY = math.floor(player.body:getY() + love.graphics:getHeight() / 2  + mapgen.cellsize)

    -- move according to player
    love.graphics.translate(getTranslate())
    -- draw the world
    drawWorld(minBoundX, minBoundY, maxBoundX, maxBoundY)
    -- draw the bullets
    drawBullets(minBoundX, minBoundY, maxBoundX, maxBoundY)
    -- shake the screen
    --shakeScreen()

    local headbody = player.body
    xH, yH = headbody:getPosition()
    xH = xH - love.graphics.getWidth() / 2
    yH = yH - love.graphics.getHeight() / 2
    -- draw enemies
    for i=1,3 do
	    objects.enemies[i]:draw(xH, yH)
    end

    player:draw()
end

function initializePlayer(playerContainer, playerX, playerY)
    playerContainer.body = love.physics.newBody(world, playerX, playerY, "dynamic")
    playerContainer.body:setMass(1)
    playerContainer.body:setAngularVelocity(0)
    playerContainer.shape = love.physics.newCircleShape(10)
    playerContainer.fixture = love.physics.newFixture(playerContainer.body, playerContainer.shape)
    playerContainer.fixture:setRestitution(0)
    playerContainer.fixture:setUserData("head")
end

-- init map in world
function initializeMap(worldBlocks)
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
                worldBlocks[key] = {}
                worldBlocks[key].body = love.physics.newBody(world, worldX, worldY, "static")
                worldBlocks[key].shape = love.physics.newRectangleShape(mapgen.cellsize, mapgen.cellsize)
            end

            -- for each block change properties
            if mapgen.grid[i][j] == -1 then
                worldBlocks[key].fixture = love.physics.newFixture(worldBlocks[key].body, worldBlocks[key].shape)
                worldBlocks[key].fixture:setUserData("indestructible")
            end
            if mapgen.grid[i][j] == 0 then
                worldBlocks[key].fixture = love.physics.newFixture(worldBlocks[key].body, worldBlocks[key].shape)
                worldBlocks[key].fixture:setUserData("wall")
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
function drawWorld(minBoundX, minBoundY, maxBoundX, maxBoundY)
    for i = 1, #objects.static do
        local rectX, rectY = objects.static[i].body:getPosition() -- get rectangle position
        -- if draw iff not out of bounds
        if rectX > minBoundX and rectX < maxBoundX and rectY < maxBoundY and rectY > minBoundY then
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
    objects.bulletTouching[name] = 0
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
            objects.bulletTouching[b:getUserData()] = objects.bulletTouching[b:getUserData()] + 1
        end
    elseif tonumber(a:getUserData()) ~= nil then
        if string.sub(a:getUserData(), 1, 5) == "enemy" then
            -- delete the enemy
        else
            objects.bulletTouching[a:getUserData()] = objects.bulletTouching[a:getUserData()] + 1
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
        startShake(0.5, 100) -- shak    if t < shakeDuration then -- if duration not passed
        local dx = love.math.random(-shakeMagnitude, shakeMagnitude) -- shake randomly
        local dy = love.math.random(-shakeMagnitude, shakeMagnitude)
        love.graphics.translate(dx, dy) -- move the camera
    end
end

function drawBullets(minBoundX, minBoundY, maxBoundX, maxBoundY)
    for i = #objects.bullets, 1, -1 do
        -- get location of the bullet
        local bulletX, bulletY = objects.bullets[i].b:getPosition()
        -- if out of bounds for screen
        if tonumber(objects.bulletTouching[objects.bullets[i].f:getUserData()]) > tmpGun.maxCollisions then -- if the number of touchings more than 5
            -- destroy the bullet
            objects.bullets[i].b:destroy()
            -- remove it from the array
            table.remove(objects.bullets, i)
            --table.remove(objects.bulletTouching, objects.bullets[i].f:getUserData())
        else
            -- draw the bullet
            love.graphics.setColor(unpack(tmpGun.bulletColor))
            love.graphics.circle("fill", objects.bullets[i].b:getX(), objects.bullets[i].b:getY(), objects.bullets[i].s:getRadius())
        end
    end
end

