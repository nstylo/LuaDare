-- class Enemy
local Enemy = {}
local metatable = { __index = Enemy }


function Enemy:new(startX, startY, size, speed)
	local this = {}
	math.randomseed(os.time())

	this.x = startX
	this.y = startY

	this.hp = 1
	this.size = size
	this.speed = speed


	-- set random movement
	-- go horizontal
	this.goH = (math.random(0,1) <= 0.5)
	-- go neg
	this.goN = (math.random(0,1) <= 0.5)

end

function Enemy:draw()
	love.graphics.setColor(1,0,0)
	love.graphics.circle("line", self.x, self.y, self.size)
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

	xDiff = xDiff * speed
	yDiff = yDiff * speed
end

return Enemy
