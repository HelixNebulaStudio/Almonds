local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modToolsLibrary = shared.require(game.ReplicatedStorage.Library.ToolsLibrary);

function modToolsLibrary.loadNewToolPackage(toolPackage)
	local itemId = toolPackage.ItemId;

	local itemLib = modItemsLibrary:Find(itemId);

	if toolPackage.HandlerType == "FoodTool" then
		local configs = toolPackage.Configurations;
		
		if configs.Calories then
			itemLib.Description = itemLib.Description.."\n    + ".. configs.Calories .. " Calories";
		end
		if configs.Hydration then
			itemLib.Description = itemLib.Description.."\n    + ".. configs.Hydration .. " Hydration";
		end
	end

end

function modToolsLibrary.onRequire()
	for _, module in pairs(script:GetChildren()) do
		modToolsLibrary.LoadToolModule(module);
		modToolsLibrary.loadNewToolPackage(modToolsLibrary.get(module.Name));
	end
	script.ChildAdded:Connect(function(module)
		modToolsLibrary.LoadToolModule(module);
		modToolsLibrary.loadNewToolPackage(modToolsLibrary.get(module.Name));
	end);
end

return modToolsLibrary;