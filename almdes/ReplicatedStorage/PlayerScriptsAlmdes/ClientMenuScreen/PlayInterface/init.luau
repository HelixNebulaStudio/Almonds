local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};

local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");
local HttpService = game:GetService("HttpService");

local localplayer = game.Players.LocalPlayer;
local modData = require(localplayer:WaitForChild("DataModule"));

local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modScreenRelativeTextSize = require(game.ReplicatedStorage.Library.UI.ScreenRelativeTextSize);

local remoteMainMenu = modRemotesManager:Get("MainMenuRemote");


local templateMainFrame = script:WaitForChild("Play");
local textTweenInOut = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut);
--== Script;
function Interface.init(modInterfaceBase)
	setmetatable(Interface, modInterfaceBase);
	
	Debugger:Log("Play Init");
	local mainFrame = templateMainFrame:Clone();
	mainFrame.Parent = Interface.ScreenGui;
	
	local titleFrame = mainFrame:WaitForChild("TitleFrame");
	

	local activePlayPage = "OptionsFrame";
	local PlayPages = {
		Options = mainFrame:WaitForChild("OptionsFrame");
		ServerBrowser = mainFrame:WaitForChild("ServerBrowserFrame");
	}
	
	local scrollFramesList = PlayPages.Options:GetChildren();

	local optionsScrollFrame = PlayPages.Options:WaitForChild("OptionsScrollFrame");
	local PlayOptions = {
		Play = optionsScrollFrame:WaitForChild("PlayOptionPlay");
		Servers = optionsScrollFrame:WaitForChild("PlayOptionServers");
		Event = optionsScrollFrame:WaitForChild("PlayOptionEvent");
		Tutorial = optionsScrollFrame:WaitForChild("PlayOptionTutorial");
	}
	
	local templateServerListing = script:WaitForChild("ServerListing");
	local function updateServerBrowser()
		local jsonServersMeta = workspace:GetAttribute("ServersMeta");
		if jsonServersMeta == nil then
			Debugger:Warn("Servers list data unavailable.");
			return;
		end
		
		local serverBrowserScrollFrame = PlayPages.ServerBrowser.ScrollFrame;
		
		local serversMeta = HttpService:JSONDecode(jsonServersMeta);
		local serverTime = modSyncTime.GetTime();
		print("serversMeta", serversMeta);
		
		local updatedJobId = {};
		for a=1, #serversMeta.List do
			local serverInfo = serversMeta.List[a];
			if serverInfo.JobId:sub(1,4) == "test" and not RunService:IsStudio() then continue end;
			if (serverTime - serverInfo.LastUpdated) >= 300 then Debugger:Warn("server JobId(",serverInfo.JobId,") expired.") continue end;
			
			local newListing = serverBrowserScrollFrame:FindFirstChild(serverInfo.JobId);
			if newListing == nil then
				newListing = templateServerListing:Clone();
			end
			newListing.Name = serverInfo.JobId;
			newListing.Parent = serverBrowserScrollFrame;
			
			local titleLabel = newListing:WaitForChild("ServerTitle");
			local playersLabel = newListing:WaitForChild("ServerPlayers");
			local pingLabel = newListing:WaitForChild("ServerPing");
			local descLabel = newListing:WaitForChild("ServerDesc");
			
			local worldName = modBranchConfigs.GetWorldName(serverInfo.PlaceId);
			
			titleLabel.Name = "Official Server #".. serverInfo.JobId;
			playersLabel.Text = #serverInfo.Players .." / ".. serverInfo.MaxPlayers;
			pingLabel.Text = serverInfo.RegionCode;
			descLabel.Text = "Official vanilla almonds server. World: ".. modBranchConfigs.GetWorldDisplayName(worldName); 
			
			updatedJobId[newListing.Name] = true;
		end
		
		for _, obj in pairs(serverBrowserScrollFrame:GetChildren()) do
			if not obj:IsA("TextButton") then continue end;
			if updatedJobId[obj.Name] then continue end;
			
			game.Debris:AddItem(updatedJobId[obj.Name], 0);
		end
		
	end
	workspace:GetAttributeChangedSignal("ServersMeta"):Connect(updateServerBrowser);
	
	local function updatePlayPages()
		for _, pageFrame in pairs(PlayPages) do
			pageFrame.Visible = pageFrame.Name == activePlayPage;
		end
		
		if activePlayPage == "ServerBrowserFrame" then
			titleFrame.ServerBrowserHeader.Visible = true;
			updateServerBrowser();
			
		else
			titleFrame.ServerBrowserHeader.Visible = false;
		end
	end
	
	local window = Interface:NewWindow("Play", mainFrame);
	window.MenuBlur = 50;
	window:SetOpenClosePosition(UDim2.new(0.5, 0, 1, 0), UDim2.new(0.5, 0, 2, 0));
	window.OnToggle:Connect(function(visible)
		if visible then
			Interface:HideAll{[window.Name]=true;};
			Interface.Update();
		end
	end)
	
	
	-- Menu window button;
	local windowButtonPacket = {
		Image="rbxassetid://11191072881";
		LayoutOrder=1;
		Parent=Interface.Dir.MenuNavBar;
		OnClick=function()
			window:Open();
			
			activePlayPage = "OptionsFrame";
			updatePlayPages();
		end;
	};
	Interface:NewWindowButton(window.Name, windowButtonPacket);
	windowButtonPacket.Button:GetAttributeChangedSignal("WindowVisible"):Connect(function()
		local isVisible = windowButtonPacket.Button:GetAttribute("WindowVisible") == true;
		
		local selectedHighlight = windowButtonPacket.Button.SelectedHighlight;
		selectedHighlight.Visible = isVisible;
	end)
	
	
	local selectionName = PlayOptions.Play.Name;
	local selectionHighlight = script:WaitForChild("SelectionHighlight"):Clone();
	
	local function updateSelectionHighlight()
		for key, optionsButton: TextButton in pairs(PlayOptions) do
			local isSelected = optionsButton.Name == selectionName;
			
			local buttonImage: ImageLabel = optionsButton.ImageLabel;
			if isSelected then
				selectionHighlight.Parent = buttonImage;
			end
			
			local descLabel: TextLabel = optionsButton.DescLabel;
			
			if descLabel:GetAttribute("IsSelected") ~= isSelected then
				descLabel:SetAttribute("IsSelected", isSelected);
				
				TweenService:Create(descLabel, textTweenInOut, {
					TextStrokeTransparency = isSelected and 0.75 or 1;
					TextTransparency = isSelected and 0 or 1;
				}):Play();
			end
			
			buttonImage.ImageColor3 = isSelected and Color3.fromRGB(255,255,255) or Color3.fromRGB(225,225,225);
		end
	end
	
	local isMenuWorld = modBranchConfigs.IsWorld("AlmondsMainMenu");
	local isTutorialFinished = modData:GetEvent("tutorialFinished");
	Debugger:Warn("isTutorialFinished", isTutorialFinished);
	
	for key, optionsButton: TextButton in pairs(PlayOptions) do
		optionsButton.MouseEnter:Connect(function()
			selectionName = optionsButton.Name;
			updateSelectionHighlight();
		end)
		optionsButton.MouseMoved:Connect(function()
			selectionName = optionsButton.Name;
			updateSelectionHighlight();
		end)
		
		if key == "Tutorial" then
			optionsButton.Visible = isMenuWorld and isTutorialFinished == nil;
		elseif key == "Play" then
			optionsButton.Visible = not (isMenuWorld and isTutorialFinished == nil);
		end
		optionsButton.MouseButton1Click:Connect(function()
			Interface:PlayButtonClick();
			
			if key == "Tutorial" then
				if remoteMainMenu:Debounce() then return end;

				window:Close();
				Interface.ScreenGui.Enabled = false;
				local replyPacket = remoteMainMenu:InvokeServer("deploy") or {};

				if replyPacket.Success then
					local tween = TweenService:Create(Interface.Dir.MenuMusic, TweenInfo.new(5), {Volume = 0})
					tween:Play();

					task.delay(5, function()
						Interface.Dir.MenuMusic:Stop();
					end)
				end
				
			elseif key == "Servers" then
				activePlayPage = "ServerBrowserFrame";
				updatePlayPages();
				
			elseif key == "Event" then
				
				
			end
		end)
		
		local descLabel: TextLabel = optionsButton:WaitForChild("DescLabel");
		descLabel.TextSize = modScreenRelativeTextSize.GetTextSize();
	end
	
	updateSelectionHighlight();
	updatePlayPages();

	return Interface;
end;

function Interface.Update()

end

--Interface.Garbage is only initialized after .init();
return Interface;
