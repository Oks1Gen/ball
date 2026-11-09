--!strict
-- Shared by visible portraits/followers. Native vertex colours need recolouring,
-- not a texture tint. Entries exist only while models using them are alive.
local Cache = {}
local entries: { [string]: any } = {}
local colors = { Golden = Color3.fromRGB(255, 202, 45), Diamond = Color3.fromRGB(100, 228, 255) }
function Cache.apply(model: Model, form: string)
	if form == "Normal" then
		return
	end
	for _, part in model:GetDescendants() do
		if not part:IsA("MeshPart") or part.MeshId == "" then
			continue
		end
		local key = part.MeshId .. ":" .. form
		local entry = entries[key]
		if not entry then
			entry = { refs = 0, ready = false, signal = Instance.new("BindableEvent") }
			entries[key] = entry
			task.spawn(function()
				local ok, err = pcall(function()
					local mesh = game:GetService("AssetService"):CreateEditableMeshAsync(Content.fromUri(part.MeshId))
					assert(mesh, "Vertex-colour memory budget unavailable")
					entry.mesh = mesh
					local heights: { [number]: number } = {}
					if form == "Rainbow" then
						local center, size = mesh:GetCenter(), mesh:GetSize()
						for index, face in mesh:GetFaces() do
							local vertices = mesh:GetFaceVertices(face)
							for corner, id in mesh:GetFaceColors(face) do
								heights[id] = math.clamp(
									(mesh:GetPosition(vertices[corner]).Y - center.Y) / math.max(0.01, size.Y) + 0.5,
									0,
									1
								)
							end
							if index % 1000 == 0 then
								task.wait()
							end
						end
					end
					local recolored = false
					for _, id in mesh:GetColors() do
						local original = assert(mesh:GetColor(id))
						local _, s, v = original:ToHSV()
						-- Keep black mouths, white eye highlights and neutral face details.
						if s > 0.12 and v > 0.3 then
							local target = colors[form] or Color3.fromHSV((heights[id] or 0) * 0.8, 0.65, 1)
							mesh:SetColor(id, target:Lerp(Color3.new(0, 0, 0), math.clamp(1 - v, 0, 0.35)))
							recolored = true
						end
					end
					if recolored then
						entry.part = game:GetService("AssetService"):CreateMeshPartAsync(Content.fromObject(mesh))
					else
						mesh:Destroy()
						entry.mesh = nil
					end
				end)
				if not ok then
					warn("[PetVariant] " .. key .. ": " .. tostring(err))
				end
				entry.ready = true
				entry.signal:Fire()
			end)
		end
		entry.refs += 1
		local alive = true
		local function release()
			if not alive then
				return
			end
			alive = false
			entry.refs -= 1
			if entry.refs == 0 and entry.ready then
				if entry.part then
					entry.part:Destroy()
				end
				if entry.mesh then
					entry.mesh:Destroy()
				end
				entry.signal:Destroy()
				entries[key] = nil
			end
		end
		model.Destroying:Once(release)
		task.spawn(function()
			if not entry.ready then
				entry.signal.Event:Wait()
			end
			if alive and entry.part then
				local size, cf, texture = part.Size, part.CFrame, part.TextureID
				part:ApplyMesh(entry.part)
				part.Size, part.CFrame, part.TextureID = size, cf, texture
				part.Color = Color3.new(1, 1, 1)
				local surface = part:FindFirstChildOfClass("SurfaceAppearance")
				if surface then
					surface.Color = Color3.new(1, 1, 1)
				end
			end
			if not alive and entry.refs == 0 and entries[key] == entry then
				if entry.part then
					entry.part:Destroy()
				end
				if entry.mesh then
					entry.mesh:Destroy()
				end
				entry.signal:Destroy()
				entries[key] = nil
			end
		end)
	end
end
return Cache
