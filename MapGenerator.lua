-- map generator class

-- class MapGenerator
local MapGenerator = {}
local metatable = { __index = MapGenerator}

-- param sizeX : define x-dimension of the grid
-- param sizeY : define y-dimension of the grid
-- param numWalkers : define number of walkers
function MapGenerator:new(sizeX, sizeY, numWalkers, cellsize)
    -- return new object
    local this = {}
    math.randomseed(os.time())

    -- assign dimensions
    this.sizeX = sizeX
    this.sizeY = sizeY
    this.cellsize = cellsize

    this.numWalkPath = 0
    this.minWalkers = 1
    this.maxWalkers = 10
    this.startWalkers = numWalkers

    -- assign an empty grid
    local grid = {}
    this.grid = grid

    for i = 1, sizeX do grid[i] = {}
        for j = 1, sizeY do
            grid[i][j] = 0
        end
    end

    -- assign walkers
    local walkers = {}
    this.walkers = walkers

    -- init walkers at middle of grid
    local x = math.floor(sizeX / 2)
    local y = math.floor(sizeY / 2)

    for k = 1, this.startWalkers do
        walkers[k] = {x = x, y = y}
    end


    return setmetatable(this, metatable)
end

-- param filename : name of inputfile for level
function MapGenerator:readFile(filename)
    self.file = io.open(filename, "r")
    -- TODO: decode file to generate grid
    self.file:close()
end

-- exports grid to file
-- param filename : filename of the exported level file
function MapGenerator:exportToFile(filename)
    local file = io.open("test.txt", "w+")

    for i = 1, self.sizeX do
        for j = 1, self.sizeY do
            if j == self.sizeY then -- last grid element
                file:write(self.grid[i][j] .. "\n")
            else
                file:write(self.grid[i][j] .. " ")
            end
        end
    end
    file:seek("set", 0)
    file:close()
end

-- generate the map i.e. init the grid algorithmically
function MapGenerator:doDrunkardsMove(w)
    -- TODO: drunkards walk
    rand = math.random(1, 4) -- generate random number [1, 4]

    walker = self.walkers[w] -- walker we're working with

    if walker.y ~= 1 and rand == 1 then -- north
        walker.y = walker.y - 1
    elseif walker.y ~= self.sizeY and rand == 2 then -- south
        walker.y = walker.y + 1
    elseif walker.x ~= self.sizeX and rand == 3 then -- east
        walker.x = walker.x + 1
    elseif walker.x ~= 1 and rand == 4 then -- west
        walker.x = walker.x - 1
    end

    -- check if current grid index is a 0, if so, then change to 1 and increment counter
    if self.grid[walker.x][walker.y] == 0 then
        self.grid[walker.x][walker.y] = 1
        self.numWalkPath = self.numWalkPath + 1 -- increment number of non 0s
    end
end

-- Delete walkers with a certain chance
function MapGenerator:delWalker()
    local chanceWalkerDel = 0.001

    for i=#self.walkers,1,-1 do
        if math.random() < chanceWalkerDel and #self.walkers > self.minWalkers then
            table.remove(self.walkers, i) -- remove the walker
            do return end
        end
    end
end

-- Add walkers with a certain chance
function MapGenerator:addWalker()
    local chanceWalkerAdd = 0.001

    for i=1, #self.walkers do
        if math.random() < chanceWalkerAdd and #self.walkers < self.maxWalkers then
            local walker = {} -- Create new walker
            -- Set new walker's x and y coords to i walker's
            walker.x = self.walkers[i].x
            walker.y = self.walkers[i].y
            table.insert(self.walkers, walker) -- insert the new walker
        end
    end
end

-- clear an area of the spawn
function MapGenerator:clearSpawn()
    -- get the middle of the grid
    local middleX = math.floor(self.sizeX / 2)
    local middleY = math.floor(self.sizeY / 2)

    -- clear a 20x20 area at spawn
    for i=(middleX-10), (middleX+10) do
        for j=(middleY-10), (middleY+10) do
            self.grid[i][j] = 1 -- set the points to a path
        end
    end
end

-- param perc : the percentage covered with walking paths
function MapGenerator:doDrunkardsWalk(perc)
    -- iter is given in percentage
    if perc > 1 then
        perc = 1
    elseif perc < 0 then
        perc = 0
    end

    -- walk with a walker until we find a tile to set to 1
    -- until the desired percentage is reached
    while (self.numWalkPath / (self.sizeX * self.sizeY)) < perc do
        self:delWalker()
        self:addWalker()
        self:doDrunkardsMove((self.numWalkPath % #self.walkers) + 1)
    end
    self:clearSpawn()
end

return MapGenerator

