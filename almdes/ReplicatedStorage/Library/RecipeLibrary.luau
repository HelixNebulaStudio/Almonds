local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modLibraryManager = shared.require(game.ReplicatedStorage.Library.LibraryManager);
local library = modLibraryManager.new();

local categories = {
	Resources = {Key="Resources"; IconItemId="gunpowder"; Order=10};
	Tools = {Key="Tools"; IconItemId="hammer"; Order=20};
	Clothing = {Key="Clothing"; IconItemId="plankarmor"; Order=30};
	Weapons = {Key="Weapons"; IconItemId="machete"; Order=40};
	Buildings = {Key="Buildings"; IconItemId="wooddoor"; Order=50};
	Medical = {Key="Medical"; IconItemId="medkit"; Order=60};
	Raiding = {Key="Raiding"; IconItemId="explosives"; Order=70};
	Ammunition = {Key="Ammunition"; IconItemId="lightammo"; Order=80};
}

function library:Categorize()
	local list = {};
	
	local wholeLib = library:GetIndexList();
	for a=1, #wholeLib do
		local lib = wholeLib[a];
		local key = lib.Category.Key;
		if list[key] == nil then
			list[key] = {};
		end
		
		table.insert(list[key], lib);
	end
	
	return list;
end

local treeBranches = {
	Tools = {Key="Tools"; RootLink="center"; Order=1;};
	
	BasicStructure = {Key="BasicStructure"; RootLink="center"; Order=20;};
	TacStructure = {Key="TacStructure"; RootLink="BasicStructure"; Order=30;};
	DefStructure = {Key="DefStructure"; RootLink="BasicStructure"; Order=32;};
	RpStructure = {Key="RpStructure"; RootLink="BasicStructure"; Order=40;};

	Weapons = {Key="Weapons"; RootLink="center"; Order=50;};
	
	Guns = {Key="Guns"; RootLink="Weapons"; Order=51;};
	
	Melee = {Key="Melee"; RootLink="Weapons"; Order=60;};
	BluntMelee = {Key="BluntMelee"; RootLink="Melee"; Order=70;};
	EdgeMelee = {Key="EdgeMelee"; RootLink="Melee"; Order=80;};

	Raiding = {Key="Raiding"; RootLink="center"; Order=90;};
	SoftRaid = {Key="SoftRaid"; RootLink="Raiding"; Order=100;};
	HardRaid = {Key="HardRaid"; RootLink="Raiding"; Order=110;};
	Ammunition = {Key="Ammunition"; RootLink="Raiding"; Order=120;};
	
	Clothing = {Key="Clothing"; RootLink="center"; Order=130;};
	RpClothing = {Key="RpClothing"; RootLink="Clothing"; Order=140;};
	ArmorClothing = {Key="ArmorClothing"; RootLink="Clothing"; Order=110;};
	WarmClothing = {Key="WarmClothing"; RootLink="Clothing"; Order=170;};
	ProClothing = {Key="ProClothing"; RootLink="ArmorClothing"; Order=180;};
}

function library:GetTechTree(seed)
	local randoms = {};
	local list = {};
	
	local wholeLib = library:GetIndexList();
	for a=1, #wholeLib do
		local item = wholeLib[a];
		if item.Workbench == nil then continue end;

		local branchKey = item.Branch.Key;

		if list[branchKey] == nil then
			list[branchKey] = {};
		end
		if randoms[branchKey] == nil then
			randoms[branchKey] = Random.new(seed);
		end

		local random = randoms[branchKey];
		local offset = random:NextNumber(-0.15, 0.15);
		
		item.TotalRarity = (item.Rarity or 1) + offset;
		--if item.Workbench > 1 and item.Rarity > 1 then continue end;
		
		table.insert(list[branchKey], item);
	end
	
	for branchKey, _ in pairs(list) do
		table.sort(list[branchKey], function(a, b)
			return a.TotalRarity > b.TotalRarity;
		end)
	end
	
	return list;
end

local workbenchTypes = {
	BasicWorkbench = "workbench";
};

library.WorkbenchTypes = workbenchTypes;

library:Add{
	Id="torch";
	Category=categories.Tools;
	Recipe={
		{Type="Item"; ItemId="wood"; Amount=20};
		{Type="Item"; ItemId="cloth"; Amount=10};
	};
	Duration=5;
}

library:Add{
	Id="campfire";
	Category=categories.Buildings;
	Recipe={
		{Type="Item"; ItemId="wood"; Amount=20};
	};
	--Duration=5;
	--Amount=2;
}

library:Add{
	Id="furnace";
	Category=categories.Buildings;
	Recipe={
		{Type="Item"; ItemId="metal"; Amount=200};
	};
	Duration=30;
}

library:Add{
	Id="lantern";
	Category=categories.Tools;
	Recipe={
		{Type="Item"; ItemId="metal"; Amount=25};
		{Type="Item"; ItemId="wood"; Amount=5};
	};
	Duration=5;
	
	Workbench = workbenchTypes.BasicWorkbench;
	Branch=treeBranches.Tools;
	Rarity=1;
}

library:Add{
	Id="hammer";
	Category=categories.Tools;
	Recipe={
		{Type="Item"; ItemId="metal"; Amount=50};
	};
	Duration=10;

	Workbench = workbenchTypes.BasicWorkbench;
	Branch=treeBranches.Tools;
	Rarity=1;
}

library:Add{
	Id="workbench";
	Category=categories.Buildings;
	Recipe={
		{Type="Item"; ItemId="wood"; Amount=200};
		{Type="Item"; ItemId="metal"; Amount=200};
	};
	Duration=60;
}

-- library:Add{
-- 	Id="sleepingbag";
-- 	Category=categories.Buildings;
-- 	Recipe={
-- 		{Type="Item"; ItemId="cloth"; Amount=30};
-- 	};

-- }

library:Add{
	Id="woodwindowbarricade";
	Category=categories.Buildings;
	Recipe={
		{Type="Item"; ItemId="wood"; Amount=10};
	};
}

library:Add{
	Id="keylock";
	Category=categories.Buildings;
	Recipe={
		{Type="Item"; ItemId="metal"; Amount=25};
	};
}

library:Add{
	Id="wooddoor";
	Category=categories.Buildings;
	Recipe={
		{Type="Item"; ItemId="wood"; Amount=10};
	};
}

library:Add{
	Id="wooddoubledoors";
	Category=categories.Buildings;
	Recipe={
		{Type="Item"; ItemId="wood"; Amount=20};
	};
}

library:Add{
	Id="woodcrate";
	Category=categories.Buildings;
	Recipe={
		{Type="Item"; ItemId="wood"; Amount=20};
	};
}

library:Add{
	Id="broomspear";
	Category=categories.Weapons;
	Recipe={
		{Type="Item"; ItemId="wood"; Amount=60};
	};
	Duration=10;
}

library:Add{
	Id="medkit";
	Category=categories.Medical;
	Recipe={
		{Type="Item"; ItemId="cloth"; Amount=10};
	};
	Duration=10;
	Amount=3;
}

library:Add{
	Id="buildingplan";
	Category=categories.Tools;
	Recipe={
		{Type="Item"; ItemId="wood"; Amount=10};
	};
	Duration=10;
}

library:Add{
	Id="timedbreachcharge";
	Category=categories.Raiding;
	Recipe={
		{Type="Item"; ItemId="explosives"; Amount=3};
	};
	Duration=10;

	Workbench = workbenchTypes.BasicWorkbench;
	Branch = treeBranches.HardRaid;
	Rarity = 0.01;
}

library:Add{
	Id="largewoodcrate";
	Category=categories.Buildings;
	Recipe={
		{Type="Item"; ItemId="wood"; Amount=100};
	};
	Duration=10;

	Workbench = workbenchTypes.BasicWorkbench;
	Branch = treeBranches.BasicStructure;
	Rarity=1;
}

-- library:Add{
-- 	Id="cupboard";
-- 	Category=categories.Buildings;
-- 	Recipe={
-- 		{Type="Item"; ItemId="wood"; Amount=200};
-- 	};
-- 	Duration=60;

-- 	Workbench = workbenchTypes.BasicWorkbench;
-- 	Branch=treeBranches.TacStructure;
-- 	Rarity=0.5;
-- }

library:Add{
	Id="cellwall";
	Category=categories.Buildings;
	Recipe={
		{Type="Item"; ItemId="metal"; Amount=10};
	};
	Duration=10;

	Workbench = workbenchTypes.BasicWorkbench;
	Branch=treeBranches.RpStructure;
	Rarity=0.5;
}


library:Add{
	Id="ammopouch";
	Category=categories.Clothing;
	Recipe={
		{Type="Item"; ItemId="cloth"; Amount=20};
	};
	Duration=10;
}

library:Add{
	Id="tacticalvest";
	Category=categories.Clothing;
	Recipe={
		{Type="Item"; ItemId="cloth"; Amount=40};
	};
	Duration=10;
	
	Workbench = workbenchTypes.BasicWorkbench;
	Branch=treeBranches.Clothing;
	Rarity=1;
}

library:Add{
	Id="dufflebag";
	Category=categories.Clothing;
	Recipe={
		{Type="Item"; ItemId="cloth"; Amount=80};
	};
	Duration=10;

	Workbench = workbenchTypes.BasicWorkbench;
	Branch=treeBranches.Clothing;
	Rarity=0.5;
}

library:Add{
	Id="survivorsbackpack";
	Category=categories.Clothing;
	Recipe={
		{Type="Item"; ItemId="cloth"; Amount=160};
		{Type="Item"; ItemId="tarp"; Amount=40};
		{Type="Item"; ItemId="rope"; Amount=20};
	};
	Duration=10;

	Workbench = workbenchTypes.BasicWorkbench;
	Branch=treeBranches.Clothing;
	Rarity=0.25;
}

library:Add{
	Id="watch";
	Category=categories.Clothing;
	Recipe={
		{Type="Item"; ItemId="cloth"; Amount=20};
	};
	Duration=5;

	Workbench = workbenchTypes.BasicWorkbench;
	Branch=treeBranches.RpClothing;
	Rarity=1;
}

library:Add{
	Id="cowboyhat";
	Category=categories.Clothing;
	Recipe={
		{Type="Item"; ItemId="cloth"; Amount=35};
	};
	Duration=5;

	Workbench = workbenchTypes.BasicWorkbench;
	Branch=treeBranches.RpClothing;
	Rarity=1;
}


library:Add{
	Id="plankarmor";
	Category=categories.Clothing;
	Recipe={
		{Type="Item"; ItemId="wood"; Amount=100};
		{Type="Item"; ItemId="cloth"; Amount=40};
	};
	Duration=1;

	Workbench = workbenchTypes.BasicWorkbench;
	Branch=treeBranches.ArmorClothing;
	Rarity=0.5;
}


library:Add{
	Id="militaryboots";
	Category=categories.Clothing;
	Recipe={
		{Type="Item"; ItemId="metal"; Amount=100};
		{Type="Item"; ItemId="cloth"; Amount=40};
	};
	Duration=1;

	Workbench = workbenchTypes.BasicWorkbench;
	Branch=treeBranches.ArmorClothing;
	Rarity=0.5;
}


library:Add{
	Id="gasmask";
	Category=categories.Clothing;
	Recipe={
		{Type="Item"; ItemId="cloth"; Amount=65};
		{Type="Item"; ItemId="glass"; Amount=35};
	};
	Duration=20;

	Workbench = workbenchTypes.BasicWorkbench;
	Branch=treeBranches.ProClothing;
	Rarity=0.25;
}

library:Add{
	Id="highvisjacket";
	Category=categories.Clothing;
	Recipe={
		{Type="Item"; ItemId="cloth"; Amount=65};
		{Type="Item"; ItemId="metal"; Amount=25};
	};
	Duration=20;

	Workbench = workbenchTypes.BasicWorkbench;
	Branch=treeBranches.WarmClothing;
	Rarity=0.25;
}

library:Add{
	Id="molotov";
	Category=categories.Weapons;
	Recipe={
		{Type="Item"; ItemId="glass"; Amount=25};
		{Type="Item"; ItemId="jerrycan"; Amount=1};
	};
	Duration=10;

	Workbench = workbenchTypes.BasicWorkbench;
	Branch=treeBranches.Weapons;
	Rarity=0.5;
}


library:Add{
	Id="machete";
	Category=categories.Weapons;
	Recipe={
		{Type="Item"; ItemId="metal"; Amount=80};
	};
	Duration=10;

	Workbench = workbenchTypes.BasicWorkbench;
	Branch=treeBranches.EdgeMelee;
	Rarity=0.5;
}

library:Add{
	Id="spikedbat";
	Category=categories.Weapons;
	Recipe={
		{Type="Item"; ItemId="wood"; Amount=40};
		{Type="Item"; ItemId="metal"; Amount=40};
	};
	Duration=10;

	Workbench = workbenchTypes.BasicWorkbench;
	Branch=treeBranches.BluntMelee;
	Rarity=0.5;
}

library:Add{
	Id="pickaxe";
	Category=categories.Weapons;
	Recipe={
		{Type="Item"; ItemId="wood"; Amount=40};
		{Type="Item"; ItemId="metal"; Amount=40};
	};
	Duration=10;

	Workbench = workbenchTypes.BasicWorkbench;
	Branch=treeBranches.BluntMelee;
	Rarity=0.5;
}

library:Add{
	Id="shovel";
	Category=categories.Weapons;
	Recipe={
		{Type="Item"; ItemId="wood"; Amount=40};
		{Type="Item"; ItemId="metal"; Amount=40};
	};
	Duration=10;

	Workbench = workbenchTypes.BasicWorkbench;
	Branch=treeBranches.EdgeMelee;
	Rarity=0.5;
}


library:Add{
	Id="crowbar";
	Category=categories.Weapons;
	Recipe={
		{Type="Item"; ItemId="metal"; Amount=120};
	};
	Duration=10;

	Workbench = workbenchTypes.BasicWorkbench;
	Branch=treeBranches.Melee;
	Rarity=0.1;
}


library:Add{
	Id="gunpowder";
	Category=categories.Resources;
	Recipe={
		{Type="Item"; ItemId="charcoal"; Amount=4};
		{Type="Item"; ItemId="sulfur"; Amount=4};
	};
	Duration=1;

	Workbench = workbenchTypes.BasicWorkbench;
	Branch=treeBranches.Raiding;
	Rarity=0.5;
}


library:Add{
	Id="lightammo";
	Category=categories.Ammunition;
	Recipe={
		{Type="Item"; ItemId="gunpowder"; Amount=5};
		{Type="Item"; ItemId="metal"; Amount=10};
	};
	Duration=1;
	Amount=5;

	Workbench = workbenchTypes.BasicWorkbench;
	Branch=treeBranches.Ammunition;
	Rarity=0.5;
}

library:Add{
	Id="heavyammo";
	Category=categories.Ammunition;
	Recipe={
		{Type="Item"; ItemId="gunpowder"; Amount=5};
		{Type="Item"; ItemId="metal"; Amount=10};
	};
	Duration=1;
	Amount=5;

	Workbench = workbenchTypes.BasicWorkbench;
	Branch=treeBranches.Ammunition;
	Rarity=0.5;
}

library:Add{
	Id="shotgunammo";
	Category=categories.Ammunition;
	Recipe={
		{Type="Item"; ItemId="gunpowder"; Amount=5};
		{Type="Item"; ItemId="metal"; Amount=10};
	};
	Duration=1;
	Amount=5;

	Workbench = workbenchTypes.BasicWorkbench;
	Branch=treeBranches.Ammunition;
	Rarity=0.5;
}

library:Add{
	Id="sniperammo";
	Category=categories.Ammunition;
	Recipe={
		{Type="Item"; ItemId="gunpowder"; Amount=6};
		{Type="Item"; ItemId="metal"; Amount=10};
	};
	Duration=1;
	Amount=5;

	Workbench = workbenchTypes.BasicWorkbench;
	Branch=treeBranches.Ammunition;
	Rarity=0.4;
}

library:Add{
	Id="p250";
	Category=categories.Weapons;
	Recipe={
		{Type="Item"; ItemId="metal"; Amount=10};
		{Type="Item"; ItemId="steelfragments"; Amount=10};
	};
	Duration=60;

	Workbench = workbenchTypes.BasicWorkbench;
	Branch=treeBranches.Guns;
	Rarity=0.5;
}

library:Add{
	Id="at4";
	Category=categories.Weapons;
	Recipe={
		{Type="Item"; ItemId="metal"; Amount=200};
		{Type="Item"; ItemId="circuitboards"; Amount=4};
	};
	Duration=60;

	Workbench = workbenchTypes.BasicWorkbench;
	Branch=treeBranches.SoftRaid;
	Rarity=0.01;
}

library:Add{
	Id="planter";
	Category=categories.Buildings;
	Recipe={
		{Type="Item"; ItemId="wood"; Amount=100};
		{Type="Item"; ItemId="tarp"; Amount=20};
	};
	Duration = 30;

	Workbench  =  workbenchTypes.BasicWorkbench;
	Branch = treeBranches.TacStructure;
	Rarity = 0.5;
}

library:Add{
	Id = "barbedwooden";
	Category = categories.Buildings;
	Recipe = {
		{Type="Item"; ItemId="wood"; Amount=100};
		{Type="Item"; ItemId="metal"; Amount=20};
	};
	Duration = 30;

	Workbench = workbenchTypes.BasicWorkbench;
	Branch = treeBranches.DefStructure;
	Rarity = 0.5;
}


library.Categories = categories;
library.TreeBranches = treeBranches;
return library;
