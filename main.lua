require("player")

function love.load()
    love.physics.setMeter(64)
    world = love.physics.newWorld(0, 0, true)    
    world:setCallbacks(beginContact, endContact, preSolve, postSolve)
    objects = {}
    x_vel = 500
    y_vel = 500

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
    mouse_x, mouse_y = love.mouse.getPosition()
    wpn_x, wpn_y = objects.wpn.body:getPosition()
    head_x, head_y = headbody:getPosition()
    
    headbody:setLinearVelocity(getVelocity(x_cur, y_cur, kybrd))

    --headbody:setLinearVelocity(-wpn_x + mouse_x, -wpn_y + mouse_y)
    --objects.wpn.body:setAngle(math.atan2(wpn_x - mouse_x, wpn_y - mouse_y))
    --headbody:setAngle(headbody:getAngle() - findangle(wpn_x - head_x, wpn_y - head_y, mouse_x - head_x, mouse_y - head_y))
    headbody:setAngle(-1.5 + math.atan2(mouse_y - wpn_y, mouse_x - wpn_x)) 
    --objects.wpn.body:setAngle(math.atan2(wpn_x - mouse_x, wpn_y - mouse_y))

    if kybrd.isDown("space") then
        -- shoot
        objects.bullet.b:setX(wpn_x)
        objects.bullet.b:setY(wpn_y)
        objects.bullet.b:setActive(true)
        objects.bullet.b:setLinearVelocity((wpn_x - head_x) * 10, 10 * (wpn_y - head_y))
        objects.bullet.b:applyForce((-1 * wpn_x + mouse_x) * 100, 100 * (-1 * wpn_y +  mouse_y))
        headbody:applyForce((wpn_x - head_x) * 500, 500 * (wpn_y - head_y))
    end

    headbody:setAngularVelocity(0)
    if string.len(text) > 0 then -- dont get too long babe
        text ="" 
    end
end

function findangle(x1, y1, x2, y2)
    local dot_product = x1 * x2 + y1 * y2
    local l1 = x1 * x1 + y1 * y1
    local l2 = x2 * x2 + y2 * y2
    return  math.acos(dot_product / (math.sqrt(l1) * math.sqrt(l2)))
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
