require("player")

function love.load()
    love.physics.setMeter(64)
    world = love.physics.newWorld(0, 0, true)
    world:setCallbacks(beginContact, endContact, preSolve, postSolve)
    t, shakeDuration, shakeMagnitude = 0, -1, 0 -- initialization for camera shaking parameters
    MAX_TOUCHING = 5 -- number of times the bullets can bounce before die

    -- Generate map
    MapGenerator = require("MapGenerator")
    mapgen = MapGenerator:new(200, 200, 10, 15)
    mapgen:doDrunkardsWalk(0.3)
    mapgen:exportToFile("test.txt")
      
    objects = {} -- stores objects to draw and physics
    -- static world objects
    objects.static = {}
    initializeDrawableObjects(objects) -- initialize all drawable objects
    -- join the weapon and the player
    player = love.physics.newWeldJoint(objects.head.body, objects.wpn.body, 400, 200)
    player:setDampingRatio(0)
   
    -- contains the bullets
    objects.bullets = {} -- contains bullets currently flying
    objects.bullet_touching = {} -- number of times a bullet touches an object [bullet.f:getUserData()] = #times_touched
    bullet_amount = 0 -- amount of bullets

--    love.window.setMode(mapgen.sizeX * mapgen.cellsize, mapgen.sizeY * mapgen.cellsize)
end

function love.update(dt)
    world:update(dt)

    headbody = objects.head.body
    if t < shakeDuration then
        t = t + dt
    end

    head_x, head_y = headbody:getPosition()
    kybrd = love.keyboard
    headbody = objects.head.body
    weaponbody = objects.wpn.body
    mouse = love.mouse

    x_cur, y_cur = headbody:getLinearVelocity()
    mouse_x, mouse_y = mouse.getPosition()
    wpn_x, wpn_y = weaponbody:getPosition()
    -- update player angle and velocity 
    --
    head_x, head_y = headbody:getPosition()
    -- update player angle and velocity
    headbody:setLinearVelocity(getPlayerVelocity(x_cur, y_cur, kybrd))
    headbody:setAngle(getPlayerAngle(mouse, weaponbody)) 
    -- shoot if necessary
    if shouldShoot(mouse) then
        bullet_amount = bullet_amount + 1
        addBullet(tostring(bullet_amount))
        shoot(weaponbody, headbody, mouse, objects.bullets[table.getn(objects.bullets)].b)
    end
    headbody:setAngularVelocity(0)
end

function love.draw()
    love.graphics.reset()
    -- screen bounds in world space
    local x_bound_min = objects.head.body:getX() - love.graphics.getWidth() / 2
    local y_bound_min = objects.head.body:getY() - love.graphics.getHeight() / 2
    local x_bound_max = objects.head.body:getX() + love.graphics.getWidth() / 2
    local y_bound_max = objects.head.body:getY() + love.graphics.getHeight() / 2
    -- shake the screen
    shakeScreen()
    -- move according to player
    love.graphics.translate(-objects.head.body:getX() + love.graphics.getWidth()/2, -objects.head.body:getY() + love.graphics.getHeight()/2)
    -- draw the player
    love.graphics.circle("line", objects.head.body:getX() , objects.head.body:getY(), objects.head.shape:getRadius())
    -- draw the weapon object
    love.graphics.polygon("line", objects.wpn.body:getWorldPoints(objects.wpn.shape:getPoints()))
    -- draw the world
    drawWorld(x_bound_min, y_bound_min, x_bound_max, y_bound_max)
    -- draw the bullets
    drawBullets(x_bound_min, y_bound_min, x_bound_max, y_bound_max)
end

function initializeDrawableObjects(container) 
    initializePlayer(container)
    initializeMap(container)
end

function initializePlayer(container)
    -- player
    container.head = {}
    container.head.body = love.physics.newBody(world, 400, 200, "dynamic")
    container.head.body:setMass(0)
    container.head.body:setAngularVelocity(0)
    container.head.shape = love.physics.newCircleShape(10)
    container.head.fixture = love.physics.newFixture(container.head.body, container.head.shape)
    container.head.fixture:setRestitution(0)
    container.head.fixture:setUserData("head")
    container.head.body:setInertia(50)
    -- starting weapon
    container.wpn = {}
    container.wpn.body = love.physics.newBody(world, 400, 210, "dynamic")
    container.wpn.shape = love.physics.newRectangleShape(1, 5)
    container.wpn.fixture = love.physics.newFixture(container.wpn.body, container.wpn.shape)
    container.wpn.fixture:setUserData("Weapon")
end

-- init map in world
function initializeMap(container)
    world_blocks = container.static
    key = 0 -- key to access index
    for i = 1, mapgen.sizeX do -- for each coordinate combination
        for j = 1, mapgen.sizeY do
            if mapgen.grid[i][j] == 0 then
                -- map index to world space
                local worldX = (i - 1) * mapgen.cellsize
                local worldY = (j - 1) * mapgen.cellsize

                key = key + 1
                -- initialize the body of a static block
                world_blocks[key] = {}
                world_blocks[key].body = love.physics.newBody(world, worldX, worldY, "static")
                world_blocks[key].shape = love.physics.newRectangleShape(mapgen.cellsize, mapgen.cellsize)
                world_blocks[key].fixture = love.physics.newFixture(world_blocks[key].body, world_blocks[key].shape)
                world_blocks[key].fixture:setUserData("block")
            end
            
        end
    end
end

function drawMapBlock(r, g, b, indice)
    love.graphics.setColor(r, g, b)
    love.graphics.polygon("fill", objects.static[indice].body:getWorldPoints(objects.static[indice].shape:getPoints()))
end

function drawWorld(x_bound_min, x_bound_max, y_bound_min, y_bound_max)
    -- draw the world
    for i = 1, #objects.static do
        local rect_x, rect_y = objects.static[i].body:getPosition() -- get rectangle position
        -- if draw iff not out of bounds
        if not (rect_x < x_bound_min and rect_x > x_bound_max and rect_y < y_bound_min and rect_y > y_bound_max) then
            drawMapBlock(165,42,42,i)
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
    bullet.f:setRestitution(1) -- bouncy stuff
    bullet.f:setUserData(name)
    bullet.b:setActive(false)
    bullet.b:setBullet(true) 
    bullet.touched = 0
    table.insert(objects.bullets, bullet)
end
-- collision callbacks
function beginContact(a, b, coll)
    -- update number of times a bullet touched
    if tonumber(b:getUserData()) ~= nil then 
        objects.bullet_touching[b:getUserData()] = objects.bullet_touching[b:getUserData()] + 1
    elseif tonumber(a:getUserData()) ~= nil then
        objects.bullet_touching[a:getUserData()] = objects.bullet_touching[a:getUserData()] + 1
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
        startShake(0.5, 2) -- shake
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
        if (bullet_x < x_bound_min or bullet_y < y_bound_min
            or bullet_x > x_bound_max or bullet_y > y_bound_max) or 
            -- if the number of touchings more than 5
            tonumber(objects.bullet_touching[objects.bullets[i].f:getUserData()]) > MAX_TOUCHING then
            -- destroy the bullet
            objects.bullets[i].b:destroy()
            -- remove it from the array
            table.remove(objects.bullets, i)
            --table.remove(objects.bullet_touching, objects.bullets[i].f:getUserData())
        elseif objects.bullets[i].b:isActive() then
            -- draw the bullet
            love.graphics.circle("fill", objects.bullets[i].b:getX(), objects.bullets[i].b:getY(), objects.bullets[i].s:getRadius())
        end
    end
end

