--! file: player.lua
velocity = 500
bullet_speed = 800
bullet_force = 500
body_pushback = 1000
accuracy = 0 

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

function shoot(head, translate_x, translate_y, head_radius, mouse, bullet)
    -- how far away the bullet should spawn
    bullet_distance = head_radius + 3
    -- position of head and mouse
    head_x, head_y = head:getPosition()
    mouse_x, mouse_y = mouse:getPosition()
    mouse_x = mouse_x + math.abs(translate_x)
    mouse_y = mouse_y + math.abs(translate_y)
    -- vector coords to mouse
    to_mouse_x = mouse_x - head_x
    to_mouse_y = mouse_y - head_y
    -- vectors second norm
    second_norm = math.sqrt(to_mouse_x * to_mouse_x + to_mouse_y * to_mouse_y)
    -- normalize this vector
    to_mouse_x = to_mouse_x / second_norm
    to_mouse_y = to_mouse_y / second_norm
    -- transfer bullet accross this vector by distance of radius
    bullet:setX(head_x + to_mouse_x * bullet_distance)
    bullet:setY(head_y + to_mouse_y * bullet_distance)
    -- apply forces 
    bullet:applyForce(to_mouse_x * bullet_force,  to_mouse_y * bullet_force)
    -- apply innacuracy
    bullet:applyForce((1-accuracy) * math.random(200, 300),  (1-accuracy) * math.random(200, 300))
    --speed to the bullet
    bullet:setLinearVelocity(to_mouse_x * bullet_speed,  to_mouse_y * bullet_speed)
    -- apply pushback
    head:applyForce(-to_mouse_x * body_pushback, -to_mouse_y * body_pushback)
    bullet:setActive(true)
end
