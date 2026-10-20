local Visual = {}
local mesh
local function getMesh()
    if mesh then return mesh end
    local data = require(script.Parent.VolcanicEggData)
    local editable = assert(game:GetService("AssetService"):CreateEditableMesh(), "Egg mesh memory unavailable")
    local vertices, colors = {}, {}
    for i, v in data.vertices do vertices[i] = editable:AddVertex(Vector3.new(v[1], v[2], v[3])) end
    for i, c in data.colors do colors[i] = editable:AddColor(Color3.new(c[1], c[2], c[3]), 1) end
    for i, t in data.triangles do
        local face = editable:AddTriangle(vertices[t[1]], vertices[t[2]], vertices[t[3]])
        editable:SetFaceColors(face, {colors[t[4]], colors[t[4]], colors[t[4]]})
        if i % 500 == 0 then task.wait() end
    end
    editable:RemoveUnused()
    mesh = editable
    return mesh
end
function Visual.create(map)
    local world = map:WaitForChild("SkippingWorld")
    local anchor = world:WaitForChild("HackedAdminEgg")
    if world:FindFirstChild("VolcanicEggVisual") then return end
    local part = game:GetService("AssetService"):CreateMeshPartAsync(Content.fromObject(getMesh()), {CollisionFidelity=Enum.CollisionFidelity.Box})
    part.Name = "VolcanicEggVisual"
    part.Color = Color3.new(1, 1, 1)
    part.Material = Enum.Material.SmoothPlastic
    part.Anchored = true
    part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
    local data = require(script.Parent.VolcanicEggData)
    local scale = 12.5 / data.size[2]
    part.Size = Vector3.new(data.size[1], data.size[2], data.size[3]) * scale
    local stand = world:WaitForChild("HackedEggStand")
    local centerY = stand.Position.Y + stand.Size.Y / 2 + 0.3 + part.Size.Y / 2
    part.CFrame = anchor.CFrame + Vector3.new(0, centerY - anchor.Position.Y, 0)
    part:SetAttribute("SourceEgg", "02 Volcanic Inferno")
    part.Parent = world
    local fallback = world:FindFirstChild("VolcanicEggFallback")
    if fallback then fallback.LocalTransparencyModifier = 1 end
    return part
end
function Visual.start()
    -- Render locally so EditableMesh contents need no asset upload or replication.
    for _, name in {"ProgressionMap", "World2Map"} do
        task.spawn(function()
            local map = workspace:WaitForChild(name)
            local ok, err = pcall(Visual.create, map)
            if not ok then warn("Volcanic egg visual: " .. tostring(err)) end
        end)
    end
end
return Visual
