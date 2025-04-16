local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local MetaStatusComponent = {};
MetaStatusComponent.__index = MetaStatusComponent;
MetaStatusComponent.base = MetaStatusComponent;
MetaStatusComponent.Script = script;

function MetaStatusComponent.new(compOwner: ComponentOwner)
    local self = {
        -- @properties
        CompOwner = compOwner;

        CurHunger = 50;
        MaxHunger = 100;

        CurThirst = 50;
        MaxThirst = 100;

        CurComfort = 50;
        MaxComfort = 100;

        -- @signals
    };

    setmetatable(self, MetaStatusComponent);
    return self;
end



return MetaStatusComponent;