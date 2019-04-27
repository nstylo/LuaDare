require("player")

function love.load()
    love.physics.setMeter(64)
    world = love.physics.newWorld(0, 0, true)    
    t, shakeDuration, shakeMagnitude = 0, -1, 0 

    objects = {}
    objects.head = {}
        objects.head.body = love.physics.newBody(world, 400, 200, "dynamic")
        objects.head.body:setMass(0)
        objects.head.body:setAngularVelocity(1)
        objects.head.body:setFixedRotation(false)
        objects.head.shape = love.physics.newCircleShape(20)
        objects.head.fixture = love.physics.newFixture(objects.head.body, objects.head.shape)
        objects.head.fixture:setRestitution(0)
        objects.head.fixture:setUserData("head")
        objects.head.body:setInertia(50)

    objects.wpn = {}
        objects.wpn.body = love.physics.newBody(world, 400, 230, "dynamic")
        objects.wpn.shape = love.physics.newRectangleShape(5, 25)
        objects.wpn.fixture = love.physics.newFixture(objects.wpn.body, objects.wpn.shape)
        objects.wpn.fixture:setUserData("Weapon")
    
    player = love.physics.newWeldJoint(objects.head.body, objects.wpn.body, 400, 230)
    player:setDampingRatio(0)

    objects.static = {}
        objects.static.b = love.physics.newBody(world, 400, 400, "static")
        objects.static.s = love.physics.newRectangleShape(200,50)
        objects.static.f = love.physics.newFixture(objects.static.b, objects.static.s)
        objects.static.f:setUserData("Block")
    -- contains the bullets
    objects.bullets = {} 

    -- Generate map with 0s
    MapGenerator = require("MapGenerator")
    mapgen = MapGenerator:new(80, 50, 10)
    mapgen:exportToFile("test.txt")
end

function startShake(duration, magnitude)
    t, shakeDuration, shakeMagnitude = 0, duration or 1, magnitude or 5
end

function addBullet()
    bullet = {}
    bullet.b = love.physics.newBody(world, 10, 10, "dynamic")
    bullet.s = love.physics.newCircleShape(10)
    bullet.f = love.physics.newFixture(bullet.b,bullet.s)
    bullet.f:setRestitution(1)
    bullet.f:setUserData("bullet")
    bullet.b:setActive(false)
    bullet.b:setBullet(true) table.insert(objects.bullets, bullet)
end


function love.update(dt)
    world:update(dt)    

    if t < shakeDuration then
        t = t + dt
    end

    kybrd = love.keyboard
    headbody = objects.head.body
    weaponbody = objects.wpn.body 
    mouse = love.mouse
    
    x_cur, y_cur = headbody:getLinearVelocity() 
    mouse_x, mouse_y = mouse.getPosition()
    wpn_x, wpn_y = weaponbody:getPosition()
    head_x, head_y = headbody:getPosition()
    -- update player angle and velocity 
    --
    headbody:setLinearVelocity(getPlayerVelocity(x_cur, y_cur, kybrd))
    headbody:setAngle(getPlayerAngle(mouse, weaponbody)) 
    
    -- shoot if necessary
    if shouldShoot(mouse) then
        addBullet()
        shoot(weaponbody, headbody, mouse, objects.bullets[table.getn(objects.bullets)].b)
    end

    headbody:setAngularVelocity(0)

end

function shakeScreen()
    if #objects.bullets > 1 then
        startShake(0.2, 2)
    end
    if t < shakeDuration then
        local dx = love.math.random(-shakeMagnitude, shakeMagnitude)
        local dy = love.math.random(-shakeMagnitude, shakeMagnitude)
        love.graphics.translate(dx, dy)
    end
end

function drawBullets()
    for i=#objects.bullets,1,-1 do
        local bullet_x, bullet_y = objects.bullets[i].b:getPosition()
        -- do nothing
        if (bullet_x < 0 or bullet_y < 0 or bullet_x > love.graphics.getWidth() or bullet_y > love.graphics.getHeight()) then
            objects.bullets[i].b:destroy()
            --objects.bullets[i].b:destroy()
            table.remove(objects.bullets, i)
        elseif objects.bullets[i].b:isActive() then
            love.graphics.circle("fill", objects.bullets[i].b:getX(), objects.bullets[i].b:getY(), objects.bullets[i].s:getRadius())
        end
    end
end

function love.draw()
    shakeScreen()

    love.graphics.circle("line", objects.head.body:getX() , objects.head.body:getY(), objects.head.shape:getRadius())
    love.graphics.polygon("line", objects.wpn.body:getWorldPoints(objects.wpn.shape:getPoints()))

    if objects.static.b:isActive() then
        love.graphics.polygon("line", objects.static.b:getWorldPoints(objects.static.s:getPoints()))
    end

    drawBullets()

end
