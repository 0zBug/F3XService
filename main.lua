local Player = game.Players.LocalPlayer
local serverEndpoint = Player.Character:FindFirstChild("ServerEndpoint", true) or Player:FindFirstChild("ServerEndpoint", true)
local classNames = {Part = "Normal", TrussPart = "Truss", WedgePart = "Wedge", CornerWedgePart = "Corner", SpawnLocation = "Spawn"}
local defaultProperties = {}
local defaultPart = Instance.new("Part")
local validMeshProperties = {"MeshType", "Scale", "Offset", "MeshId", "TextureId", "VertexColor"}
local validPartProperties = {"Color", "Material", "Reflectance", "Transparency", "Anchored", "CanCollide", "Shape", "Size", "CFrame", "BackSurface", "BottomSurface", "FrontSurface", "LeftSurface", "RightSurface", "TopSurface"}
local validTextureProperties = {Decal = {"Face", "Texture", "Transparency"}, Texture = {"Face", "Texture", "Transparency", "StudsPerTileU", "StudsPerTileV"}}
local validDecorationProperties = {Smoke = {"Color", "Opacity", "Size", "RiseVelocity"}, Fire = {"Color", "SecondaryColor", "Heat", "Size"}, Sparkles = {"SparkleColor"}}
local validLightingProperties = {SpotLight = {"Color", "Range", "Brightness", "Angle", "Face", "Shadows"}, PointLight = {"Color", "Range", "Brightness", "Shadows"}, SurfaceLight = {"Color", "Range", "Brightness", "Angle", "Face", "Shadows"}}
for _,property in pairs(validPartProperties) do
    defaultProperties[property] = defaultPart[property]
end
defaultProperties.Parent = workspace
defaultPart:Destroy()
local F3X = {}
function F3X.Object(object)
    local properties = {}
    if object:IsA("BasePart") then
        for _,property in pairs(validPartProperties) do
            properties[property] = object[property]
        end
    elseif object:IsA("SpecialMesh") then
        for _,property in pairs(validMeshProperties) do
            properties[property] = object[property]
        end
    elseif object:IsA("Decal") or object:IsA("Texture") then
        for _,property in pairs(validTextureProperties[object.ClassName]) do
            properties[property] = object[property]
        end
    elseif object:IsA("Fire") or object:IsA("Smoke") or object:IsA("Sparkles") then
        for _,property in pairs(validDecorationProperties[object.ClassName]) do
            properties[property] = object[property]
        end
    elseif object:IsA("SpotLight") or object:IsA("PointLight") or object:IsA("SurfaceLight") then
        for _,property in pairs(validLightingProperties[object.ClassName]) do
            properties[property] = object[property]
        end
    else
        local proxy = newproxy(true)
        local meta = getmetatable(proxy)
        proxy.Object = object
        function proxy:Destroy() serverEndpoint:InvokeServer("Remove", {object}) end
        function proxy:Remove() serverEndpoint:InvokeServer("Remove", {object}) end
        return proxy, object
    end
    for property,value in pairs(properties) do
        object:GetPropertyChangedSignal(property):Connect(function()
            properties[property] = object[property]
        end)
    end
    local proxy = newproxy(true)
    local meta = getmetatable(proxy)
    meta.__index = properties
    meta.__newindex = function(table, key, value)
        properties[key] = value
        local edited = {}
        edited[key] = value
        F3X.Edit(object, edited)
    end
    proxy.Object = object
    if object:IsA("BasePart") then
        function proxy:AddMesh() local mesh = serverEndpoint:InvokeServer("CreateMeshes", {{Part = object}})[1] return F3X.Object(mesh) end
        function proxy:AddDecal() local decal = serverEndpoint:InvokeServer("CreateTextures", {{Part = object, Face = Enum.NormalId.Front, TextureType = "Decal"}})[1] return F3X.Object(decal) end
        function proxy:AddTexture() local texture = serverEndpoint:InvokeServer("CreateTextures", {{Part = object, Face = Enum.NormalId.Front, TextureType = "Texture"}})[1] return F3X.Object(texture) end
        function proxy:AddSmoke() local smoke = serverEndpoint:InvokeServer("CreateDecorations", {{Part = object, DecorationType = "Smoke"}})[1] return F3X.Object(smoke) end
        function proxy:AddFire() local fire = serverEndpoint:InvokeServer("CreateDecorations", {{Part = object, DecorationType = "Fire"}})[1] return F3X.Object(fire) end
        function proxy:AddSparkles() local sparkles = serverEndpoint:InvokeServer("CreateDecorations", {{Part = object, DecorationType = "Sparkles"}})[1] return F3X.Object(sparkles) end
        function proxy:AddSpotLight() local spotlight = serverEndpoint:InvokeServer("CreateLights", {{Part = object, LightType = "SpotLight"}})[1] return F3X.Object(spotlight) end
        function proxy:AddPointLight() local pointlight = serverEndpoint:InvokeServer("CreateLights", {{Part = object, LightType = "PointLight"}})[1] return F3X.Object(pointlight) end
        function proxy:AddSurfaceLight() local pointlight = serverEndpoint:InvokeServer("CreateLights", {{Part = object, LightType = "surfacelight"}})[1] return F3X.Object(surfacelight) end
        function proxy:WeldTo(parts) if type(parts) ~= "table" then parts = {parts} end serverEndpoint:InvokeServer("CreateWelds", parts, object) end
        function proxy:MakeJoints() local parts = {} for _,part in pairs(object:GetTouchingParts()) do table.insert(parts, part) end serverEndpoint:InvokeServer("CreateWelds", parts, object) end
        function proxy:BreakJoints() local welds = {} for _,weld in pairs(workspace:GetDescendants()) do if weld:IsA("Weld") and (weld.Part0 == object or weld.Part1 == object) then table.insert(welds, weld) end end serverEndpoint:InvokeServer("RemoveWelds", welds, object) end
    end
    function proxy:Destroy() serverEndpoint:InvokeServer("Remove", {object}) end
    function proxy:Remove() serverEndpoint:InvokeServer("Remove", {object}) end
    return proxy, object
end

function F3X.Edit(objects, properties)
    if type(objects) ~= "table" then
        objects = {objects}
    end
    for _,object in pairs(objects) do
        spawn(function()
            if object:IsA("BasePart") then
                coroutine.wrap(serverEndpoint.InvokeServer)(serverEndpoint, "SyncAnchor", {{Part = object, Anchored = properties.Anchored}})
                for property,value in pairs(properties) do
                    if property == "BrickColor" then property = "Color" properties[property] = value.Color end
                    if property == "Position" then property = "CFrame" properties[property] = CFrame.new(value) end
                    local sync
                    if property == "Material" or property == "Transparency" or property == "Reflectance" then
                        sync = "SyncMaterial"
                    elseif property:sub(property:len() - 6) == "Surface" then
                        sync = "SyncSurface"
                        property = property:gsub("Surface", "")
                    elseif property == "Color" then
                        sync = "SyncColor"
                    elseif property == "Size" then
                        sync = "SyncResize"
                    elseif property == "CanCollide" then
                        sync = "SyncCollision"
                    elseif property == "Shape" then
                        sync = "SyncShape"
                    elseif property == "Name" then
                        sync = "SetName"
                    elseif property == "Parent" then
                        sync = "SetParent"
                    end
                    local propertyTable = {Part = object}
                    if sync == "SyncSurface" then
                        propertyTable["Surfaces"] = {}
                        propertyTable["Surfaces"][property] = value
                    elseif sync == "SetName" or sync == "SetParent" then
                        coroutine.wrap(serverEndpoint.InvokeServer)(serverEndpoint, sync, {object}, value)
                    elseif property == "SyncShape" then
                        local mesh = F3X.Object(object):AddMesh()
                        local meshType
                        if property.Name == "Ball" then meshType = "Sphere" end
                        mesh.MeshType = Enum.MeshType[property.Name]
                    else
                        propertyTable[property] = value
                    end
                    coroutine.wrap(serverEndpoint.InvokeServer)(serverEndpoint, sync, {propertyTable})
                end
                if properties.CFrame ~= nil then
                    coroutine.wrap(serverEndpoint.InvokeServer)(serverEndpoint, "SyncMove", {{Part = object, CFrame = properties.CFrame}})
                end
            elseif object:IsA("SpecialMesh") then
                properties.Part = object.Parent
                coroutine.wrap(serverEndpoint.InvokeServer)(serverEndpoint, "SyncMesh", {properties})
            elseif object:IsA("Decal") or object:IsA("Texture") then
                properties.Part = object.Parent
                properties.TextureType = object.ClassName
                coroutine.wrap(serverEndpoint.InvokeServer)(serverEndpoint, "SyncTexture", {properties})
            elseif object:IsA("Fire") or object:IsA("Smoke") or object:IsA("Sparkles") then
                properties.Part = object.Parent
                properties.DecorationType = object.ClassName
                coroutine.wrap(serverEndpoint.InvokeServer)(serverEndpoint, "SyncDecorate", {properties})
            elseif object:IsA("SpotLight") or object:IsA("PointLight") or object:IsA("SurfaceLight") then
                properties.Part = object.Parent
                properties.LightType = object.ClassName
                coroutine.wrap(serverEndpoint.InvokeServer)(serverEndpoint, "SyncLighting", {properties})
            end
        end)
    end
end

function F3X.new(className, parent)
    for name,f3xname in pairs(classNames) do
        if className == name then
            className = f3xname
        end
    end
    local properties = {}
    for property,value in pairs(defaultProperties) do
        properties[property] = value
    end
    local object = serverEndpoint:InvokeServer("CreatePart", className, CFrame.new(), parent)
    F3X.Edit(object, defaultProperties)
    return F3X.Object(object)
end

return F3X
