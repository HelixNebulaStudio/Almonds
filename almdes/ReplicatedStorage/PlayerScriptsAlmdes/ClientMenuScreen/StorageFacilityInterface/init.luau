local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};

local localplayer = game.Players.LocalPlayer;
local modData = require(localplayer:WaitForChild("DataModule"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local remotes = game.ReplicatedStorage.Remotes;


local templateMainFrame = script:WaitForChild("Storages");

--== Script;
function Interface.init(modInterfaceBase)
	setmetatable(Interface, modInterfaceBase);
	
	Debugger:Log("StorageFac Init");
	local mainFrame = templateMainFrame:Clone();
	mainFrame.Parent = Interface.ScreenGui;
	
	local window = Interface:NewWindow("Storages", mainFrame);
	window.MenuBlur = 50;
	window:SetOpenClosePosition(UDim2.new(0.5, 0, 0, 0), UDim2.new(0.5, 0, -1.5, 0));
	window.OnToggle:Connect(function(visible)
		if visible then
			Interface:HideAll{[window.Name]=true;};
			Interface.Update();
		end
	end)
	
	--Interface:NewWindowButton(window.Name, {
	--	Image="rbxassetid://11191077792";
	--	LayoutOrder=2;
	--	Parent=Interface.Dir.MenuNavBar;
	--	OnClick=function()
	--		window:Open();
	--	end;
	--});
	
	--Interface.Garbage:Tag();

	return Interface;
end;

function Interface.Update()

end

--Interface.Garbage is only initialized after .init();
return Interface;
