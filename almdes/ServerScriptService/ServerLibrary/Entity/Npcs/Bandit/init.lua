local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Bandit";
    HumanoidType = "Bandit";
    
	Configurations = {};
    Properties = {};

    Chatter = {
        Greetings = {
            "Who's there?!";
        };
    };
    
    AddComponents = {
        "TargetHandler";
        "DropReward";
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
    local healthComp: HealthComp = npcClass.HealthComp;
    local wieldComp: WieldComp = npcClass.WieldComp;
    local properties = npcClass.Properties;

    local maxHealth = 200;
    healthComp.MaxHealth = maxHealth;
    healthComp.CurHealth = maxHealth;
    
    wieldComp.TargetableTags.Humanoid = true;
    wieldComp.TargetableTags.Human = true;
    wieldComp.TargetableTags.Bandit = false;

    local rngGun = {
        "machete";
        "tec9";
        "p250";
    };
    properties.PrimaryWeaponItemId = rngGun[math.random(1, #rngGun)];

    npcClass.Garbage:Tag(npcClass.OnThink:Connect(function()
        npcClass.BehaviorTree:RunTree("BanditDefaultTree", true);
    end));
end

function npcPackage.Spawned(npcClass: NpcClass)
end


return npcPackage;