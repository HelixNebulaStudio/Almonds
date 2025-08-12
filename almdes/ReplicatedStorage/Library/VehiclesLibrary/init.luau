local modLibraryManager = shared.require(game.ReplicatedStorage.Library.LibraryManager);

local library = modLibraryManager.new();
--==

function library:loadPackage(module: ModuleScript)
    if not module:IsA("ModuleScript") then return end;
    local package = shared.require(module);
	package.Script = module;
    
    library:Add(package);
end

function library.onRequire()
	for _, module in pairs(script:GetChildren()) do
		library:loadPackage(module);
	end
	script.ChildAdded:Connect(library.loadPackage);
end

return library;