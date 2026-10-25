--!strict
-- Add future collection pages here; every entry uses the same window and routing.
local Tabs = {}
Tabs.Entries = {
	{ Id = "Balls", Route = "Inventory", Title = "My Balls", Icon = "Ball" },
	{ Id = "Pets", Route = "Pets", Title = "My Pets", Icon = "Pets" },
	{ Id = "Eggs", Route = "Eggs", Title = "My Eggs", Icon = "Egg" },
}
function Tabs.resolve(route: string): any
	for _, tab in Tabs.Entries do
		if tab.Route == route or tab.Id == route then
			return tab
		end
	end
	return nil
end
return Tabs
