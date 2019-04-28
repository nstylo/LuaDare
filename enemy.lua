-- class Enemy
local Enemy = {}
local metatable = { __index = Enemy }

function Enemy:new(index, startX, startY, size, speed, world)
	local this = {}
	--math.randomseed(os.time())

	this.index = index
	-- coordinates in world space
	this.x = startX
	this.y = startY

	-- offset from starting position
	this.xOff = startX
	this.yOff = startY

	this.hp = 1
	this.size = size
	this.speed = speed

	-- setup physics shit
	this.body = love.physics.newBody(world, startX, startY, "dynamic")
	this.body:setMass(1)
	this.body:setAngularVelocity(0)
	this.shape = love.physics.newCircleShape(size)
	this.fixture = love.physics.newFixture(this.body, this.shape)
	this.fixture:setRestitution(0)
	this.fixture:setUserData("enemy" .. this.index)

	-- set random movement
	-- go horizontal
	this.goH = (math.random(0,1) <= 0.5)
	-- go neg
	this.goN = (math.random(0,1) <= 0.5)

	return setmetatable(this, metatable)

end

function Enemy:draw()
	love.graphics.setColor(1,0,0)
	love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.shape:getRadius())
end

function Enemy:update()
	xDiff = 0
	yDiff = 0
	if self.goH then
		if self.goN then
			xDiff = 1
		else
			xDiff = -1
		end
	else
		if self.goN then
			yDiff = 1
		else
			yDiff = -1
		end
	end
	xDiff = xDiff * self.speed
	yDiff = yDiff * self.speed
	self.xOff = self.xOff + xDiff
	self.yOff = self.yOff + yDiff


	self.x = self.xOff
	self.y = self.yOff

	self.body:setLinearVelocity(xDiff, yDiff)

	--self.body:setX(self.x)
	--self.body:setY(self.y)
end

function Enemy:getIndex()
	return self.index
end

return Enemy
