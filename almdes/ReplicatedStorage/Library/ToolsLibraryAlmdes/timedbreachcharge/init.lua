local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="ThrowableTool";

	Animations={
		Core={Id=11424227585;};
		Charge={Id=11424271630;};
		Throw={Id=11424299380};
	};
	Audio={
		ProjectileBounce={Id=5082995723; Pitch=1; Volume=1;};
		Throw={Id=5083063763; Pitch=1; Volume=1;};
	};
	Configurations={
		ExplosionRadius = 35;
		
		ExplosionStun=1;
		Damage=250;
		ChargeDuration = 0.2;

		DirectionOffset = Vector3.new(0, 0.35, 0);

		--== Projectile
		ProjectileId = "TimedExplosive";
		ProjectileConfig={
			Acceleration = Vector3.new(0, -workspace.Gravity*3, 0);
			Velocity = 100;
			Bounce = 0;
			LifeTime = 20;
		};

		ConsumeOnThrow=true;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;