require("player")

function love.load()
    love.physics.setMeter(64)
    world = love.physics.newWorld(0, 0, true)
    world:setCallbacks(beginContact, endContact, preSolve, postSolve)
    t, shakeDuration, shakeMagnitude = 0, -1, 0

    -- Generate map
    MapGenerator = require("MapGenerator")
    mapgen = MapGenerator:new(200, 200, 10, 15)
    mapgen:doDrunkardsWalk(0.3)
    mapgen:exportToFile("test.txt")

    -- centre of map
    centre_map_x = math.floor(mapgen.sizeX * mapgen.cellsize / 2)
    centre_map_y = math.floor(mapgen.sizeY * mapgen.cellsize / 2)
      
    objects = {} -- stores objects of the to draw 
    objects.head = {} -- player
        objects.head.body = love.physics.newBody(world, centre_map_x, centre_map_y, "dynamic")
        objects.head.body:setMass(0)
        objects.head.body:setAngularVelocity(0)
        objects.head.body:setFixedRotation(false)
        objects.head.shape = love.physics.newCircleShape(10)
        objects.head.fixture = love.physics.newFixture(objects.head.body, objects.head.shape)
        objects.head.fixture:setRestitution(0)
        objects.head.fixture:setUserData("head")
        objects.head.body:setInertia(50)

    objects.wpn = {}
    objects.wpn.body = love.physics.newBody(world, centre_map_x, centre_map_y + 5, "dynamic")
    objects.wpn.shape = love.physics.newRectangleShape(1, 5)
    objects.wpn.fixture = love.physics.newFixture(objects.wpn.body, objects.wpn.shape)
    objects.wpn.fixture:setUserData("Weapon")

    player = love.physics.newWeldJoint(objects.head.body, objects.wpn.body, centre_map_x, centre_map_y)
    player:setDampingRatio(0)
   
    -- contains the bullets
    objects.bullets = {}
    objects.bullet_touching = {}
    bullet_amount = 0


    -- static world objects
    objects.static = {}

    -- init objects in worldspace
    key = 0
    for i = 1, mapgen.sizeX do
        for j = 1, mapgen.sizeY do

            if mapgen.grid[i][j] == 0 then
                local worldX = (i - 1) * mapgen.cellsize
                local worldY = (j - 1) * mapgen.cellsize

                key = key + 1
                objects.static[key] = {}
                objects.static[key].body = love.physics.newBody(world, worldX, worldY, "static")
                objects.static[key].shape = love.physics.newRectangleShape(mapgen.cellsize, mapgen.cellsize)
                objects.static.fixture = love.physics.newFixture(objects.static[key].body, objects.static[key].shape)
                objects.static.fixture:setUserData("block")
            end
            
        end
    end

    --love.window.setMode(mapgen.sizeX * mapgen.cellsize, mapgen.sizeY * mapgen.cellsize)
    love.graphics.scale(0.5, 0.5)
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

function beginContact(a, b, coll)
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

function drawBullets()
    local x_bound_min = objects.head.body:getX() - love.graphics.getWidth()
    local y_bound_min = objects.head.body:getY() - love.graphics.getHeight()
    local x_bound_max = objects.head.body:getX() + love.graphics.getWidth()
    local y_bound_max = objects.head.body:getY() + love.graphics.getHeight()

    for i=#objects.bullets,1,-1 do
        -- get location of the bullet
        local bullet_x, bullet_y = objects.bullets[i].b:getPosition()
        -- if out of bounds for screen
        if (bullet_x < x_bound_min or bullet_y < y_bound_min
            or bullet_x > x_bound_max or bullet_y > y_bound_max) or 
            
            tonumber(objects.bullet_touching[objects.bullets[i].f:getUserData()]) > 5 then

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

function love.draw()
    love.graphics.reset()

    -- shake the screen
    shakeScreen()
    -- move according to player
    love.graphics.translate(-objects.head.body:getX() + love.graphics.getWidth()/2, -objects.head.body:getY() + love.graphics.getHeight()/2)
    love.graphics.circle("line", objects.head.body:getX() , objects.head.body:getY(), objects.head.shape:getRadius())
    love.graphics.polygon("line", objects.wpn.body:getWorldPoints(objects.wpn.shape:getPoints()))

    local x_bound_min = objects.head.body:getX() - love.graphics.getWidth() / 2
    local y_bound_min = objects.head.body:getY() - love.graphics.getHeight() / 2
    local x_bound_max = objects.head.body:getX() + love.graphics.getWidth() / 2
    local y_bound_max = objects.head.body:getY() + love.graphics.getHeight() / 2

    for i = 1, #objects.static do
        local rect_x, rect_y = objects.static[i].body:getPosition()
        if not (rect_x < x_bound_min and rect_x > x_bound_max and rect_y < y_bound_min and rect_y > y_bound_max) then
            love.graphics.setColor(165,42,42)
            love.graphics.polygon("fill", objects.static[i].body:getWorldPoints(objects.static[i].shape:getPoints()))
        end
    end
    -- draw the bullets
    drawBullets()
end

