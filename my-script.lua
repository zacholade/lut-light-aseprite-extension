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
    normalImage:drawSprite(sprite, app.site.frameNumber or 1, Point(0, 0))
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


function init(plugin)
    plugin:newCommand{
        id="aesprite_lut_light",
        title="Open Lut Light Dialogue",
        group="foo",
        onclick=OpenDialogue,
        onenabled=OpenDialogue,
    }
end


-- Main dialog window
-- Dlg = Dialogue("LutLight Preview")
CURRENT_SPRITE = "<Currently open sprite>"
CanvasScale = 8
GradientListenerCode = nil
SpriteListenerCode = nil
CurrentSpriteName = CURRENT_SPRITE
GradientSpriteName = nil
CurrentSprite = app.sprite
GradientSprite = nil


function SpriteNames()
    local spriteNames = {}
    for _, sprite in ipairs(app.sprites) do
        table.insert(spriteNames, sprite.filename)
    end
    return spriteNames
end


function Repaint()
    Dlg:repaint()
end


function UpdateCanvas(ev)
    local gc = ev.context
    local lightLevel = Dlg.data.light_level
    GradientSpriteName = Dlg.data.gradient_map_sprite_name
    GradientSprite = findSpriteByName(GradientSpriteName)
    CurrentSpriteName = Dlg.data.current_sprite
    if CurrentSpriteName == CURRENT_SPRITE then
        CurrentSprite = app.sprite
    else
        CurrentSprite = findSpriteByName(CurrentSpriteName)
    end

    if GradientSprite == nil or CurrentSprite == nil then
        return
    end

    local gradientMap = loadGradientMap(GradientSprite)
    local newImage = applyGradientMap(CurrentSprite, gradientMap, lightLevel)
    newImage:resize(newImage.width * CanvasScale, newImage.height * CanvasScale)
    gc:drawImage(newImage, 0, 0)

end

function UpdateDlg(ev)
    if SpriteListenerCode ~= nil and CurrentSprite ~= nil then
        CurrentSprite.events:off(SpriteListenerCode)
    end
    if GradientListenerCode ~= nil and GradientSprite ~= nil then
        GradientSprite.events:off(GradientListenerCode)
    end

    UpdateCanvas(ev)

    if CurrentSprite ~= nil then
        SpriteListenerCode = CurrentSprite.events:on("change", Repaint)
    end
    if GradientSprite ~= nil then
        GradientListenerCode = GradientSprite.events:on("change", Repaint)
    end

end


function OpenDialogue()
    if CurrentSprite == nil then
        return
    end
    Dlg = Dialog("LutLight Preview")

    Dlg:combobox{
        id = "gradient_map_sprite_name",
        label = "Gradient Map:",
        options=SpriteNames(),
        option=next(SpriteNames()),
        onchange=function()
            Dlg:modify{id="light_level", max=findSpriteByName(Dlg.data.gradient_map_sprite_name).height - 1}
            Dlg:repaint()
        end
    }

    Dlg:combobox{
        id = "current_sprite",
        label = "Current Sprite:",
        options={CURRENT_SPRITE, table.unpack(SpriteNames())},
        option=CURRENT_SPRITE,
        onchange=Repaint
    }

    Dlg:slider{
        id = "light_level",
        label = "Light Level:",
        min = 0,
        max = findSpriteByName(Dlg.data.gradient_map_sprite_name).height - 1,
        value = 0,
        onchange=Repaint
    }

    Dlg:canvas{
        width=CurrentSprite.width * CanvasScale,
        height=CurrentSprite.height * CanvasScale,
        onpaint=UpdateDlg,
        onmousekeydown=Repaint,
        autoscaling=true
    }
    Dlg:show{wait=false}

end

app.events:on("sitechange",
    function()
        Repaint()
    end
)