-- map generator class

-- class MapGenerator
local MapGenerator = {}
local metatable = { __index = MapGenerator}

-- param sizeX : define x-dimension of the grid
-- param sizeY : define y-dimension of the grid
function MapGenerator:new(sizeX, sizeY)
    -- return new object
    this = {} 

    -- assign dimensions
    this.x = sizeX
    this.y = sizeY

    -- assign an empty grid
    grid = {}
    this.grid = grid

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
    -- TODO: encode grid to file if grid is not empty  
end

-- generate the map i.e. init the grid algorithmically
function MapGenerator:doDrunkardsWalk()
    -- TODO: drunkards walk
end

return MapGenerator
