local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local toolHandler = shared.require(game.ReplicatedStorage.Library.ToolHandler.HealTool);

function toolHandler.onRequire()
	shared.modEventService:OnInvoked("Tools_BindHealTool", function(eventPacket: EventPacket, ...)
		local action, handler, toCharacterClass = ...;

		if action == "UseComplete" then
			local equipmentClass: EquipmentClass = handler.EquipmentClass;
			local configurations = equipmentClass.Configurations;
			local properties = equipmentClass.Properties;

			local healAmount = configurations.HealAmount;

			local statusComp: StatusComp = toCharacterClass.StatusComp;

			local newHealAmount = healAmount;

			local comfortStatus: StatusClassInstance = statusComp:GetOrDefault("Comfort");
			if comfortStatus.Values.CurValue < 50 then
				local comfortRatio = math.clamp(comfortStatus.Values.CurValue / 50, 0, 1);
				newHealAmount = newHealAmount * comfortRatio;
			end

			properties.HealAmount = math.max(newHealAmount, 10);
		end
	end)
end

return toolHandler;