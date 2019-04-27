require("player")

function love.load()
    love.physics.setMeter(64)
    world = love.physics.newWorld(0, 0, true)    
    world:setCallbacks(beginContact, endContact, preSolve, postSolve)
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

    objects.bullet = {} 
        objects.bullet.b = love.physics.newBody(world, 10, 10, "dynamic")
        objects.bullet.s = love.physics.newCircleShape(10)
        objects.bullet.f = love.physics.newFixture(objects.bullet.b, objects.bullet.s)
        objects.bullet.f:setRestitution(1)
        objects.bullet.f:setUserData("bullet")
        objects.bullet.b:setActive(false)
        objects.bullet.b:setBullet(true)

    text =""
    persisting = 0

    -- Generate map with 0s
    MapGenerator = require("MapGenerator")
    mapgen = MapGenerator:new(80, 50, 10)
    mapgen:exportToFile("test.txt")
end

function beginContact(a, b, coll)
    x,y = coll:getNormal()
    text = text.."\n"..a:getUserData().." colliding with "..b:getUserData()
end

function endContact(a, b, coll)
    persisting = 0
    text = text.."\n"..a:getUserData().." uncolliding with "..b:getUserData()
end

function preSolve(a, b, coll)
    if persisting == 0 then
        text = text.."\n"..a:getUserData().." touching "..b:getUserData()
    elseif persisting < 20 then
        text = text.." "..persisting
    end
    persisting = persisting + 1
end

function postSolve(a, b, coll, normalimpulse, tangentimpulse)
end

function love.update(dt)
    world:update(dt)    

    kybrd = love.keyboard
    headbody = objects.head.body
    weaponbody = objects.wpn.body 
    bullet = objects.bullet.b 
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
        shoot(weaponbody, headbody, mouse, bullet)
    end

    headbody:setAngularVelocity(0)

    if string.len(text) > 0 then -- dont get too long babe
        text ="" 
    end
end

function love.draw()
    love.graphics.circle("line", objects.head.body:getX() , objects.head.body:getY(), objects.head.shape:getRadius())
    love.graphics.polygon("line", objects.wpn.body:getWorldPoints(objects.wpn.shape:getPoints()))
    if objects.static.b:isActive() then
        love.graphics.polygon("line", objects.static.b:getWorldPoints(objects.static.s:getPoints()))
    end
    if objects.bullet.b:isActive() then
        love.graphics.circle("fill", objects.bullet.b:getX(), objects.bullet.b:getY(), objects.bullet.s:getRadius())
    end
    love.graphics.print(text, 10, 10)
end
