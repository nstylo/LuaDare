-- map generator class

-- class MapGenerator
local MapGenerator = {}
local metatable = { __index = MapGenerator}

-- param sizeX : define x-dimension of the grid
-- param sizeY : define y-dimension of the grid
-- param numWalkers : define number of walkers
function MapGenerator:new(sizeX, sizeY, numWalkers)
    -- return new object
    local this = {} 

    -- assign dimensions
    this.sizeX = sizeX
    this.sizeY = sizeY

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
    
    for k = 1, numWalkers do
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
end

-- generate the map i.e. init the grid algorithmically
function MapGenerator:doDrunkardsWalk(w)
    -- TODO: drunkards walk
    math.randomseed(os.time())
    rand = math.random(1, 4) -- generate random number [1, 4]

    print("Walker #: " .. w)
    walker = self.walkers[w] -- walker we're working with

    if rand == 1 then -- north
        print("north")
        walker.y = walker.y - 1
    elseif rand == 2 then -- south
        print("south")
        walker.y = walker.y + 1
    elseif rand == 3 then -- east
        print("east")
        walker.x = walker.x - 1
    elseif rand == 4 then -- west
        print("west")
        walker.x = walker.x + 1
    end

    -- check if current grid index is a 0, if so, then change to 1 and increment counter
    if self.grid[walker.x][walker.y] == 0 then
        self.grid[walker.x][walker.y] = 1
        self.numWalkPath = self.numWalkPath + 1 -- increment number of non 0s
    end
end

return MapGenerator
