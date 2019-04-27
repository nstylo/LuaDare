function love.load()
    love.physics.setMeter(64)
    world = love.physics.newWorld(0, 0, true)    
    world:setCallbacks(beginContact, endContact, preSolve, postSolve)
    objects = {}
    x_vel = 500
    y_vel = 500

    objects.head = {}
        objects.head.body = love.physics.newBody(world, 400, 200, "dynamic")
        objects.head.body:setMass(1)
        objects.head.body:setAngularVelocity(0)
        objects.head.shape = love.physics.newCircleShape(30)
        objects.head.fixture = love.physics.newFixture(objects.head.body, objects.head.shape)
        objects.head.fixture:setRestitution(0)
        objects.head.fixture:setUserData("head")
        objects.head.fixture:setFriction(1)

    objects.wpn = {}
        objects.wpn.body = love.physics.newBody(world, 400, 230, "dynamic")
        objects.wpn.shape = love.physics.newRectangleShape(5, 25)
        objects.wpn.fixture = love.physics.newFixture(objects.wpn.body, objects.wpn.shape)
        objects.wpn.fixture:setUserData("Weapon")
    
    player = love.physics.newWeldJoint(objects.wpn.body, objects.head.body, 400, 230)
    player:setDampingRatio(0)

    objects.static = {}
        objects.static.b = love.physics.newBody(world, 400, 400, "static")
        objects.static.s = love.physics.newRectangleShape(200,50)
        objects.static.f = love.physics.newFixture(objects.static.b, objects.static.s)
        objects.static.f:setUserData("Block")

    objects.bullet = {} 
        objects.bullet.b = love.physics.newBody(world, 10, 10, "dynamic")
        objects.bullet.s = love.physics.newCircleShape(5)
        objects.bullet.f = love.physics.newFixture(objects.bullet.b, objects.bullet.s)
        objects.bullet.f:setRestitution(0.5)
        objects.bullet.f:setUserData("bullet")
        objects.bullet.b:setActive(false)
        objects.bullet.b:setBullet(true)

    text =""
    persisting = 0

    -- Generate map with 0s
    MapGenerator = require("MapGenerator")
    mapgen = MapGenerator:new(80, 50)
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

    x_cur, y_cur = headbody:getLinearVelocity() -- current velocity
    y_changed = false -- if y velocity has changed
    x_changed = false -- if x velocity has changed

    if kybrd.isDown("up") then
        headbody:setLinearVelocity(x_cur, -1 * y_vel) -- update velocity
        headbody:setAngle(math.max(headbody:getAngle() - 0.2, -3.4))
        y_changed = true -- we changed y
    else -- up is released
        headbody:setLinearVelocity(x_cur, 0) -- reset y velocity, leave x as previous
    end

    if kybrd.isDown("down") then
        headbody:setLinearVelocity(x_cur, y_vel) -- update velocity
        headbody:setAngle(math.max(headbody:getAngle() - 0.2, 0))
    elseif not y_changed then -- down is not pressed and we havent changed y this frame
        headbody:setLinearVelocity(x_cur, 0) -- reset y velocity
    end

    x_cur, y_cur = headbody:getLinearVelocity() -- get new velocity

    -- similarly as for y velocity
    if kybrd.isDown("left") then
        headbody:setLinearVelocity(-1 * x_vel, y_cur)
        headbody:setAngle(math.min(headbody:getAngle() + 0.2, 1.7))
        x_changed = true
    else
        headbody:setLinearVelocity(0, y_cur)
    end

    if kybrd.isDown("right") then
        headbody:setLinearVelocity(x_vel, y_cur)
        headbody:setAngle(math.max(headbody:getAngle() - 0.2, -1.7))
    elseif not x_changed then
        headbody:setLinearVelocity(0, y_cur)
    end
    if kybrd.isDown("space") then
        -- shoot

        wpn_x, wpn_y = objects.wpn.body:getPosition()
        head_x, head_y = headbody:getPosition()
        objects.bullet.b:setX(wpn_x)
        objects.bullet.b:setY(wpn_y)
        objects.bullet.b:setActive(true)
        objects.bullet.b:setLinearVelocity((wpn_x - head_x) * 10, 10* (wpn_y - head_y))
        objects.bullet.b:applyForce((wpn_x - head_x) * 100, 100 * (wpn_y - head_y))
    end
    headbody:setAngularVelocity(0)

    if string.len(text) > 768 then -- dont get too long babe
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
