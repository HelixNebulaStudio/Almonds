local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modResourcePileLibrary = shared.require(game.ReplicatedStorage.Library.ResourcePileLibrary);
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);

--==

local toolPackage = {
	ItemId=script.Name;
	Class="Melee";
	HandlerType="MeleeTool";

	CompatiblePileType = {"Chopped"};

	Animations={
		Core={Id=16971427992;};
		Load={Id=16971430052;};
		PrimaryAttack={Id=16971425618};
		HeavyAttack={Id=16971437059};
		Inspect={Id=16971433041; WaistStrength=0.2;};
		Unequip={Id=16971435376; Looped=false;};
	};
	Audio={
		Load={Id=2304904662; Pitch=0.6; Volume=0.5;};
		PrimaryHit={Id=4844105915; Pitch=1.4; Volume=1;};
		PrimarySwing={Id=4601593953; Pitch=1.4; Volume=1;};
		HeavySwing={Id=158037267; Pitch=0.70; Volume=1;};
	};
	
	Configurations={
		Category = "Edged";
		Type="Sword";

		EquipLoadTime=1;
		Damage=65;

		PrimaryAttackSpeed=1;
		PrimaryAttackAnimationSpeed=0.4;

		HeavyAttackMultiplier=1.75;
		HeavyAttackSpeed=1.4;
		HitRange=12.5;

		WaistRotation=math.rad(0);

		StaminaCost = 2;
		StaminaDeficiencyPenalty = 0.6;

		BleedDamagePercent=0.1;
		BleedSlowPercent=0.1;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

function toolPackage.BindMeleePointHit(handler: ToolHandlerInstance, packet)
	if packet == nil then return end;

	if RunService:IsClient() then
		packet.Action = "call";
		packet.CallFuncName = "BindMeleePointHit";
		return packet;
	end

	task.spawn(function()
		modResourcePileLibrary.BindToolHit(handler, packet);
	end)

	return;
end

return toolPackage;