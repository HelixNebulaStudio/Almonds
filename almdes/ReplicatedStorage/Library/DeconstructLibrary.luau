local DeconstructLibrary = {};
DeconstructLibrary.__index = DeconstructLibrary;
--==
local modLibraryManager = shared.require(game.ReplicatedStorage.Library.LibraryManager);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);

local library = modLibraryManager.new();

--== Templates
local function newTemplate(rewards)
	local t = {Rewards=rewards;}
	t.__index = t;
	return t;
end

local metalLight = newTemplate{
	{Index=1; ItemId="metal"; Quantity={Min=10; Max=20}; Chance=1;};
};

local woodLight = newTemplate{
	{Index=1; ItemId="wood"; Quantity={Min=10; Max=20}; Chance=1;};
};

local clothLight = newTemplate{
	{Index=1; ItemId="cloth"; Quantity={Min=10; Max=20}; Chance=1;};
};

local glassLight = newTemplate{
	{Index=1; ItemId="glass"; Quantity={Min=10; Max=20}; Chance=1;};
};

local metalWoodLight = newTemplate{
	{Index=1; ItemId="metal"; Quantity={Min=5; Max=10}; Chance=1;};
	{Index=2; ItemId="wood"; Quantity={Min=5; Max=10}; Chance=1;};
};

local clothWoodLight = newTemplate{
	{Index=2; ItemId="wood"; Quantity={Min=5; Max=10}; Chance=1;};
	{Index=1; ItemId="cloth"; Quantity={Min=5; Max=10}; Chance=1;};
};

local metalMed = newTemplate{
	{Index=1; ItemId="metal"; Quantity={Min=30; Max=40}; Chance=1;};
};

local woodMed = newTemplate{
	{Index=1; ItemId="wood"; Quantity={Min=30; Max=40}; Chance=1;};
};

local metalKey = newTemplate{
	{Index=1; ItemId="metal"; Quantity=5; Chance=1;};
};

local sulfurLight = newTemplate{
	{Index=1; ItemId="sulfur"; Quantity={Min=10; Max=20}; Chance=1;};
};

--==
library:Add(setmetatable({Id="metalpipes";}, metalLight));
library:Add(setmetatable({Id="battery";}, metalLight));
library:Add(setmetatable({Id="circuitboards";}, metalLight));
library:Add(setmetatable({Id="gastank";}, metalLight));


library:Add(setmetatable({Id="woodwindowbarricade";}, woodLight));
library:Add(setmetatable({Id="wooddoubledoors";}, woodLight));
library:Add(setmetatable({Id="wooddoor";}, woodLight));
library:Add(setmetatable({Id="woodcrate";}, woodMed));
library:Add(setmetatable({Id="barbedwooden";}, woodMed));

library:Add(setmetatable({Id="machete";}, metalWoodLight));
library:Add(setmetatable({Id="spikedbat";}, metalWoodLight));
library:Add(setmetatable({Id="crowbar";}, metalLight));
library:Add(setmetatable({Id="pickaxe";}, metalWoodLight));
library:Add(setmetatable({Id="shovel";}, metalWoodLight));

library:Add(setmetatable({Id="militaryboots";}, clothLight));
library:Add(setmetatable({Id="plankarmor";}, clothWoodLight));
library:Add(setmetatable({Id="watch";}, clothLight));
library:Add(setmetatable({Id="cowboyhat";}, clothLight));

library:Add(setmetatable({Id="p250";}, metalMed));
library:Add(setmetatable({Id="deagle";}, metalMed));

library:Add(setmetatable({Id="lockkey";}, metalKey));
library:Add(setmetatable({Id="t1key";}, metalKey));

library:Add(setmetatable({Id="molotov";}, glassLight));
library:Add(setmetatable({Id="matchbox";}, sulfurLight));


--==
for _, id in pairs(library:GetKeys()) do
	modItemsLibrary.Library:Set(id, "Deconstructible", true);
end 

return library;
