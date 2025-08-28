local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local camera = workspace.CurrentCamera;
local localPlayer = game.Players.LocalPlayer;

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modTables = shared.require(game.ReplicatedStorage.Library.Util.Tables);

local modStorageInterface = shared.require(game.ReplicatedStorage.Library.UI.StorageInterface);

local interfacePackage = {
    Type = "Character";
};
--==


function interfacePackage.newInstance(interface: InterfaceInstance)
    local modData = shared.require(localPlayer:WaitForChild("DataModule"));

    local templateSlot = interface.newTemplate("ItemSlot");

    local charWindow = interface:GetWindow("CharacterWindow");
    local rPanel = charWindow.Binds.RPanel;

    local storageFrame = script:WaitForChild("ExternalStorage"):Clone();
    storageFrame.Parent = rPanel;

    local storageTitleLabel = storageFrame:WaitForChild("Title");
    local storageSlots = storageFrame:WaitForChild("Slots");

    local window: InterfaceWindow = interface:NewWindow("ExternalStorage", storageFrame);
    window.IgnoreHideAll = true;
    window.UseTween = false;
    window.DisableInteractables = true;
    window.CloseWithInteract = true;

    local binds = window.Binds;
    binds.StorageId = nil;
    binds.Interactable = nil;

    local activeStorageId = nil;
    local activeStorageInterface = nil;
    
    --MARK: OnToggle
    window.OnToggle:Connect(function(visible, storageId, packet)
        if visible then
            binds.Interactable = packet.Interactable;
            binds.StorageId = storageId;

            interface:ToggleWindow("Inventory", true);
            storageFrame.Visible = true;
            window:Update(true);

            local interactPart = binds.Interactable and binds.Interactable.Part;
            if interactPart then
                task.spawn(function()
                    while window.Visible do
                        task.wait(0.2);
                        if not workspace:IsAncestorOf(interactPart) then
                            break;
                        end
                        if localPlayer:DistanceFromCharacter(interactPart.Position) > 20 then
                            break;
                        end
                    end
                    window:Close();
                end)
            end

        else
			task.spawn(function()
                modData.RequestStorage{
                    Action = "CloseStorage";
                    StorageId = binds.StorageId;
                };
			end)

            modStorageInterface.SetQuickTarget();
            storageFrame.Visible = false;
        end
    end)

    --MARK: OnUpdate
	window.OnUpdate:Connect(function(forceReload)
        local storageId = binds.StorageId;
        if forceReload ~= true and activeStorageId == storageId and activeStorageInterface then
            modStorageInterface.SetQuickTarget(activeStorageInterface);
            activeStorageInterface:Update();
            Debugger:Warn(`Refresh storage: {activeStorageId}/{storageId}`);
            return;
        end

        activeStorageId = storageId;
        local storage = modData.GetStorage(activeStorageId);

		Debugger:Log("Opening storage:",activeStorageId,"(",storage and storage.Name or nil,")");
		
		local storageName = storage.Name or activeStorageId or "nil";
		storageTitleLabel.Text = storageName;

		if activeStorageInterface then
            activeStorageInterface:Destroy();
        end;
		for _, c in pairs(storageSlots:GetChildren()) do
            if c:IsA("GuiObject") then 
                c:Destroy();
            end;
        end;

		local slotFrames = {};
		local yieldTick = tick(); 
        repeat until storage.Size or tick()-yieldTick >1 or not wait(1/60);

        if storage.Size == nil then
            Debugger:Warn(`Failed to load external storage: {activeStorageId}`);
            window:Close();
            return;
        end

        for a=1, (storage.MaxSize or storage.Size) do
            local slot = templateSlot:Clone();
            slot:SetAttribute("Index", a);
            slot.LayoutOrder = a;
            slot.Parent = storageSlots;
            table.insert(slotFrames, slot);
        end

        activeStorageInterface = modStorageInterface.new(activeStorageId, storageFrame, slotFrames);
        activeStorageInterface:Update();
        modStorageInterface.SetQuickTarget(activeStorageInterface);
    end)

end

return interfacePackage;

