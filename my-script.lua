function loadGradientMap(sprite)
    local gradientMap = {}
    local gradientMapImage = Image{width=sprite.width, height=sprite.height, colorMode=sprite.colorMode}
    gradientMapImage:drawSprite(sprite)
    for x = 0, gradientMapImage.width - 1 do
        local baseColour = gradientMapImage:getPixel(x, 0)
        gradientMap[baseColour] = {}
        for y = 0, gradientMapImage.height - 1 do
            local lightLevelColour = gradientMapImage:getPixel(x, y)
            gradientMap[baseColour][gradientMapImage.height - 1 - y] = lightLevelColour
        end
    end
    return gradientMap
end

function applyGradientMap(sprite, gradientMap, lightLevel)
    local lightLevelImage = Image(sprite.spec)
    local normalImage = Image{width=sprite.width, height=sprite.height, colormode=sprite.colorMode}
    normalImage:drawSprite(sprite, app.frame.frameNumber, Point(0, 0))
    for y = 0, sprite.height - 1 do
        for x = 0, sprite.width - 1 do
            local pixelColor = normalImage:getPixel(x, y)
            local newColor
            if gradientMap[pixelColor] and gradientMap[pixelColor][lightLevel] then
                newColor = Color(gradientMap[pixelColor][lightLevel])
            else
                -- Set a default value if the key doesn't exist
                newColor = Color{r=255, g=0, b=195, a=255}
            end
            lightLevelImage:drawPixel(x, y, newColor)
        end
    end

    return lightLevelImage
end


function findSpriteByName(name)
    for _, sprite in ipairs(app.sprites) do
        if sprite.filename == name then
            return sprite
        end
    end
    return nil  -- If the sprite with the given name is not found
end



-- Main dialog window
Dlg = Dialog("Gradient Map Preview")
GradientListenerCode = nil
SpriteListenerCode = nil


local canvasScale = 6

local sprite_names = {}
for _, sprite in ipairs(app.sprites) do
    table.insert(sprite_names, sprite.filename)
end

if next(sprite_names) == nil then
    Dlg:label{ id="warning", label="Cannot load gradient map", text="No sprites are currently open to select"}
    return Dlg
end


function repaint()
    Dlg:repaint()
end


function updateCanvas(ev)
    local gc = ev.context
    local gradientSprite = findSpriteByName(Dlg.data.gradient_map_sprite_name)
    local lightLevel = Dlg.data.light_level

    if gradientSprite == nil then
        print("Failed to find gradient map sprite open")
    end

    local gradientMap = loadGradientMap(gradientSprite)
    local newImage = applyGradientMap(app.sprite, gradientMap, lightLevel)
    newImage:resize(newImage.width * canvasScale, newImage.height * canvasScale)
    gc:drawImage(newImage, 0, 0)
    if SpriteListenerCode ~= nil then
        app.sprite.events:off(SpriteListenerCode)
    end
    if GradientListenerCode ~= nil then
        gradientSprite.events:off(GradientListenerCode)
    end

    GradientListenerCode = gradientSprite.events:on("change", repaint)
    SpriteListenerCode = app.sprite.events:on("change", repaint)
end

Dlg:combobox{
    id = "gradient_map_sprite_name",
    label = "Gradient Map:",
    options=sprite_names,
    option=sprite_names[1],
    onchange=function()
        Dlg:modify{id="light_level", max=findSpriteByName(Dlg.data.gradient_map_sprite_name).height - 1}
        Dlg:repaint()
    end
}

Dlg:slider {
    id = "light_level",
    label = "Light Level:",
    min = 0,
    max = findSpriteByName(Dlg.data.gradient_map_sprite_name).height - 1,
    value = 0,
    onchange=function() Dlg:repaint() end
}

Dlg:canvas {
    width=app.sprite.width * canvasScale,
    height=app.sprite.height * canvasScale,
    onpaint=updateCanvas,
    onmousekeydown=function() Dlg:repaint() end,
    autoscaling=true
}


-- gradientSprite.events:off(repaint)
print('off eventd')
app.events:on("sitechange", repaint)
print('done events')
Dlg:show{wait=false}
