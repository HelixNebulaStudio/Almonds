local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local ItemFactory = {};
ItemFactory.__index = ItemFactory;
--==

function ItemFactory.onRequire()

end

return ItemFactory;