local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
--==


--==
local function new(b, d) b.__index=b; modItemsLibrary:Add(setmetatable(d, b)); end;

function modItemsLibrary.onRequire()
	--==========================================================[[ RESOURCE ]]==========================================================--
	local resourceBase = {
		Type = modItemsLibrary.Types.Resource;
		Tradable = modItemsLibrary.Tradable.Nontradable;
		Stackable = 200;
	};

	new(resourceBase, {Id="metal"; Name="Metal Scraps"; Icon="rbxassetid://1551792125"; Description="Metallic scraps used in crafting metal objects.";});
	new(resourceBase, {Id="glass"; Name="Glass Shards"; Icon="rbxassetid://1551792117"; Description="Glass shards and pieces used in crafting glass objects.";});
	new(resourceBase, {Id="wood"; Name="Wooden Parts"; Icon="rbxassetid://1551280660"; Description="Wooden parts used in crafting wooden objects.";});
	new(resourceBase, {Id="cloth"; Name="Cloth"; Icon="rbxassetid://3580309486"; Description="Cloth used in crafting clothing or medical supplies.";});

	new(resourceBase, {Id="charcoal"; Name="Charcoal"; Icon="rbxassetid://6117038530"; Description="Charred or non-charred coal, a byproduct of burning wood in the furnace.";});
	new(resourceBase, {Id="steelfragments"; Name="Steel Fragments"; Icon="rbxassetid://8815170269"; Description="Steel Fragments used in crafting high quality items.";});

	new(resourceBase, {Id="gunpowder"; Name="Gun Powder"; Icon="rbxassetid://12122129617"; Description="Used in crafting ammunition.";});
	new(resourceBase, {Id="sulfur"; Name="Sulfur"; Icon="rbxassetid://12122140942"; Description="Used in crafting gun powder and explosives.";});
	
	new(resourceBase, {Id="jerrycan"; Name="Jerrycan"; Icon="rbxassetid://5886813198"; Stackable=false; BaseValues={Fuel=25}; Description="Steel-pressed container that holds highly flammable fuel. Ignited fuel will deal 1% of max health as damage (Min: 10).";});
	
	new(resourceBase, {Id="tarp"; Name="Tarp"; Icon="rbxassetid://12369050152"; Description="Useful resource to contain elements of liquid.";});
	new(resourceBase, {Id="rope"; Name="Rope"; Icon="rbxassetid://13265271329"; Description="Useful for tying things together.";});
	
	--=========================================================[[ AMMO ]]==========================================================--
	local ammoBase = {
		Type = modItemsLibrary.Types.Ammo;
		Tradable = modItemsLibrary.Tradable.Tradable;
		SyncOnAdd = true;
	}
	new(ammoBase, {Id="lightammo"; Name="Light Ammo"; Icon="rbxassetid://7242498697"; Stackable=64; Description="Ammunition for pistols, smgs and light weapons.";});
	new(ammoBase, {Id="heavyammo"; Name="Heavy Ammo"; Icon="rbxassetid://7242509621"; Stackable=64; Description="Ammunition for rifles, lmgs and heavy weapons.";});
	new(ammoBase, {Id="shotgunammo"; Name="Shotgun Ammo"; Icon="rbxassetid://7242511854"; Stackable=32; Description="Ammunition for shotguns.";});
	new(ammoBase, {Id="sniperammo"; Name="Sniper Ammo"; Icon="rbxassetid://7242517756"; Stackable=16; Description="Ammunition for sniper rifles.";});

	--==========================================================[[ WEAPONS ]]==========================================================--
	local gunBase = {
		Type = modItemsLibrary.Types.Tool;
		Tradable = modItemsLibrary.Tradable.PremiumOnly;
		Tags = {"Gun"};
	}
	
	new(gunBase, {Id="p250"; Name="P250"; Icon="rbxassetid://5174775682"; Tags={"Pistol"}; Description="A handy pistol.";});
	new(gunBase, {Id="cz75"; Name="CZ75-Auto"; Icon="rbxassetid://5166288452"; Tags={"Pistol"}; Description="High fire-rate automatic pistol. Has built in damage rev, which does more damage the lower your ammo count is in your magazine.";});
	new(gunBase, {Id="tec9"; Name="Tec-9"; Icon="rbxassetid://5166289439"; Tags={"Pistol"}; Description="High power, high firerate automatic pistol.";});
	new(gunBase, {Id="deagle"; Name="Desert Eagle"; Icon="rbxassetid://5166288732"; Tags={"Pistol"}; Description="The hand cannon.";});
	
	new(gunBase, {Id="mp5"; Name="MP5"; Icon="rbxassetid://9960159062"; Tags={"Submachine gun"}; Description="Quick fire-rate sub-machine gun.";});
	new(gunBase, {Id="mp7"; Name="MP7"; Icon="rbxassetid://9960161355"; Tags={"Submachine gun"}; Description="Good accuracy and damage sub-machine gun.";});

	new(gunBase, {Id="m4a4"; Name="M4A4"; Icon="rbxassetid://5166150878"; Tags={"Rifle"}; Description="Military grade M4 rifle capable of high damage and long range shooting.";});
	new(gunBase, {Id="ak47"; Name="AK-47"; Icon="rbxassetid://5166397129"; Tags={"Rifle"}; Description="High damage, high magazine capacity, and great fire-rate. Quite a noise maker.";});
	
	new(gunBase, {Id="grandgarand"; Name="Grand Garand"; Icon="rbxassetid://118201286435452"; Tags={"Sniper"}; Description="High Damage, High Recoil and Long ranged rifle.";});
	
	new(gunBase, {Id="rusty48"; Name="Rusty 48"; Icon="rbxassetid://10390716871"; Tags={"Shotgun"}; Description="Powerful hand made shotgun.";});

	new(gunBase, {Id="at4"; Name="AT4 Rocket Launcher"; Icon="rbxassetid://6436980949"; Tags={"Explosive"; "Launcher"}; Description="Perfectly designed to annihilate structures and defenses.";});
	

	local meleeBase = {
		Type = modItemsLibrary.Types.Tool;
		Tradable = modItemsLibrary.Tradable.PremiumOnly;
		Tags = {"Melee"};
	}
	
	new(meleeBase, {Id="broomspear"; Name="Broom Spear"; Icon="rbxassetid://5120882769"; Tags={"Pointed Melee"; "Throwable"}; Description="Chipped out from a broom stick. Does 50 damage melee, 35 damage on thrown.";});
	
	new(meleeBase, {Id="machete"; Name="Machete"; Icon="rbxassetid://4469866502"; Tags={"Edged Melee"}; Description="A heavy duty zombie killer, can't get far without it.";});
	new(meleeBase, {Id="spikedbat"; Name="Spiked Bat"; Icon="rbxassetid://4600968105"; Tags={"Blunt Melee"}; Description="Time to hit some home runs on these zombies.";});
	new(meleeBase, {Id="crowbar"; Name="Crowbar"; Icon="rbxassetid://4843541333"; Tags={"Blunt Melee"}; Description="A handy tool to break free.";});
	new(meleeBase, {Id="pickaxe"; Name="Pickaxe"; Icon="rbxassetid://5175332073"; Tags={"Pointed Melee"; "Throwable";}; Description="A construction grade pickaxe capable of mining metal piles.";});
	new(meleeBase, {Id="shovel"; Name="Shovel"; Icon="rbxassetid://8814526891"; Tags={"Blunt Melee"}; Description="A gardener's trusty shovel. Good for digging dirt piles.";});

	--==========================================================[[ Throwables ]]==========================================================--
	local throwableBase = {
		Type = modItemsLibrary.Types.Tool;
		Tradable = modItemsLibrary.Tradable.Tradable;
		Tags = {"Throwable"};
		Stackable = 10;
	}
	
	new(throwableBase, {Id="molotov"; Name="Molotov"; Icon="rbxassetid://5088295501"; Tags={"Incendiary"}; Description="Ignites surrounding area on fire on impact, does 10 every 0.5 seconds.";});

	new(throwableBase, {Id="mk2grenade"; Name="Mk2 Grenade"; Icon="rbxassetid://5018436895"; Tags={"Explosive"}; Description="Throwable explosive thingy. Does 70 damage to surrounding enemies.";});
	new(throwableBase, {Id="stickygrenade"; Name="Sticky Grenade"; Icon="rbxassetid://5106343976"; Tags={"Explosive"}; Description="Sticks to surfaces thrown on. Does 70 damage to surrounding enemies.";});
	new(throwableBase, {Id="explosives"; Name="Explosives"; Icon="rbxassetid://7304930076"; Tags={"Explosive"}; Description="Does 40 damage on impact to surrounding enemies.";});
	
	new(throwableBase, {Id="timedbreachcharge"; Name="Timed Breach Charge"; Icon="rbxassetid://11424066625"; Tags={"Explosive"}; Description="Used to breach through doors and walls, does 250 structural damage to the structure it lands on.";});

	--==========================================================[[ CLOTHING ]]==========================================================--
	local clothingBase = {
		Type = modItemsLibrary.Types.Clothing;
		Tradable = modItemsLibrary.Tradable.Tradable;
		Tags = {};
	}
	
	new(clothingBase, {Id="plankarmor"; Name="Plank Armor"; Icon="rbxassetid://5765969051"; Tags={"Chest"}; Description="Makeshift wooden plank armor.";});
	new(clothingBase, {Id="militaryboots"; Name="Military Boots"; Icon="rbxassetid://5806715194"; Tags={"Shoes"}; Description="Military grade boots.";});
	new(clothingBase, {Id="watch"; Name="Watch"; Icon="rbxassetid://6306934431"; Tags={}; Description="Tick-tock-tick-tock. Tells the time.";});
	new(clothingBase, {Id="cowboyhat"; Name="Cowboy Hat"; Icon="rbxassetid://4994923375"; Tags={"Head"}; Description="I will be the one yeeee-haw-ing around here.";});
	new(clothingBase, {Id="highvisjacket"; Name="High Visibility Jacket"; Icon="rbxassetid://8488333823"; Tags={"Chest"}; Description="The high visibility jacket provides warmth and some protection.";});
	new(clothingBase, {Id="gasmask"; Name="Gas Mas"; Icon="rbxassetid://6971981402"; Tags={"Head"}; Description="Hudda hudda huuh! Protects you in hazardous environments.";});


	local storageBase = {
		Type = modItemsLibrary.Types.Clothing;
		Tradable = modItemsLibrary.Tradable.Tradable;
		Tags = {"Storage"};
		--Usable="Open";
		OnAdd = function(data)
			-- local usableItemLib = modUsableItems:Find(data.Id);
			-- if usableItemLib.PortableStorage then
			-- 	data.PortableStorage = true;
			-- 	data.Description = "Portable storage for additional "..usableItemLib.PortableStorage.Size.." slots. Equip it in clothing to access storage. This item cannot be stored in another storage.";
			-- end
		end;
		StorageWhitelist={
			["Inventory"]=true;
			["Clothing"]=true;
		};
	};
	
	new(storageBase, {Id="survivorsbackpack"; Name="Survivor's Backpack"; Description="Equip it in clothing to access an additional 12 slots."; Icon="rbxassetid://8948320931"; SlotColor=Color3.fromRGB(75, 50, 50);});
	new(storageBase, {Id="dufflebag"; Name="Duffle Bag"; Description="Equip it in clothing to access an additional 6 slots."; Icon="rbxassetid://8827967921"; SlotColor=Color3.fromRGB(75, 75, 50);});
	new(storageBase, {Id="ammopouch"; Name="Ammo Pouch"; Description="Equip it in clothing to access an additional 3 slots."; Icon="rbxassetid://7335420098"; SlotColor=Color3.fromRGB(50, 75, 50);});
	new(storageBase, {Id="tacticalvest"; Name="Tactical Vest"; Description="Equip it in clothing to access an additional 3 slots."; Icon="rbxassetid://12060781576"; SlotColor=Color3.fromRGB(50, 75, 75);});

	--==========================================================[[ CRATES ]]==========================================================--
	local crateBase = {
		Type = modItemsLibrary.Types.Structure;
		Tradable = modItemsLibrary.Tradable.Tradable;
		TradingTax = 10;
		Stackable = 10;
		Description = "Open it to see what you got from the crate.";
		Tags = {"Crate"};
		OnAdd = function(data)
			local gameModeData = data.GameMode;
			if gameModeData then
				data.Name = (gameModeData.HardPrefix and gameModeData.HardPrefix.." " or "")..gameModeData.Stage.." Reward Crate";
				data.Description = gameModeData.HardPrefix and "Obtained from boss waves above wave 20 with a 50% drop chance. " or "";
				data.Description = data.Description.."Open it to see what you got from "..gameModeData.Mode..": "..gameModeData.Stage.."."
			end
		end;
	};
	
	
	--=========================================================[[ COMPONENTS ]]==========================================================--
	local componentsBase = {
		Type = modItemsLibrary.Types.Component;
		Tradable = modItemsLibrary.Tradable.PremiumOnly;
		Stackable = 10;
	};
	
	new(componentsBase, {Id="battery"; Name="Battery"; Icon="rbxassetid://3592076927"; Description="Crafting component for storing electricity.";});
	new(componentsBase, {Id="circuitboards"; Name="Circuit Boards"; Icon="rbxassetid://4327228467"; Description="Crafting component for making electronic devices.";});
	new(componentsBase, {Id="gastank"; Name="Gas Tank"; Icon="rbxassetid://3238394723"; Description="Crafting component for storing liquid or gas.";});
	new(componentsBase, {Id="metalpipes"; Name="Metal Pipes"; Icon="rbxassetid://3238326135"; Description="Crafting component for transfering liquid or gas.";});
	
	
	--=========================================================[[ COMMODITY ]]==========================================================--
	local commodityBase = {
		Type = modItemsLibrary.Types.Commodity;
		Tradable = modItemsLibrary.Tradable.Tradable;
		Stackable = 10;
	};
	
	
	--=========================================================[[ STRUCTURE ]]==========================================================--
	local structureBase = {
		Type = modItemsLibrary.Types.Structure;
		Tradable = modItemsLibrary.Tradable.Tradable;
	};
	
	new(structureBase, {Id="campfire"; Name="Campfire"; Icon="rbxassetid://6734447412"; Description="Placeable campfire.";});
	new(structureBase, {Id="woodcrate"; Name="Wooden Crate"; Icon="rbxassetid://12325880326"; Description="Placeable wooden container with 6 slots.";});
	new(structureBase, {Id="largewoodcrate"; Name="Large Wooden Crate"; Icon="rbxassetid://12325879233"; Description="Placeable wooden container with 18 slots.";});
	new(structureBase, {Id="sleepingbag"; Name="Sleeping Bag"; Icon="rbxassetid://6979796635"; Description="Sleeping bag. Creates a respawn point.";});

	new(structureBase, {Id="woodwindowbarricade"; Name="Wooden Window Barricade"; Icon="rbxassetid://6387328672"; Stackable=4; Description="Used for barricading windows.";});
	new(structureBase, {Id="wooddoubledoors"; Name="Wooden Double Doors"; Icon="rbxassetid://6438344617"; Description="Used for barricading doorways.";});
	new(structureBase, {Id="wooddoor"; Name="Wooden Door"; Icon="rbxassetid://6444920805"; Description="Used for barricading a doorway.";});
	
	new(structureBase, {Id="cupboard"; Name="Management Cupboard"; Icon="rbxassetid://11436871213"; Description="Used for maintaining your structures and protecting your territory.";});
	
	new(structureBase, {Id="cellwall"; Name="Cell Wall"; Icon="rbxassetid://11450927716"; Description="Cell walls used to build a jail cell.";});

	new(structureBase, {Id="workbench"; Name="Workbench"; Icon="rbxassetid://12122151861"; Description="Used for unlocking new crafting recipes and craft higher tier items.";});
	new(structureBase, {Id="planter"; Name="Planter"; Icon="rbxassetid://12335379052"; Description="Used for growing basic crops.";});
	
	new(structureBase, {Id="barbedwooden"; Name="Barbed Wooden Fence"; Icon="rbxassetid://5803776520"; Description="Placable barbed wooden fence that does 1% damage per second when touched.";});
	
	new(structureBase, {Id="furnace"; Name="Furnace"; Icon="rbxassetid://16124582573"; Description="Used for cooking and refining different resources.";});

	
	--==========================================================[[ Medical ]]==========================================================--
	local medicalBase = {
		Type = modItemsLibrary.Types.Tool;
		Tradable = modItemsLibrary.Tradable.Tradable;
		Stackable = 3;
	};

	new(medicalBase, {Id="medkit"; Name="Medkit"; Icon="rbxassetid://492009851"; Stackable=5; Description="Heals you for 20 health and stops bleeding.";});
	new(medicalBase, {Id="largemedkit"; Name="Large Medkit"; Icon="rbxassetid://508762791"; Description="Heals you for 40 health and stops bleeding.";});
	new(medicalBase, {Id="advmedkit"; Name="Advance Medkit"; Icon="rbxassetid://5008764919"; Description="Heals you for 80 health and stops bleeding.";});
	
	
	--==========================================================[[ Tools ]]==========================================================--
	local toolBase = {
		Type = modItemsLibrary.Types.Tool;
		Tradable = modItemsLibrary.Tradable.Tradable;
	}
	
	new(toolBase, {Id="buildingplan"; Name="Building Plan"; Icon="rbxassetid://8894342011"; Description="Used to build wall plans on foundations. When on top of a foundation, left click to place/unplace wall plans.";});
	new(toolBase, {Id="hammer"; Name="Hammer"; Icon="rbxassetid://11497379398"; Description="Used to inspect, modify and upgrade.";});
	
	new(toolBase, {Id="torch"; Name="Torch"; Icon="rbxassetid://12278042615"; Description="It is used to light up the dark.";});
	new(toolBase, {Id="lantern"; Name="Lantern"; Icon="rbxassetid://3681206568"; Description="It is used to light up the dark.";});
	
	new(toolBase, {Id="fotlcardgame"; Name="Fall of the Living: Card Game"; Icon="rbxassetid://10862651147"; Description="Card game called Fall of the Living.. Play safe by not bluffing or take risks and bluff to gain an advantage.\n\n<b>Actions:</b>\nScavenging might yield 0-2 resources.\nAttacking with 10 resources is unblockable. \n\n<b>Card:</b>\n<font color='#8c5252'>Rouge</font>: Attack using 4 resources\n<font color='#78476f'>Rat</font>: Scavenge 3 resources\n<font color='#634335'>Bear</font>: Raid others for 2 resources\n<font color='#31564c'>Rabbit</font>: Pick 2 random card and switch cards\n<font color='#52622a'>Zombie</font>: Blocks rouge attacks.\n\nPlayers starts with 2 cards, if they have a card, they can perform the card's action legitimately. If they don't have the card, they can bluff their actions.";});
	
	new(toolBase, {Id="cabbageseeds"; Name="Cabbage Seeds"; Icon="rbxassetid://12336988868"; BaseValues={Cap=4; MaxCap=4;}; Description="It is used to plant cabbages.";});
	new(toolBase, {Id="keylock"; Name="Key Lock"; Icon="rbxassetid://12650377361"; Description="Attachable lock for doors.";});

	new(toolBase, {Id="lockkey"; Name="Lock Key"; Icon="rbxassetid://13149516635"; Description="A key used for a specific lock.";});

	new(toolBase, {Id="t1key"; Name="Tier 1 Key"; Icon="rbxassetid://1537254647"; Description="Used for unlocking Tier 1 Crate dropped from small bandit camps.";});
	new(toolBase, {Id="matchbox"; Name="Matchbox"; Icon="rbxassetid://6269033605"; Stackable=10; Description="Can be deconstructed to get Sulfur.";});

	--==========================================================[[ FOOD ]]==========================================================--
	local foodBase = {
		Type = modItemsLibrary.Types.Food;
		Tradable = modItemsLibrary.Tradable.Tradable;
		Stackable = 4;
	}
	
	new(foodBase, {Id="cannedbeans"; Name="Canned Beans"; Icon="rbxassetid://4466508636"; Description="A can of beans.";});
	new(foodBase, {Id="cannedfish"; Name="Canned Sardines"; Icon="rbxassetid://6961233944"; Description="A can of sardines.";});
	new(foodBase, {Id="bloxycola"; Name="Bloxy Cola"; Icon="rbxassetid://5094119246"; Description="Bloxy Cola?! Yippee.";});
	new(foodBase, {Id="chocobar"; Name="Chocolate Bar"; Icon="rbxassetid://5795159539"; Description="Edible happiess.";});
	new(foodBase, {Id="annihilationsoda"; Name="Annihilation Soda"; Icon="rbxassetid://10368377851"; Description="Annihilation's special edition soda.";});
	new(foodBase, {Id="cabbage"; Name="Cabbage"; Icon="rbxassetid://12335313494"; Description="Fresh home-grown cabbage.";});
	new(foodBase, {Id="cupcake"; Name="Cupcake"; Icon="rbxassetid://12806349482"; Description="One of those highly preserved convenience store cupcakes.. Food is food.";});



end

return modItemsLibrary;