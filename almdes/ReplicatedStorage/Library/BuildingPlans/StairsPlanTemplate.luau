local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);
local modMath = shared.require(game.ReplicatedStorage.Library.Util.Math);
local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);
local modBuildingPlans;

local BLUE_COLOR = Color3.fromRGB(124, 161, 200);
local RED_COLOR = Color3.fromRGB(200, 124, 124);

local StairsPlanTemplate = {};
StairsPlanTemplate.__index = StairsPlanTemplate;
StairsPlanTemplate.ClassName = "StairPlan";

--==

function StairsPlanTemplate.onRequire(BuildingPlans)
	modBuildingPlans = BuildingPlans;

	templateGenericBillboard = game.ReplicatedStorage.Prefabs.Misc:WaitForChild("GenericBillboard");
    gameAttachments = workspace.Interactables:WaitForChild("StructureAttachments");
	templateStairsModel = game.ReplicatedStorage.Prefabs.Buildings:WaitForChild("StairsTemplate");
end

function StairsPlanTemplate:SetType(t)
	self.Type = t;
end

function StairsPlanTemplate:SetColor(c)
	for _, obj in pairs(self.Model:GetChildren()) do
		if not obj:IsA("BasePart") then continue end;
		if c == "red" then
			c = RED_COLOR;
		end
		
		obj.Color = c or BLUE_COLOR;
		obj.Material = Enum.Material.SmoothPlastic;
	end
end

function StairsPlanTemplate:SetTransparency(v)
	local ot = {PrimaryPart=1; StairsBody=0;};

	for _, obj in pairs(self.Model:GetChildren()) do
		if not obj:IsA("BasePart")then continue end;

		obj.Transparency = ot[obj.Name] == 1 and 1 or v;
		obj.Material = Enum.Material.SmoothPlastic;
	end
end

local stairsIdCounter = 0;
function StairsPlanTemplate:Build(baseId)
	stairsIdCounter = stairsIdCounter +1;
	
	self.Id = stairsIdCounter;
	
	self:Update();
	self:SetTransparency(0);
	
	local baseColor = Color3.fromRGB(132, 114, 93);
	for _, obj in pairs(self.Model:GetChildren()) do
		if not obj:IsA("BasePart") then continue end;

		obj.Material = Enum.Material.WoodPlanks;
		obj.Color = baseColor;
		
		if obj.Transparency == 1 then
			if obj.Name == "PrimaryPart" then
				obj.CollisionGroup = "RaycastIgnore";
				
			else
				game.Debris:AddItem(obj, 0);
				
			end
			
		else
			obj.CanCollide = true;
			obj.CastShadow = true;
			
		end
	end
	
	self.Model:SetAttribute("FloorId", stairsIdCounter);
	self.Model:SetAttribute("GridPoint", self.GridPoint);
	
	local attachmentParent = workspace.Interactables;
	if baseId then
		attachmentParent = gameAttachments:FindFirstChild(baseId);
		if attachmentParent == nil then
			attachmentParent = Instance.new("Folder");
			attachmentParent.Name = baseId;
			attachmentParent.Parent = gameAttachments;
			attachmentParent:SetAttribute("TerritoryGroup", true);
		end
	end
	
	modAudio.Play("Repair", self.Base.Position);

	if self.AttachmentPart then
		local newInteractable = modInteractables.createInteractable("DeployableSocket", self.Type);
		newInteractable.Parent = self.AttachmentPart;
	end

    local newDestructible = modDestructibles.createDestructible();
    newDestructible.Parent = self.Model;
	
	return self;
end

function StairsPlanTemplate:SetParent(p)
	self.Model.Parent = p;
end

function StairsPlanTemplate:Clone(n)
	local newWallClass = StairsPlanTemplate.new(self);

	newWallClass.Model = self.Model:Clone();
	newWallClass.Model.Name = n;
	newWallClass.Base = newWallClass.Model:WaitForChild("PrimaryPart");
	
	newWallClass:SetTransparency(0.8);

	return newWallClass;
end

function StairsPlanTemplate:ToggleBillboard(v)
	if v == true then
		local newBillboard = templateGenericBillboard:Clone();
		newBillboard.Parent = self.Model;
		newBillboard.Adornee = self.Base;

		self.Billboard = newBillboard;
		
	else
		if self.Billboard then
			game.Debris:AddItem(self.Billboard, 0);
		end
	end
end

function StairsPlanTemplate:Destroy()
	game.Debris:AddItem(self.Model, 0);
	self.Model = nil;
	self.Base = nil;
end

function StairsPlanTemplate:CheckPlaceholder(inputs)
	local isValidPlace = false;
	local scanInfo = {};

	local foundationCf = inputs.FoundationCFrame;
	local halfGrid = inputs.GridSize/2;
	local worldGridPoint = inputs.WorldGridPoint;


	if true then
		isValidPlace = true;
	end;

	return {
		IsValid = isValidPlace;
		ScanInfo = scanInfo;
	};
end

function StairsPlanTemplate:UpdatePlaceholder(data)
	local foundationCf = data.FoundationCFrame;
	local foundationSize = data.FoundationSize;
	local worldGridPoint = data.WorldGridPoint;

	local gridSize = data.GridSize;
	local gridType = data.GridType;
	local aimPoint = data.AimPoint;

	self.CFrame = CFrame.new(worldGridPoint + Vector3.new(0, gridSize/2, 0)) * foundationCf.Rotation;
end

function StairsPlanTemplate:Update()
	local foundationPart = self.FoundationPart;
	local model = self.Model;
	model:PivotTo(self.CFrame);

	local gridSize = 14;
	local placementCf = self.CFrame;

	self.Base.Size = Vector3.zero;
	self.Base.CFrame = placementCf;
	
	if self.Type == "Floor" then

	end
end

function StairsPlanTemplate:AddInteractable()
    if self.Model:FindFirstChild("Interactable") then return end;

    local new = modInteractables.createInteractable("ConstructBuilding", self.Type);
    new.Parent = self.Model;

	local interactable: InteractableInstance = modInteractables.getOrNew(new);
	
	interactable.Values.FoundationPart = self.FoundationPart;
	interactable.Values.GridPoint = self.GridPoint;

	return new;
end

function StairsPlanTemplate.new(data)
	local self = {
		FoundationPart = data.FoundationPart;
	};

	setmetatable(self, StairsPlanTemplate);

	if data then
		for k, v in pairs(data) do
			if self[k] == nil then
				self[k] = v;
			end
		end
	end

	if self.Model == nil then
		self.Model = templateStairsModel:Clone();
	end
	if self.Base == nil then
		self.Base = self.Model:WaitForChild("PrimaryPart");
	end

	return self;
end

return StairsPlanTemplate;
