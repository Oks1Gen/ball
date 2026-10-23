--!strict
local Framing = {}
-- Fit every bounding-box corner to the actual viewport aspect, including depth.
function Framing.fit(camera: Camera, size: Vector3, viewport: Vector2)
	if viewport.X <= 0 or viewport.Y <= 0 then
		return
	end
	local direction = Vector3.new(0.28, 0.15, -1).Unit
	local basis = CFrame.lookAt(direction, Vector3.zero)
	local tanY = math.tan(math.rad(camera.FieldOfView / 2)) * 0.94
	local tanX = tanY * viewport.X / viewport.Y
	local distance = 0
	for _, x in { -1, 1 } do
		for _, y in { -1, 1 } do
			for _, z in { -1, 1 } do
				local point = size * Vector3.new(x, y, z) / 2
				local depth = point:Dot(direction)
				distance = math.max(
					distance,
					depth + math.abs(point:Dot(basis.RightVector)) / tanX,
					depth + math.abs(point:Dot(basis.UpVector)) / tanY
				)
			end
		end
	end
	camera.CFrame = CFrame.lookAt(direction * distance, Vector3.zero)
end
return Framing
