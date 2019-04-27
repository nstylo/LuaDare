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

    -- assign walkers
    local walkers = {}
    this.walkers = walkers

    -- init walkers at middle of grid
    local x = math.floor(sizeX / 2)
    local y = math.floor(sizeY / 2)
    
    for i = 1, numWalkers do
        walkers[i] = {x = x, y = y}
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

    for i=1, self.sizeX do
        for j=1, self.sizeY do
            if j == self.sizeY then -- last grid element
                file:write("0\n")
            else
                file:write("0 ")
            end
        end
    end
end

-- generate the map i.e. init the grid algorithmically
function MapGenerator:doDrunkardsWalk()
    -- TODO: drunkards walk
end

return MapGenerator
