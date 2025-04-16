local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};

local localplayer = game.Players.LocalPlayer;
local modData = require(localplayer:WaitForChild("DataModule"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modMarkupFormatter = require(game.ReplicatedStorage.Library.MarkupFormatter);

local remoteMainMenu = modRemotesManager:Get("MainMenuRemote");
local remoteApiRequest = modRemotesManager:Get("ApiRequest");

local templateMainFrame = script:WaitForChild("Menu");
local templateUpdatesWindow = script:WaitForChild("UpdatesWindow");
local templateLogoButton = script:WaitForChild("LogoButton");

--== Script;
function Interface.init(modInterfaceBase)
	setmetatable(Interface, modInterfaceBase);
	
	Debugger:Log("Menu Init");

	local mainFrame = templateMainFrame:Clone();
	mainFrame.Parent = Interface.ScreenGui;

	local updateLogFrame: TextButton = mainFrame:WaitForChild("UpdateLogFrame");
	local updateContent = updateLogFrame:WaitForChild("Content");
	local updateLogLabel = updateContent:WaitForChild("notes"):WaitForChild("textLabel");

	local window = Interface:NewWindow("Menu", mainFrame);
	window.ToggleTweenAnimation = false;
	
	window.OnToggle:Connect(function(visible)
		if visible then
			Interface:HideAll{[window.Name]=true;};
		end
	end)
	
	local logoButton = templateLogoButton:Clone();
	logoButton.Parent = Interface.Dir.MenuNavBar;
	Interface:NewWindowButton("Menu", {
		Image="rbxassetid://11191206072";
		LayoutOrder=0;
		OnClick=function()
			window:Open();
		end;
		Button=logoButton;
	});

	window:Open();
	
	function Interface:RefreshUpdateLog()
		task.spawn(function()
			local blogTable = remoteApiRequest:InvokeServer("updatelog") or {};

			local success, message = false, "";
			if blogTable.name ~= nil then
				success, message = pcall(function()
					updateLogLabel.Text = modMarkupFormatter.Format(blogTable.desc);
				end)
			end
		end)
	end
	
	Interface:RefreshUpdateLog();
	
	
	--== Update blogs window;
	local updatesFrame = templateUpdatesWindow:Clone();
	updatesFrame.Parent = Interface.ScreenGui;
	
	local updatesFrameLabel = updatesFrame:WaitForChild("ContentFrame"):WaitForChild("ScrollFrame"):WaitForChild("textLabel");
	
	local updatesWindow = Interface:NewWindow("Updates", updatesFrame);
	updatesWindow.MenuBlur = 50;
	updatesWindow:SetOpenClosePosition(UDim2.new(0.5, 0, 1, 0), UDim2.new(0.5, 0, 2, 0));
	updatesWindow.OnToggle:Connect(function(visible)
		if visible then
			Interface:HideAll{[updatesWindow.Name]=true;};
			Interface:RefreshUpdateLog();
			
			updatesFrameLabel.Text = updateLogLabel.Text;
		end
	end)
	
	updateLogFrame.MouseButton1Click:Connect(function()
		Interface:PlayButtonClick();
		updatesWindow:Open();
	end)
	
	
	return Interface;
end;

--Interface.Garbage is only initialized after .init();
return Interface;
