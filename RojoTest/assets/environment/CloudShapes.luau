--!strict
-- Reusable volumetric cloud recipes: local X faces outwards, local Z follows the rim.
-- Each lobe is a smooth sphere mesh stretched to the declared ellipsoid size.
return {
	{
		{ position = Vector3.new(0, -5, 0), size = Vector3.new(46, 19, 64) },
		{ position = Vector3.new(-7, 0, -17), size = Vector3.new(31, 22, 35) },
		{ position = Vector3.new(-5, 2, 17), size = Vector3.new(33, 23, 36) },
		{ position = Vector3.new(9, 7, -10), size = Vector3.new(33, 31, 36) },
		{ position = Vector3.new(15, 12, 10), size = Vector3.new(31, 34, 32) },
		{ position = Vector3.new(25, 0, 23), size = Vector3.new(30, 23, 34) },
		{ position = Vector3.new(29, -3, -23), size = Vector3.new(32, 21, 35) },
	},
	{
		{ position = Vector3.new(0, -5, 0), size = Vector3.new(47, 19, 66) },
		{ position = Vector3.new(-6, 1, -20), size = Vector3.new(32, 23, 35) },
		{ position = Vector3.new(-5, 0, 18), size = Vector3.new(34, 21, 38) },
		{ position = Vector3.new(12, 13, -8), size = Vector3.new(35, 34, 35) },
		{ position = Vector3.new(18, 7, 19), size = Vector3.new(30, 29, 34) },
		{ position = Vector3.new(29, -2, 0), size = Vector3.new(33, 25, 42) },
	},
	{
		{ position = Vector3.new(0, -5, 0), size = Vector3.new(45, 20, 65) },
		{ position = Vector3.new(-7, 0, -20), size = Vector3.new(32, 21, 36) },
		{ position = Vector3.new(-6, 1, 18), size = Vector3.new(34, 25, 35) },
		{ position = Vector3.new(10, 6, -18), size = Vector3.new(34, 29, 34) },
		{ position = Vector3.new(16, 15, 5), size = Vector3.new(34, 37, 33) },
		{ position = Vector3.new(26, 1, 26), size = Vector3.new(30, 24, 35) },
	},
}
