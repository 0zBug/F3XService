
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Event = LocalPlayer.Character:FindFirstChild("ServerEndpoint", true) or LocalPlayer:FindFirstChild("ServerEndpoint", true)

local ClassNames = {
    Part = "Normal",
    TrussPart = "Truss",
    WedgePart = "Wedge",
    SpawnLocation = "Spawn",
    CornerWedgePart = "Corner"
}

local SyncProperties = {
    Material = "SyncMaterial",
    Color = "SyncColor",
    Size = "SyncResize",
    CFrame = "SyncMove",
    CanCollide = "SyncCollision",
    Shape = "SyncShape",
    Name = "SetName",
    Parent = "SetParent",
    Anchor = "SyncAnchored"
}

local Edit = {
    BrickColor = function(Value) return "Color", Value.Color end,
    Position = function(Value) return "CFrame", CFrame.new(Value) end
}

local F3X = {}

function F3X.new(ClassName, Parent)
    return F3X.Object(Event:InvokeServer("CreatePart", ClassNames[ClassName], CFrame.new(), Parent or Workspace))
end

function F3X.Object(Object)
    local Properties = getproperties(Object)

    return setmetatable({
        Object = Object,
        Destroy = function(self) Event:InvokeServer("Remove", {Object}) end,
        Remove = function(self) Event:InvokeServer("Remove", {Object}) end,
        AddMesh = function(self) return F3X.Object(Event:InvokeServer("CreateMeshes", {{Part = Object}})[1]) end,
        AddDecal = function(self) return F3X.Object(Event:InvokeServer("CreateTextures", {{Part = Object, Face = Enum.NormalId.Front, TextureType = "Decal"}})[1]) end,
        AddTexture = function(self) return F3X.Object(Event:InvokeServer("CreateTextures", {{Part = Object, Face = Enum.NormalId.Front, TextureType = "Texture"}})[1]) end,
        AddSmoke = function(self) return F3X.Object(Event:InvokeServer("CreateDecorations", {{Part = Object, DecorationType = "Smoke"}})[1]) end,
        AddFire = function(self) return F3X.Object(Event:InvokeServer("CreateDecorations", {{Part = Object, DecorationType = "Fire"}})[1]) end,
        AddSparkles = function(self) return F3X.Object(Event:InvokeServer("CreateDecorations", {{Part = Object, DecorationType = "Sparkles"}})[1]) end,
        AddSpotLight = function(self) return F3X.Object(Event:InvokeServer("CreateLights", {{Part = Object, LightType = "SpotLight"}})[1]) end,
        AddPointLight = function(self) return F3X.Object(Event:InvokeServer("CreateLights", {{Part = Object, LightType = "PointLight"}})[1]) end,
        AddSurfaceLight = function(self) return F3X.Object(Event:InvokeServer("CreateLights", {{Part = Object, LightType = "surfacelight"}})[1]) end,
        WeldTo = function(self, Parts) if type(Parts) ~= "table" then Parts = {Parts} end Event:InvokeServer("CreateWelds", Parts, Object) end,
        MakeJoints = function(self) Event:InvokeServer("CreateWelds", Object:GetTouchingParts(), Object) end,
        BreakJoints = function(self) local Welds = {} for _, Weld in pairs(workspace:GetDescendants()) do if Weld:IsA("Weld") and (Weld.Part0 == Object or Weld.Part1 == Object) then table.insert(Welds, Weld) end end Event:InvokeServer("RemoveWelds", Welds, Object) end
    }, {
        __index = Properties,
        __newindex = function(self, Key, Value)
            Properties[Key] = Value
            F3X.Edit(Object, {[Key] = Value})
        end
    })
end

function F3X.Edit(Object, Properties)
    spawn(function()
        if Object:IsA("BasePart") then
            for Property, Value in pairs(Properties) do
                if Edit[Property] then
                    Property, Value = Edit[Property](Value)
                end

                local Sync = SyncProperties[Property]

                if Sync == "SyncSurface" then
                    Event:InvokeServer(Sync, {{Part = Object, Surfaces = {[Property] = Value}}})
                elseif Sync == "SetName" or Sync == "SetParent" then
                    Event:InvokeServer(Sync, {Object}, Value)
                elseif Sync == "SyncShape" then
                    F3X.Object(Object):AddMesh().MeshType = tostring(Value) == "Ball" and "Sphere" or Value
                else
                    pcall(function()
                        Event:InvokeServer(Sync, {{Part = Object, [Property] = Value}})
                    end)
                end
            end
        else
            Properties.Part = Object.Parent

            if Object:IsA("SpecialMesh") then
                Event:InvokeServer("SyncMesh", {Properties})
            elseif Object:IsA("Decal") or Object:IsA("Texture") then
                Properties.TextureType = Object.ClassName
                Event:InvokeServer("SyncTexture", {Properties})
            elseif Object:IsA("Fire") or Object:IsA("Smoke") or Object:IsA("Sparkles") then
                Properties.DecorationType = Object.ClassName
                Event:InvokeServer("SyncDecorate", {Properties})
            elseif Object:IsA("SpotLight") or Object:IsA("PointLight") or Object:IsA("SurfaceLight") then
                Properties.LightType = Object.ClassName
                Event:InvokeServer("SyncLighting", {Properties})
            end
        end
    end)
end

return F3X
