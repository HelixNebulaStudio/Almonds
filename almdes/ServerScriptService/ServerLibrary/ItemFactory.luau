local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local ItemFactory = {};
ItemFactory.__index = ItemFactory;
--==

function ItemFactory.onRequire()

end

function ItemFactory.new()
    local self = {
        
    };

    setmetatable(self, ItemFactory);
    return self;
end

return ItemFactory;