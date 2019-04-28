-- gun class

-- class Gun
local Gun = {}
local metatable = {__index = Gun}

fireTime = 0 -- counter for last time fired
eps = 0.02
INACCURACY = 500

-- param firerate: in seconds, how often can shoot
-- param accuracy: how accurate [0..1] , 1 is most accurate
-- param speed: speed of bullets
-- param pushback: force applied to the player
-- param soundLoc: relative path to sound file to play
-- param bulletCreator: creates the bullet for this gun, with method .create()
function Gun:new(firerate, accuracy, speed, pushback, soundLoc, bulletCreator, bulletColor, maxCollisions)
    local this = {}

    this.rate = firerate
    this.acc = accuracy
    this.speed = speed
    this.force = pushback
    this.sound = love.audio.newSource(soundLoc, "static")
    this.bulletColor = bulletColor
    this.maxCollisions = maxCollisions
    this.bulletCreator = bulletCreator

    return setmetatable(this, metatable)
end

function Gun:playSound()
    self.sound:stop() -- stop sound if there's a request to play it again (good for gunshots)

    pitchMod = 0.8 + love.math.random(0, 10) / 25 -- add randomized pitch for variety
    self.sound:setPitch(pitchMod)

    self.sound:play()
end

-- param: mouse object
function Gun:shouldShoot(mouse)
    -- condition whether to shoot
    -- if time has passed and mouse is down
    local canShoot = false
    if (fireTime > self.rate + eps) then
        canShoot = true
    end
    -- TODO: add capacity
    return canShoot and mouse.isDown(1)
end

-- precondition: shouldShoot() == true, if not, it disables firerate :D
-- param head: body object of the shooter
-- param headRadius: radius of the shooter
-- param mouseX, mouseY: world space coordinates of mouse
-- param translate_x, translate_y: the world space coordinates of camera. most likely main.lua.getTranslate()
-- returns a new bullet
function Gun:shoot(head, headRadius, mouseX, mouseY)
    -- shoot the bullet
    fireTime = 0  -- reset firetime
    self:playSound()   -- play the sound
    local bullet_distance = headRadius + 3 -- distance to spawn from player
    local headX, headY = head:getPosition()
    -- head to mouse
    local toMouseX = mouseX - love.graphics:getWidth() / 2
    local toMouseY = mouseY - love.graphics:getHeight() / 2 
    -- size of the vector
    local scnd_norm = math.sqrt(toMouseX * toMouseX + toMouseY * toMouseY)
    -- normalize the to_mouse vector
    nrmMouseX = toMouseX / scnd_norm
    nrmMouseY = toMouseY / scnd_norm

    bullet = self.bulletCreator.create()
    bullet_body = bullet.b
    -- transfer bullet accross this vector by distance of radius + eps
    bullet_body:setX(headX + nrmMouseX * bullet_distance)
    bullet_body:setY(headY + nrmMouseY * bullet_distance)
    -- apply forces
    --bullet_body:applyForce(toMouseX * self.force, toMouseY * self.force)
    -- apply innacuracy
    bullet_body:applyForce((1 - self.acc) * math.random(-INACCURACY, INACCURACY),
    (1 - self.acc) * math.random(-INACCURACY, INACCURACY))
    -- apply speed to the bullet
    bullet_body:setLinearVelocity(toMouseX * self.speed, toMouseY * self.speed)
    -- apply pushback to the head
    head:applyForce(-toMouseX * self.force, -toMouseY * self.force)
    -- can render it now
    bullet_body:setActive(true)

    return bullet
end

function Gun:update(dt)
    fireTime = fireTime + dt

end

return Gun
