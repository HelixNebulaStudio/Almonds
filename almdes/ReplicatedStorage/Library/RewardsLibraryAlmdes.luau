
local library = shared.require(game.ReplicatedStorage.Library.RewardsLibrary);
--==

local function newTemplate(rewards)
	local t = {Rewards=rewards;}
	t.__index = t;
	return t;
end

-- Wood Templates;
local woodLight = newTemplate{
	{Index=1; ItemId="wood"; Quantity={Min=10; Max=20}; Chance=1; Type="Custom";};
};

local woodMedium = newTemplate{
	{Index=1; ItemId="wood"; Quantity={Min=20; Max=30}; Chance=1; Type="Custom";};
};

local woodHeavy = newTemplate{
	{Index=1; ItemId="wood"; Quantity={Min=30; Max=40}; Chance=1; Type="Custom";};
};


-- Metal Templates;
local metalLight = newTemplate{
	{Index=1; ItemId="metal"; Quantity={Min=10; Max=20}; Chance=1; Type="Custom";};
};

local metalMedium = newTemplate{
	{Index=1; ItemId="metal"; Quantity={Min=20; Max=30}; Chance=1; Type="Custom";};
};

local metalHeavy = newTemplate{
	{Index=1; ItemId="metal"; Quantity={Min=30; Max=40}; Chance=1; Type="Custom";};
};

-- Wood + Random;
local woodRandom = newTemplate{
	{Index=1; ItemId="wood"; Quantity={Min=10; Max=20}; Chance=1; Type="Custom";};
	{Index=2; ItemId="metal"; Quantity={Min=10; Max=20}; Chance=1/8; Type="Custom";};
	{Index=2; ItemId="glass"; Quantity={Min=10; Max=20}; Chance=1/8; Type="Custom";};
	{Index=2; ItemId="cloth"; Quantity={Min=10; Max=20}; Chance=1/8; Type="Custom";};
};

-- Metal + Random;
local metalRandom = newTemplate{
	{Index=1; ItemId="metal"; Quantity={Min=10; Max=20}; Chance=1; Type="Custom";};
	{Index=2; ItemId="wood"; Quantity={Min=10; Max=20}; Chance=1/8; Type="Custom";};
	{Index=2; ItemId="glass"; Quantity={Min=10; Max=20}; Chance=1/8; Type="Custom";};
	{Index=2; ItemId="cloth"; Quantity={Min=10; Max=20}; Chance=1/8; Type="Custom";};
};

local tent = newTemplate{
	{Index=1; ItemId="tarp"; Quantity={Min=20; Max=30}; Chance=1; Type="Custom";};
};

function library.onRequire()
    --MARK: Generic
	library:Add(setmetatable({Id="woodLight";}, woodLight));
	library:Add(setmetatable({Id="metalLight";}, metalLight));
	
	library:Add(setmetatable({Id="woodMedium";}, woodMedium));
	library:Add(setmetatable({Id="metalMedium";}, metalMedium));

	library:Add(setmetatable({Id="woodHeavy";}, woodHeavy));
	library:Add(setmetatable({Id="metalHeavy";}, metalHeavy));
	
	library:Add(setmetatable({Id="woodRandom";}, woodRandom));
	library:Add(setmetatable({Id="metalRandom";}, metalRandom));
	
	library:Add(setmetatable({Id="tent";}, tent));


	library:Add{
		Id="envlootcrate";
		Rewards={
			{Index=1; ItemId="metal"; Quantity={Min=35; Max=70}; Chance=1;};
			{Index=1; ItemId="wood"; Quantity={Min=35; Max=70}; Chance=1;};
			{Index=1; ItemId="cloth"; Quantity={Min=35; Max=70}; Chance=1;};
			{Index=1; ItemId="glass"; Quantity={Min=35; Max=70}; Chance=0.5;};
			
			{Index=1; ItemId="metalpipes"; Quantity={Min=1; Max=3}; Chance=0.3;};
			{Index=1; ItemId="circuitboards"; Quantity={Min=1; Max=3}; Chance=0.1;};
			{Index=1; ItemId="battery"; Quantity={Min=1; Max=3}; Chance=0.1;};
			{Index=1; ItemId="gastank"; Quantity={Min=1; Max=3}; Chance=0.1;};
			
			{Index=2; ItemId="cannedbeans"; Quantity=1; Chance=1;};
			{Index=2; ItemId="cannedfish"; Quantity=1; Chance=1;};
			{Index=2; ItemId="bloxycola"; Quantity=1; Chance=1;};
			{Index=2; ItemId="chocobar"; Quantity=1; Chance=1;};
			{Index=2; ItemId="annihilationsoda"; Quantity=1; Chance=1;};
			{Index=2; ItemId="cupcake"; Quantity=1; Chance=1;};
			
			{Index=2; ItemId="medkit"; Quantity={Min=1; Max=2}; Chance=1;};
			
			{Index=2; ItemId="woodwindowbarricade"; Quantity=1; Chance=1;};
			{Index=2; ItemId="wooddoubledoors"; Quantity=1; Chance=1;};
			{Index=2; ItemId="wooddoor"; Quantity=1; Chance=1;};
			{Index=2; ItemId="woodcrate"; Quantity=1; Chance=1;};
			
			{Index=2; ItemId="machete"; Quantity=1; Chance=0.8;};
			{Index=2; ItemId="spikedbat"; Quantity=1; Chance=0.8;};
			{Index=2; ItemId="crowbar"; Quantity=1; Chance=0.8;};
			{Index=2; ItemId="pickaxe"; Quantity=1; Chance=0.8;};
			{Index=2; ItemId="shovel"; Quantity=1; Chance=0.8;};
			
			--{Index=2; ItemId="molotov"; Quantity=1; Chance=0.7;};
			
			{Index=2; ItemId="militaryboots"; Quantity=1; Chance=0.6;};
			{Index=2; ItemId="plankarmor"; Quantity=1; Chance=0.6;};
			{Index=2; ItemId="watch"; Quantity=1; Chance=0.6;};
			{Index=2; ItemId="cowboyhat"; Quantity=1; Chance=0.6;};
			
			{Index=2; ItemId="p250"; Quantity=1; Chance=0.6;};
			{Index=2; ItemId="deagle"; Quantity=1; Chance=0.6;};
			
			{Index=3; ItemId="matchbox"; Quantity={Min=1; Max=2}; Chance=0.2;};
			{Index=3; ItemId="cabbageseeds"; Quantity=1; Chance=0.1;};
			{Index=3; ItemId="t1key"; Quantity=1; Chance=0.1;};
			
			{Index=3; ItemId="explosives"; Quantity={Min=1; Max=2}; Chance=0.01;};
			{Index=3; ItemId="lightammo"; Quantity={Min=5; Max=10}; Chance=0.0875;};
			{Index=3; ItemId="shotgunammo"; Quantity={Min=5; Max=10}; Chance=0.0875;};
			--{Index=3; ItemId="heavyammo"; Quantity={Min=10; Max=20}; Chance=0.0875;};
			--{Index=3; ItemId="sniperammo"; Quantity={Min=3; Max=6}; Chance=0.0875;};
		};
	};
	
	
	library:Add{
		Id="carparkraid";
		Rewards={
			{Index=1; ItemId="explosives"; Quantity={Min=4; Max=8}; Chance=1;};
			
			{Index=2; ItemId="metal"; Quantity={Min=100; Max=200}; Chance=1;};
			{Index=2; ItemId="glass"; Quantity={Min=100; Max=200}; Chance=1;};
			{Index=2; ItemId="wood"; Quantity={Min=100; Max=200}; Chance=1;};
			{Index=2; ItemId="cloth"; Quantity={Min=100; Max=200}; Chance=1;};
			{Index=2; ItemId="m4a4"; Quantity=1; Chance=0.2;};
			{Index=2; ItemId="ak47"; Quantity=1; Chance=0.2;};
			{Index=2; ItemId="awp"; Quantity=1; Chance=0.2;};
			
			{Index=3; ItemId="metal"; Quantity={Min=100; Max=200}; Chance=1;};
			{Index=3; ItemId="glass"; Quantity={Min=100; Max=200}; Chance=1;};
			{Index=3; ItemId="wood"; Quantity={Min=100; Max=200}; Chance=1;};
			{Index=3; ItemId="cloth"; Quantity={Min=100; Max=200}; Chance=1;};
			
			{Index=4; ItemId="mk2grenade"; Quantity={Min=1; Max=2}; Chance=0.5;};
			{Index=4; ItemId="stickygrenade"; Quantity={Min=1; Max=2}; Chance=0.5;};
			{Index=4; ItemId="lightammo"; Quantity={Min=32; Max=64}; Chance=0.0875;};
			{Index=4; ItemId="heavyammo"; Quantity={Min=32; Max=64}; Chance=0.0875;};
			{Index=4; ItemId="shotgunammo"; Quantity={Min=16; Max=32}; Chance=0.0875;};
			{Index=4; ItemId="sniperammo"; Quantity={Min=8; Max=16}; Chance=0.0875;};
			
			{Index=5; ItemId="lightammo"; Quantity={Min=32; Max=64}; Chance=0.0875;};
			{Index=5; ItemId="heavyammo"; Quantity={Min=32; Max=64}; Chance=0.0875;};
			{Index=5; ItemId="shotgunammo"; Quantity={Min=16; Max=32}; Chance=0.0875;};
			{Index=5; ItemId="sniperammo"; Quantity={Min=8; Max=16}; Chance=0.0875;};
		};
	};
	
	
	library:Add{
		Id="smallbanditcamp";
		Rewards={
			{Index=1; ItemId="cz75"; Quantity=1; Chance=1;};
			{Index=1; ItemId="tec9"; Quantity=1; Chance=1;};
			{Index=1; ItemId="mp5"; Quantity=1; Chance=1;};
			{Index=1; ItemId="mp7"; Quantity=1; Chance=1;};
			
			{Index=2; ItemId="metal"; Quantity={Min=150; Max=200}; Chance=1;};
			{Index=2; ItemId="glass"; Quantity={Min=150; Max=200}; Chance=1;};
			{Index=2; ItemId="wood"; Quantity={Min=150; Max=200}; Chance=1;};
			{Index=2; ItemId="cloth"; Quantity={Min=150; Max=200}; Chance=1;};

			{Index=3; ItemId="matchbox"; Quantity={Min=3; Max=4}; Chance=0.5;};
			{Index=3; ItemId="metal"; Quantity={Min=100; Max=200}; Chance=1;};
			{Index=3; ItemId="glass"; Quantity={Min=100; Max=200}; Chance=1;};
			{Index=3; ItemId="wood"; Quantity={Min=100; Max=200}; Chance=1;};
			{Index=3; ItemId="cloth"; Quantity={Min=100; Max=200}; Chance=1;};

			{Index=4; ItemId="lightammo"; Quantity={Min=32; Max=64}; Chance=0.0875;};
			{Index=4; ItemId="heavyammo"; Quantity={Min=32; Max=64}; Chance=0.0875;};
			{Index=4; ItemId="shotgunammo"; Quantity={Min=16; Max=32}; Chance=0.0875;};
		};
	}

end


return library;