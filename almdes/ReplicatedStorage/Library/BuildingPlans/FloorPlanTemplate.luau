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

local FLOOR_DEPTH = 1.6;

local FloorPlanTemplate = {};
FloorPlanTemplate.__index = FloorPlanTemplate;
FloorPlanTemplate.ClassName = "FloorPlan";

--==

function FloorPlanTemplate.onRequire(BuildingPlans)
	modBuildingPlans = BuildingPlans;

	templateGenericBillboard = game.ReplicatedStorage.Prefabs.Misc:WaitForChild("GenericBillboard");
    gameAttachments = workspace.Interactables:WaitForChild("StructureAttachments");
	templateFloorModel = game.ReplicatedStorage.Prefabs.Buildings:WaitForChild("FloorTemplate");
end

function FloorPlanTemplate:SetType(t)
	self.Type = t;
end

function FloorPlanTemplate:SetColor(c)
	for _, obj in pairs(self.Model:GetChildren()) do
		if not obj:IsA("BasePart") then continue end;
		if c == "red" then
			c = RED_COLOR;
		end
		
		obj.Color = c or BLUE_COLOR;
	end
end

function FloorPlanTemplate:SetTransparency(v)
	local ot = {PrimaryPart=1; L=1; R=1; B=1; F=1;};

	if self.Type == "Floor" then
		ot = {PrimaryPart=0; L=1; R=1; B=1; F=1;};
	end

	for _, obj in pairs(self.Model:GetChildren()) do
		if not obj:IsA("BasePart")then continue end;

		obj.Transparency = ot[obj.Name] == 1 and 1 or v;
	end
end

local floorIdCounter = 0;
function FloorPlanTemplate:Build(baseId)
	floorIdCounter = floorIdCounter +1;
	
	self.Id = floorIdCounter;
	
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
	
	self.Model:SetAttribute("FloorId", floorIdCounter);
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

function FloorPlanTemplate:SetParent(p)
	self.Model.Parent = p;
end

function FloorPlanTemplate:Clone(n)
	local newWallClass = FloorPlanTemplate.new(self);

	newWallClass.Model = self.Model:Clone();
	newWallClass.Model.Name = n;
	newWallClass.Base = newWallClass.Model:WaitForChild("PrimaryPart");
	
	newWallClass:SetTransparency(0.8);

	return newWallClass;
end

function FloorPlanTemplate:ToggleBillboard(v)
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

function FloorPlanTemplate:Destroy()
	game.Debris:AddItem(self.Model, 0);
	self.Model = nil;
	self.Base = nil;
end

function FloorPlanTemplate:CheckPlaceholder(inputs)
	local structuralCheckRayParams = RaycastParams.new();
	structuralCheckRayParams.FilterType = Enum.RaycastFilterType.Include;
	structuralCheckRayParams.IgnoreWater = true;
	structuralCheckRayParams.FilterDescendantsInstances = {inputs.BuildingScene};

	local isValidPlace = false;
	local scanInfo = {};

	local foundationCf = inputs.FoundationCFrame;
	local halfGrid = inputs.GridSize/2;
	local worldGridPoint = inputs.WorldGridPoint;

	local checkLength = halfGrid + 2;
	local leftRay = workspace:Raycast(worldGridPoint, foundationCf.RightVector * -checkLength, structuralCheckRayParams);
	local rightRay = workspace:Raycast(worldGridPoint, foundationCf.RightVector * checkLength, structuralCheckRayParams);
	local frontRay = workspace:Raycast(worldGridPoint, foundationCf.LookVector * checkLength, structuralCheckRayParams);
	local backRay = workspace:Raycast(worldGridPoint, foundationCf.LookVector * -checkLength, structuralCheckRayParams);
	
	local bgRay = Debugger:Ray(Ray.new(worldGridPoint, foundationCf.RightVector * -checkLength), leftRay and leftRay.Instance, leftRay and leftRay.Position, leftRay and leftRay.Normal)
	bgRay.Color = Color3.fromRGB(0, 0, 255);
	game.Debris:AddItem(bgRay, 0.1);

	local bgRay = Debugger:Ray(Ray.new(worldGridPoint, foundationCf.RightVector * checkLength), rightRay and rightRay.Instance, rightRay and rightRay.Position, rightRay and rightRay.Normal)
	bgRay.Color = Color3.fromRGB(0, 0, 50);
	game.Debris:AddItem(bgRay, 0.1);

	local bgRay = Debugger:Ray(Ray.new(worldGridPoint, foundationCf.LookVector * checkLength), frontRay and frontRay.Instance, frontRay and frontRay.Position, frontRay and frontRay.Normal)
	bgRay.Color = Color3.fromRGB(255, 0, 0);
	game.Debris:AddItem(bgRay, 0.1);

	local bgRay = Debugger:Ray(Ray.new(worldGridPoint, foundationCf.LookVector * -checkLength), backRay and backRay.Instance, backRay and backRay.Position, backRay and backRay.Normal)
	bgRay.Color = Color3.fromRGB(50, 0, 0);
	game.Debris:AddItem(bgRay, 0.1);

	if leftRay or rightRay or frontRay or backRay then
		isValidPlace = true;

		scanInfo.LeftRay = leftRay;
		scanInfo.RightRay = rightRay;
		scanInfo.FrontRay = frontRay;
		scanInfo.BackRay = backRay;
	end;

	return {
		IsValid = isValidPlace;
		ScanInfo = scanInfo;
	};
end

function FloorPlanTemplate:UpdatePlaceholder(data)
	local foundationCf = data.FoundationCFrame;
	local foundationSize = data.FoundationSize;
	local worldGridPoint = data.WorldGridPoint;

	local gridSize = data.GridSize;
	local gridType = data.GridType;
	local aimPoint = data.AimPoint;

	self.CFrame = CFrame.new(worldGridPoint - Vector3.new(0, (FLOOR_DEPTH/2)-0.01, 0)) * foundationCf.Rotation;
end

function FloorPlanTemplate:Update()
	local foundationPart = self.FoundationPart;
	local model = self.Model;
	model:PivotTo(self.CFrame);

	local gridSize = 14;
	local placementCf = self.CFrame;

	self.Base.Size = Vector3.new(gridSize, FLOOR_DEPTH, gridSize);
	self.Base.CFrame = placementCf;
	
	if self.Type == "Floor" then

	end
end

function FloorPlanTemplate:AddInteractable()
    if self.Model:FindFirstChild("Interactable") then return end;

    local new = modInteractables.createInteractable("ConstructBuilding", self.Type);
    new.Parent = self.Model;

	local interactable: InteractableInstance = modInteractables.getOrNew(new);
	
	interactable.Values.FoundationPart = self.FoundationPart;
	interactable.Values.GridPoint = self.GridPoint;

	return new;
end

function FloorPlanTemplate.new(data)
	local self = {
		FoundationPart = data.FoundationPart;
	};

	setmetatable(self, FloorPlanTemplate);

	if data then
		for k, v in pairs(data) do
			if self[k] == nil then
				self[k] = v;
			end
		end
	end

	if self.Model == nil then
		self.Model = templateFloorModel:Clone();
	end
	if self.Base == nil then
		self.Base = self.Model:WaitForChild("PrimaryPart");
	end

	return self;
end

return FloorPlanTemplate;
