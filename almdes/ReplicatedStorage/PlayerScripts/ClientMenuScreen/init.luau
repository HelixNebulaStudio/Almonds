local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local localPlayer = game.Players.LocalPlayer;

local CollectionService = game:GetService("CollectionService");
local SoundService = game:GetService("SoundService");

local modGlobalVars = shared.require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modInterfaceBase = shared.require(game.ReplicatedStorage.Library.InterfaceBase);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local modUIElements = shared.require(game.ReplicatedStorage.Library.UI.UIElements);

local rootInterface, modData, neonLogo;
local menuInterface;

local ClientMenuScreen = {};
ClientMenuScreen.__index = ClientMenuScreen;
--==

function ClientMenuScreen.onRequire()
	rootInterface = game.ReplicatedStorage.PlayerGui.RootInterface;
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);

	local remoteMainMenu = modRemotesManager:Get("MainMenuRemote");
	neonLogo = game.ReplicatedStorage.Prefabs.Misc:WaitForChild("neonSign");

	menuInterface = modInterfaceBase.new();
	menuInterface.ScreenGui = rootInterface;

	menuInterface.Dir.MenuMusic = rootInterface:WaitForChild("MenuMusic");
	menuInterface.Dir.MenuButton = script:WaitForChild("MenuButton");
	menuInterface.Dir.MenuNavBar = rootInterface:WaitForChild("TopBar"):WaitForChild("Content");

	function menuInterface:PlayButtonClick(pitch)
		modAudio.Play("ButtonClick", nil, nil, false).PlaybackSpeed = pitch or 2;
	end

	menuInterface.OnWindowToggle:Connect(function()
		local currentScreen = nil;
		
		for name, window in pairs(menuInterface.Windows) do
			if window.Visible == true then
				currentScreen = name;
				break;
			end
		end
		
		local menuEqualizer: EqualizerSoundEffect =	menuInterface.Dir.MenuMusic.EqualizerSoundEffect;
		menuEqualizer.Enabled = currentScreen == "Menu";
		
	end)


	function remoteMainMenu.OnClientInvoke(action, paramPacket)
		local replyPacket = {};

		if action == "extraction" then
			--camera.CameraType = Enum.CameraType.Scriptable;
			--camera.CFrame = CFrame.new(Vector3.new(0, 1024, 0)) * CFrame.Angles(math.rad(-90), 0, math.rad(180));
			--camera.Focus = CFrame.new();
			game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false);

			ClientMenuScreen:Load();
		end
		return replyPacket;
	end

	rootInterface.Parent = localPlayer:WaitForChild("PlayerGui");
	
	ClientMenuScreen:Load();
	
	menuInterface:Load(script);
end

-- MenuInterface;

--== Script;
function ClientMenuScreen:Load()
	Debugger:Log("GameMenu:Load");
    local modInterface = modData:GetInterfaceModule();

	local versionLabel = rootInterface:WaitForChild("TopBar"):WaitForChild("VersionLabel");
	versionLabel.Text = string.gsub(modGlobalVars.ModeVerLabel, "$UpTime", "");
	
	game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false);
	
	shared.ClientLighting:SetAtmosphere("Menu");
	
	modData.CameraHandler:Bind("menucamera", {
		RenderStepped=function(camera, delta, totalDelta)
			camera.Focus = CFrame.new();
			camera.CFrame = CFrame.new(Vector3.new(0, 1024, 0)) * CFrame.Angles(math.rad(-90), 0, math.rad(180));
			
			neonLogo.Parent = camera;
			neonLogo:WaitForChild("base");
			neonLogo:PivotTo( (camera.CFrame + camera.CFrame.LookVector * 10) * CFrame.Angles(math.sin(totalDelta/8)/5, math.rad(180), -math.sin(totalDelta/8)/10));
		end;
	}, 2);

	modInterface:ToggleGameBlinds(true, 1);
	
	--local spawnPrefabs = CollectionService:GetTagged(localPlayer.UserId..":SpawnPoints");
	
	--if GameMenu.deployUIElements == nil then GameMenu.deployUIElements = {}; end
	
	--for a=1, #spawnPrefabs do
	--	local prefab = spawnPrefabs[a];
		
	--	if prefab:GetAttribute("uiElementId") == nil then
	--		local radialElement = modUIElements.newRadialButton();
	--		prefab:SetAttribute("uiElementId", radialElement.Id);
			
	--		radialElement.ImageButton.Parent = deployFrame;
	--		radialElement.Prefab = prefab;
			
	--		table.insert(GameMenu.deployUIElements, radialElement);
	--	end
	--end
	
	--for a=#GameMenu.deployUIElements, 1, -1 do
	--	local element = GameMenu.deployUIElements[a];
		
	--	if element.Prefab == nil or not element.Prefab:IsDescendantOf(workspace) then
	--		table.remove(GameMenu.deployUIElements, a);
	--		element.Prefab = nil;
	--		element:Destroy();
			
	--	else
	--		local prefab = element.Prefab;
	--		local prefabCf = prefab:GetPrimaryPartCFrame();
			
	--		local eventIconLabel = element.ImageButton:WaitForChild("icon");
	--		local titleLabel = element.ImageButton:WaitForChild("title");
	--		local radialBar = element.ImageButton:WaitForChild("radialBar");
	--		radialBar.Visible = false;
			
	--		local itemLib = modItemsLibrary:Find(prefab.Name);
	--		eventIconLabel.Image = itemLib.Icon;
			
	--		local pos, onScreen = camera:WorldToViewportPoint(prefabCf.p);
	--		element.ImageButton.Position = UDim2.new(0, pos.X, 0, pos.Y);
	--	end
	--end
	
	--neonLogo.Parent = #GameMenu.deployUIElements > 0 and script or camera;
	
end

function ClientMenuScreen:OnCharacterAdded(character)
	Debugger:Log("Player spawned");
	modData.CameraHandler:Unbind("menucamera");

end

function ClientMenuScreen:OnCharacterDied(character)
	task.wait(6);
	
	ClientMenuScreen:Load();
	
	menuInterface.ScreenGui.Enabled = true;
	
	menuInterface.Dir.MenuMusic.Volume = 0.5;
	menuInterface.Dir.MenuMusic:Play();
	
	menuInterface.Windows.Menu:Open();
end

return ClientMenuScreen;