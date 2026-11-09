--!strict
-- Client view rules use the same split snapshot contract as the live HUD.
local V = require("./PetVariants")
local State = {}
function State.inventory(snapshot: any): any
	return snapshot.inventory or { pets = {}, equipped = {} }
end
function State.reason(pet: any, equipped: { string }, mode: string): string?
	if pet.id == "AdminDragon" then
		return "Paid pet"
	end
	if mode == "Fusion" then
		if V.form(pet) == "Rainbow" then
			return "Max form"
		end
		if table.find(equipped, pet.uid) then
			return "Equipped"
		end
	end
	return nil
end
function State.empty(petCount: number): string
	return if petCount == 0 then "Hatch an egg to get your first pet." else "No pets match your search."
end
return State
