--! file: player.lua
velocity = 200

up = "w"
down = "s"
left = "a"
right = "d"

function setControls(_up, _down, _left, _right)
    up = _up
    down = _down
    left = _left
    right = _right
end

function setPlayerVelocity(vel)
    velocity = vel
end

function getPlayerVelocity(currentVelX, currentVelY, kybrd)
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
