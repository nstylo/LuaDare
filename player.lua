-- player class

-- class Player

local Player = {}
local metatable ={__index = Player}
velocity = 200

up = "w"
down = "s"
left = "a"
right = "d"

-- param velocity: speed of the player
-- param startingGun: starting gun
-- param health: starting health
-- param world: the love2d world of the player
-- param startX,startY: world space starting coordinates
function Player:new(velocity, startingGun, startX, startY, health, world, texture_path)
    local this = {}

    this.velocity = velocity
    this.gun = startingGun
    this.health = health
    this.texture = love.graphics.newImage(texture_path)

    -- set physics parameter
    this.body = love.physics.newBody(world, startX, startX, "dynamic")
    this.body:setMass(1)
    this.body:setAngularVelocity(0)
    this.shape = love.physics.newCircleShape(10)
    this.fixture = love.physics.newFixture(this.body, this.shape)
    this.fixture:setUserData("player")
    this.fixture:setRestitution(0)

    return setmetatable(this, metatable)
end

-- gives the gun to a player
-- param newGun: gun to give to the player
function Player:giveGun(newGun)
    -- TODO: support multiple guns
    self.gun = newGun
end

function Player:isDead()
    return self.health <= 0
end


-- getter for the gun
function Player:getGun()
    -- TODO: support multiple guns
    return self.gun
end

-- decrease health of player
function Player:takeDamage(dmg)
    self.health = self.health - dmg
end

-- change the controls of the players, must be keyboard
function Player:setControls(_up, _down, _left, _right)
    up = _up
    down = _down
    left = _left
    right = _right
end

-- change the velocity of the player
function Player:setPlayerVelocity(vel)
    self.velocity = vel
end

-- calculates the velocity according to the previous velocity
-- and the keyboard presses
-- param currentVelX: current linear velocity on x axis
-- similarly for currentVelY
-- param kybrd: love2d keyboard object
function Player:getLinearPlayerVelocity(currentVelX, currentVelY, kybrd)
    changedY = false
    changedX = false
    velocityX = currentVelX
    velocityY = currentVelY

    if kybrd.isDown(up) then
        changedY = true
        velocityY = -1 * velocity
    else
        velocityX = currentVelX
        velocityY = 0
    end

    if  kybrd.isDown(down) then
        velocityX = currentVelX
        velocityY = velocity
    elseif not changedY then
        velocityX = currentVelX
        velocityY = 0
    end

    currentVelX, currentVelY = velocityX, velocityY

    if  kybrd.isDown(left) then
        velocityX = -1 * velocity
        velocityY = currentVelY
        changedX = true
    else
        velocityX = 0
        velocityY = currentVelY
    end

    if kybrd.isDown(right) then
        velocityX = velocity
        velocityY = currentVelY
    elseif not changedX then
        velocityX = 0
        velocityY = currentVelY
    end

    return velocityX, velocityY
end

function Player:draw()
    --love.graphics.setColor(1, 1, 1)
    --love.graphics.circle("fill", self.body:getX() , self.body:getY(), self.shape:getRadius())
    love.graphics.draw(self.texture, self.body:getX() - self.texture:getWidth() / 2, self.body:getY() - self.texture:getWidth() / 2)
end

function Player:update(dt, kybrd)
    local currentVelX, currentVelY = self.body:getLinearVelocity()
    -- update velocity
    self.body:setLinearVelocity(self:getLinearPlayerVelocity(currentVelX, currentVelY, kybrd))
    self.body:setAngularVelocity(0)
end

return Player
