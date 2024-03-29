-- class Enemy
local Enemy = {}
local metatable = { __index = Enemy }

function Enemy:new(index, startX, startY, size, speed, world, strength, texture)
    local this = {}

    -- unique ID
    this.index = index
    -- coordinates in world space
    this.x = startX
    this.y = startY

    -- offset from starting position
    this.xOff = startX
    this.yOff = startY

    -- texture
    this.texture = love.graphics.newImage(texture)

    -- stats
    this.hp = 30
    this.size = size
    this.speed = speed
    this.alive = true
    this.strength = strength

    -- setup physics shit
    this.body = love.physics.newBody(world, startX, startY, "dynamic")
    this.body:setMass(1)
    this.body:setAngularVelocity(0)
    this.shape = love.physics.newCircleShape(size)
    this.fixture = love.physics.newFixture(this.body, this.shape)
    this.fixture:setRestitution(0)
    this.fixture:setUserData("enemy" .. this.index)

    return setmetatable(this, metatable)
end

function Enemy:draw()
    --love.graphics.draw(texture, math.floor(objects.static[i].body:getX() - mapgen.cellsize / 2), math.floor(objects.static[i].body:getY() - mapgen.cellsize / 2))
    if self.alive then
        --love.graphics.setColor(1,0,0)
        --love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.shape:getRadius())
	love.graphics.setColor(1,1,1)
	love.graphics.draw(self.texture, self.body:getX() - 32, self.body:getY() - 32)
    end
end

function Enemy:update(player_x, player_y)
    if not self.alive then
    	return
    end
    -- declare distances to player
    local xDist
    local yDist

    -- case distinction of to set signed distance
    if self.body:getX() >= player_x then
        xDist = player_x - self.body:getX()
    else
        xDist = player_x - self.body:getX()
    end
    if self.body:getY() >= player_y then
        yDist = player_y - self.body:getY()
    else
        yDist = player_y - self.body:getY()
    end

    -- total euclidian distance
    totalDist = math.sqrt(xDist * xDist + yDist * yDist)

    -- TODO: make it non-static
    threshhold = 500

    -- if distance to player is smaller than a certain threshhold, then move towards player
    local xVelo = 0
    local yVelo = 0
    if totalDist < threshhold then
        -- velocity vector
        xVelo = xDist / (math.abs(xDist) + math.abs(yDist))
        yVelo = yDist / (math.abs(xDist) + math.abs(yDist))
    else
        xVelo = 0
        yVelo = 0
    end

    -- speed times wight in [0,1]
    xVelo = xVelo * self.speed
    yVelo = yVelo * self.speed

    -- set velocity
    self.body:setLinearVelocity(xVelo, yVelo)
end

function Enemy:getIndex()
    return self.index
end

function Enemy:takeDamage(damage)
    self.hp = self.hp - damage
end

function Enemy:destroy()
    if self.alive then
        self.body:destroy()
	self.alive = false
    end
end

return Enemy
