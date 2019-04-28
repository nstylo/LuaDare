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

local suit = require 'suit'

function love.load()
    input = {text = ""}
    fps = love.timer.getFPS()
    -- player constants
    local PLAYER_VELOCITY = 200
    local HEALTH = 100
    NUM_ENEMIES = 10

    roundOver = false

    love.physics.setMeter(64)
    world = love.physics.newWorld(0, 0, true)
    world:setCallbacks(beginContact, endContact, preSolve, postSolve)
    t, shakeDuration, shakeMagnitude = 0, 1, 0 -- initialization for camera shaking parameters

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
    createEnemies()

    -- load textures
    wall = love.graphics.newImage("/assets/bricks/bricks_0.png")
    rock = love.graphics.newImage("/assets/rock texture.png")
    rock2 = love.graphics.newImage("/assets/brick texture 2.png")
    brick = love.graphics.newImage("/assets/brick texture.png")
    dirt = love.graphics.newImage("/assets/dirt1.jpg")

    hearts = {}
    for i = 1, math.floor(player.health / 10) do
        hearts[i] = love.graphics.newImage("/assets/heart/heart pixel art 32x32.png")
    end

    musicTrack = love.audio.newSource("/assets/sounds/track.mp3", "static")
    musicTrack:setLooping(true)
    musicTrack:play()
end

function roundIsOver()
    count = 0 -- number of alive enemies

    for i = 0, #objects.enemies do
        if objects.enemies[i] ~= nil and objects.enemies[i].alive then -- count alive enemies
            count = count + 1
        end
    end

    if count == 0 then
        roundOver = true
    end

    --TODO: Spawn a portal or something to advance to the next round
end

function love.update(dt)
    if player:isDead() then
        dt = dt / 16
    end

    roundIsOver()

    world:update(dt)
    tmpGun:update(dt)

    -- put the layout origin at position (0, 0) screen space
    -- the layout will grow down and to the right from this point
    suit.layout:reset(20, 90)

    -- put an input widget at the layout origin, with a cell size of 200 by 30 pixels
    suit.Input(input, suit.layout:row(50, 20))

    -- put a label that displays the text below the first cell
    -- the cell size is the same as the last one (200x30 px)
    -- the label text will be aligned to the left
    --suit.Label("Health: " .. player.health .. input.text, {align = "left"}, suit.layout:row())

    -- put an empty cell that has the same size as the last cell (200x30 px)
    suit.layout:row()

    -- put a button of size 200x30 px in the cell below
    -- if the button is pressed, quit the game

    if t < shakeDuration then
        t = t + dt
    end

    local kybrd = love.keyboard -- keyboard object
    mouse = love.mouse
    player:update(dt, kybrd)
    local curGun = player:getGun()

    if curGun:shouldShoot(mouse) and not player:isDead() then
        local translateX, translateY = getTranslate()
        bulletCount = (bulletCount + 1) % 10000

        local bullet = curGun:shoot(player.body,
        player.shape:getRadius(),
        mouse:getX(), --+ math.abs(translateX)
        mouse:getY()) --+ math.abs(translateY)

        bullet.f:setUserData(tostring(bulletCount))
        objects.bulletTouching[tostring(bulletCount)] = 0
        table.insert(objects.bullets, bullet)
    end

    processBullets(curGun.speed)

    for i = 1,NUM_ENEMIES do
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


function love.textedited(text, start, length)
    -- for IME input
    suit.textedited(text, start, length)
end

function love.textinput(t)
    suit.textinput(t)
end

function love.keypressed(key)
    suit.keypressed(key)
end

function love.draw()
    love.graphics.clear()
    love.graphics.reset()
    shakeScreen()

    -- screen bounds in world space
    local minBoundX = math.floor(player.body:getX() - love.graphics:getWidth() / 2 - mapgen.cellsize)
    local minBoundY = math.floor(player.body:getY() - love.graphics:getHeight() / 2 - mapgen.cellsize)
    local maxBoundX = math.floor(player.body:getX() + love.graphics:getWidth() / 2 + mapgen.cellsize)
    local maxBoundY = math.floor(player.body:getY() + love.graphics:getHeight() / 2  + mapgen.cellsize)

    -- translate to world space
    love.graphics.translate(getTranslate())
    -- draw the world
    drawWorld(minBoundX, minBoundY, maxBoundX, maxBoundY)
    -- draw the bullets
    drawBullets(minBoundX, minBoundY, maxBoundX, maxBoundY)
    -- shake the screen

    local headbody = player.body
    xH, yH = headbody:getPosition()
    xH = xH - love.graphics.getWidth() / 2
    yH = yH - love.graphics.getHeight() / 2
    -- draw enemies
    for i = 1, NUM_ENEMIES do
        objects.enemies[i]:draw(xH, yH)
    end

    player:draw()

    -- translate back to screen space
    love.graphics.translate(player.body:getX() - love.graphics:getWidth()/2, player.body:getY() - love.graphics:getHeight()/2)

    -- print health hearts
    for i = 1, math.floor(player.health / 10) do
        love.graphics.draw(hearts[i], 32 * i, 30)
    end
    printFPS() -- print fps counter

    suit.draw() -- print gui

    -- player died event
    if player:isDead() then
        player.velocity = 0
        font = love.graphics.newFont(200)
        love.graphics.setFont(font)
        wasted = "WASTED" -- text on death
        love.graphics.print(wasted, (love.graphics.getWidth() / 2) - font:getWidth(wasted) / 2, (love.graphics.getHeight() / 2) - font:getHeight(wasted) / 2)
    end
end

-- print FPS
function printFPS()
    font = love.graphics.newFont(14)
    love.graphics.setFont(font)

    love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 5, 5)
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
        bulletCollision(a, b)
    elseif tonumber(a:getUserData()) ~= nil then
        bulletCollision(b, a)
    end

    if isEnemy(a) then
        if isPlayer(b) then
            player:takeDamage(objects.enemies[getIndex(a)].strength)
        end
    elseif isEnemy(b) then
        if isPlayer(a) then
            player:takeDamage(objects.enemies[getIndex(b)].strength)
        end
    end
end

function bulletCollision(a, b)
    -- update number of times a bullet touched
    if string.sub(a:getUserData(), 1, 5) == "enemy" then
        -- delete the enemy
        local idx = tonumber(string.sub(a:getUserData(), 6))
        objects.bulletTouching[b:getUserData()] = player:getGun().maxCollisions + 1
        if objects.enemies[idx].hp < 0 then
            objects.enemies[idx]:destroy()
        else
            objects.enemies[idx]:takeDamage(20)
        end
    else
        -- bounce off wall
        objects.bulletTouching[b:getUserData()] = objects.bulletTouching[b:getUserData()] + 1
    end
end

function isEnemy(fixture)
    return string.sub(fixture:getUserData(), 1, 5) == "enemy"
end

function isPlayer(fixture)
    return fixture:getUserData() == "player"
end

function getIndex(fixture)
    return tonumber(string.sub(fixture:getUserData(), 6))
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
    if #objects.bullets > 0 then -- if we bullets exist
        startShake(0.05, 1.5) -- shak    if t < shakeDuration then -- if duration not passed
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

function createEnemies()
    -- create enemies
    enemy_counter = 1 -- counting enemy ID
    Enemy = require("enemy")
    objects.enemies = {}

    for i = 1, NUM_ENEMIES do
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
        objects.enemies[i] = Enemy:new(enemy_counter, spawnX, spawnY, 32, 300, world, 5)
        enemy_counter = enemy_counter + 1
    end
end
