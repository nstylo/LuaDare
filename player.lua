--! file: player.lua
    
velocity = 500 

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


function getVelocity(cur_vel_x, cur_vel_y, kybrd)
    y_changed = false
    x_changed = false
    x_velocity = cur_vel_x
    y_velocity = cur_vel_y

    if kybrd.isDown(up) then
        y_changed = true
        y_velocity = -1 * velocity
    else
        x_velocity = cur_vel_x
        y_velocity = 1 
    end

    if  kybrd.isDown(down) then
        x_velocity = cur_vel_x
        y_velocity = velocity
    elseif not y_changed then
        x_velocity = cur_vel_x
        y_velocity = 1
    end

    cur_vel_x, cur_vel_y = x_velocity, y_velocity

    if  kybrd.isDown(left) then
        x_velocity = -1 * velocity
        y_velocity = cur_vel_y
        x_changed = true
    else
        x_velocity = 1
        y_velocity = cur_vel_y
    end

    if kybrd.isDown(right) then
        x_velocity = velocity
        y_velocity = cur_vel_y
    elseif not x_changed then
        x_velocity = 1
        y_velocity = cur_vel_y
    end

    return x_velocity, y_velocity
end

