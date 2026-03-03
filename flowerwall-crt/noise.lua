local Noise = {}

function Noise.generate(size)
    size = size or 256
    local data = love.image.newImageData(size, size)
    for y = 0, size - 1 do
        for x = 0, size - 1 do
            local v = love.math.random()
            data:setPixel(x, y, v, v, v, 1)
        end
    end
    local img = love.graphics.newImage(data)
    img:setFilter("linear", "linear")
    img:setWrap("repeat", "repeat")
    return img
end

return Noise
