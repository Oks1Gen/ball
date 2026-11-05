--!strict
local Cradle = {}
local REVISION = 5

function Cradle.apply(station: Model, seat: BasePart, scale: number): number
	local storage = game:GetService("ServerStorage")
	local assets = storage:FindFirstChild("Assets")
	local stands = assets and assets:FindFirstChild("EggStands")
	local template = stands and stands:FindFirstChild("NautilusShell")
	assert(
		template and template:IsA("Model") and template:GetAttribute("Status") == "Ready",
		"Nautilus shell template is not ready"
	)
	local existing = station:FindFirstChild("ShellCradle")
	if
		existing
		and typeof(existing:GetAttribute("NautilusCradleVersion")) == "number"
		and existing:GetAttribute("NautilusCradleVersion") ~= REVISION
	then
		existing:Destroy()
		existing = nil
	end
	if existing and existing:GetAttribute("NautilusCradleVersion") ~= REVISION then
		local backups = assert(storage:FindFirstChild("WorldBackups"))
		local snapshot = backups:FindFirstChild("BeforeNautilusShells_20261105")
		if not snapshot then
			snapshot = Instance.new("Folder")
			snapshot.Name = "BeforeNautilusShells_20261105"
			snapshot.Parent = backups
		end
		existing:SetAttribute("OriginalParent", station:GetFullName())
		existing.Name = station.Name .. "_ShellCradle"
		existing.Parent = snapshot
		existing = nil
	end
	local shell: Model
	if existing then
		assert(existing:IsA("Model"))
		shell = existing
	else
		shell = (template :: Model):Clone()
		shell.Name = "ShellCradle"
		shell:SetAttribute("NautilusCradleVersion", REVISION)
		shell.Parent = station
	end
	local contact = shell:FindFirstChild("SeatContactFoot")
	if contact then
		contact:Destroy()
	end
	shell:ScaleTo(2 * scale)
	local yaw = seat.Parent and seat.Parent:GetAttribute("SeatYaw")
	local angle = if typeof(yaw) == "number" then math.rad(yaw) else 0
	shell:PivotTo(CFrame.new(seat.Position) * CFrame.Angles(0, math.pi + angle, 0))
	local base = assert(shell:FindFirstChild("Base_OctagonalBlueStone")) :: BasePart
	local sole = base.Position.Y - base.Size.Y / 2
	shell:PivotTo(shell:GetPivot() + Vector3.new(0, seat.Position.Y - sole, 0))
	-- Fill the shallow step between the inset and rim under the entire blue foot.
	-- The authored octagonal sole stays inside the seat's visible rim footprint.
	local contactHeight = 0.048 * scale
	local ratio = contactHeight / base.Size.Y
	local foot = Instance.new("Model")
	foot.Name = "SeatContactFoot"
	for _, part in shell:GetChildren() do
		if part:IsA("BasePart") and part.Name:match("^Base_OctagonalBlueStone") then
			local layer = part:Clone()
			layer.Name = "Contact_" .. part.Name
			layer.Size = Vector3.new(part.Size.X, part.Size.Y * ratio, part.Size.Z)
			local y = seat.Position.Y - contactHeight / 2 + (part.Position.Y - base.Position.Y) * ratio
			layer.CFrame = part.CFrame + Vector3.new(0, y - part.Position.Y, 0)
			layer:SetAttribute("PartRole", "DecorativeSupport")
			layer:SetAttribute("Purpose", "Full shell-foot contact across the inset-to-rim step")
			layer.Parent = foot
		end
	end
	foot.Parent = shell
	local cf, size = shell:GetBoundingBox()
	return cf.Y + size.Y / 2 + 0.08 * scale
end

return Cradle
