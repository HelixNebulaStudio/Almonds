local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local PortableStorages = {};
PortableStorages.__index = PortableStorages;
--==

function PortableStorages.onRequire()

end

return PortableStorages;