-- class Enemy
local Enemy = {}
local metatable = { __index = Enemy }


function Enemy:new(startX, startY, size, speed, world)
	local this = {}
	--math.randomseed(os.time())

	-- coordinates in world space
	this.x = 0
	this.y = 0

	-- offset from starting position
	this.xOff = startX
	this.yOff = startY

	this.hp = 1
	this.size = size
	this.speed = speed

	-- setup physics shit
	this.body = love.physics.newBody(world, startX, startY, "static")
	this.body:setMass(1)
	this.body:setAngularVelocity(0)
	this.shape = love.physics.newCircleShape(size)
	this.fixture = love.physics.newFixture(this.body, this.shape)
	this.fixture:setRestitution(0)
	this.fixture:setUserData("enemy")

	-- set random movement
	-- go horizontal
	this.goH = (math.random(0,1) <= 0.5)
	-- go neg
	this.goN = (math.random(0,1) <= 0.5)

	return setmetatable(this, metatable)

end

function Enemy:draw()
	local x = self.x - head_x
	local y = self.y - head_y
	love.graphics.setColor(1,0,0)
	love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.shape:getRadius())
	love.graphics.reset()
end

function Enemy:update(head_x, head_y)
	--[[
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
	xDiff = 0
	yDiff = 0
	self.xOff = self.xOff + xDiff
	self.yOff = self.yOff + yDiff
	]]--
	self.x = self.xOff
	self.y = self.yOff
	self.body:setX(self.xOff - head_x)
	self.body:setY(self.yOff - head_y)
end

return Enemy
