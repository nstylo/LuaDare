--! file: player.lua

velocity = 500
bullet_speed = 5
bullet_force = 50
body_pushback = 10

up = "w"
down = "s"
left = "a"
right = "d"
shooot = 1

function setControls(_up, _down, _left, _right, _shoot)
    up = _up
    down = _down
    left = _left
    right = _right
    shooot = _shoot
end

function setPlayerVelocity(vel)
    velocity = vel
end

function getPlayerVelocity(cur_vel_x, cur_vel_y, kybrd)
    y_changed = false
    x_changed = false
    x_velocity = cur_vel_x
    y_velocity = cur_vel_y

    if kybrd.isDown(up) then
        y_changed = true
        y_velocity = -1 * velocity
    else
        x_velocity = cur_vel_x
        y_velocity = 0
    end

    if  kybrd.isDown(down) then
        x_velocity = cur_vel_x
        y_velocity = velocity
    elseif not y_changed then
        x_velocity = cur_vel_x
        y_velocity = 0
    end

    cur_vel_x, cur_vel_y = x_velocity, y_velocity

    if  kybrd.isDown(left) then
        x_velocity = -1 * velocity
        y_velocity = cur_vel_y
        x_changed = true
    else
        x_velocity = 0
        y_velocity = cur_vel_y
    end

    if kybrd.isDown(right) then
        x_velocity = velocity
        y_velocity = cur_vel_y
    elseif not x_changed then
        x_velocity = 0
        y_velocity = cur_vel_y
    end

    return x_velocity, y_velocity
end

function getPlayerAngle(mouse, head)
    return -1.5 + math.atan2(mouse:getY() - head:getY(), mouse:getX() - head:getX())
end

function shouldShoot(mouse)
    return mouse.isDown(shooot)
end

function setBulletProperties(force, speed, pushback)
    bullet_speed = speed
    bullet_force = force
    body_pushback = pushback
end

function shoot(wpn, head, mouse, bullet)
    wpn_x, wpn_y = wpn:getPosition()
    head_x, head_y = head:getPosition()
    mouse_x, mouse_y = mouse:getPosition()
    bullet:setX(wpn_x)
    bullet:setY(wpn_y)
    bullet:setActive(true) -- render it
    -- move bullet
    bullet:setLinearVelocity((wpn_x - head_x + math.random(5, 100)) * bullet_speed,  (wpn_y - head_y + math.random(5,100)) * bullet_speed)
    -- push bulet
    bullet:applyForce((mouse_x - wpn_x) * bullet_force, (mouse_y - wpn_y) * bullet_force)
    -- knockback
    head:applyForce((head_x - wpn_x) * body_pushback , (head_y - wpn_y) * body_pushback)
end
