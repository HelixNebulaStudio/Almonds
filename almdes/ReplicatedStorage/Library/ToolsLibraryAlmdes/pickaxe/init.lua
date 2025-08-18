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

	CompatiblePileType = {"Mined"};

	Animations={
		Core={Id=16923739633;};
		PrimaryAttack={Id=17765553002};
		Load={Id=16923742307};
		Inspect={Id=16923747582; WaistStrength=0.2;};
		Charge={Id=16923735442;};
		Throw={Id=16923753693};
		Unequip={Id=16923756581};
	};
	Audio={
		Throw={Id=5083063763; Pitch=1; Volume=1;};

		Load={Id=4601593953; Pitch=1; Volume=2;};
		PrimaryHit={Id=4844105915; Pitch=1; Volume=2;};
		PrimarySwing={Id=4601593953; Pitch=1.4; Volume=2;};
	};

	Configurations={
		Category = "Pointed";
		Type="Tool";

		EquipLoadTime=0.5;
		Damage=90;

		PrimaryAttackSpeed=0.5;
		PrimaryAttackAnimationSpeed=0.5;

		HitRange=8;

		WaistRotation=math.rad(0);
		StaminaCost = 2;
		StaminaDeficiencyPenalty = 0.5;

		UseViewmodel = false;

		-- Throwable
		Throwable = true;
		ThrowDamagePercent = 0.04;

		ChargeDuration = 0.5;
		ThrowStaminaCost = 2;

		ThrowRate = 1;
		ThrowWaistRotation=math.rad(0);

		--== Projectile
		ProjectileId = "pickaxe";
		ProjectileConfig = {
			Velocity = 30;
			Bounce = 0;
			LifeTime = 10;
		};
		VelocityBonus = 30;

		ConsumeOnThrow = true;
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