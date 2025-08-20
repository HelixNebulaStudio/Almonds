local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Bandit";
    HumanoidType = "Bandit";
    
	Configurations = {};
    Properties = {
        LootableRewardId = "bandit";
    };

    Chatter = {
        Greetings = {
            "Who's there?!";
        };
    };
    
    AddComponents = {
        "TargetHandler";
        "LootableBody";
        "PopToolDebris";
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
    local healthComp: HealthComp = npcClass.HealthComp;
    local wieldComp: WieldComp = npcClass.WieldComp;
    local properties = npcClass.Properties;

    local maxHealth = 200;
    healthComp.MaxHealth = maxHealth;
    healthComp.CurHealth = maxHealth;
    
    wieldComp.TargetableTags.Player = true;
    wieldComp.TargetableTags.Human = true;
    wieldComp.TargetableTags.Bandit = false;

    local rngGun = {
        "machete";
        "tec9";
        "p250";
    };
    properties.PrimaryWeaponItemId = rngGun[math.random(1, #rngGun)];

    local binds = npcClass.Binds;
    function binds.EquipSuccessFunc(toolHandler: ToolHandlerInstance)
        local equipmentClass: EquipmentClass? = toolHandler.EquipmentClass;
        if equipmentClass == nil then return end;

        local storageItem: StorageItem = toolHandler.StorageItem;

        if equipmentClass.Class == "Gun" then
            local modifier = equipmentClass.Configurations.newModifier("BanditGun");
            modifier.SetValues.Damage = math.random(3, 5);
            equipmentClass.Configurations:AddModifier(modifier, true);

            equipmentClass.Properties.Ammo = equipmentClass.Configurations.MagazineSize
            equipmentClass.Properties.MaxAmmo = equipmentClass.Configurations.MagazineSize * math.random(1, 3);
            storageItem:SetValues("A", equipmentClass.Properties.Ammo);
            storageItem:SetValues("MA", equipmentClass.Properties.MaxAmmo);

        elseif equipmentClass.Class == "Melee" then
            local modifier = equipmentClass.Configurations.newModifier("BanditMelee");
            modifier.SetValues.Damage = math.random(10, 15);
            equipmentClass.Configurations:AddModifier(modifier, true);
        end
    end
end

function npcPackage.Despawning(npcClass: NpcClass)
    npcClass:GetComponent("PopToolDebris")();
    npcClass.Character.Parent = workspace.Interactables;
end

return npcPackage;