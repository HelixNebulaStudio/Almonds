local modInteractables = require(game.ReplicatedStorage.Library.Interactables);

for _, obj in pairs(script:GetChildren()) do
    modInteractables.loadInteractableModule(obj);
end
script.ChildAdded:Connect(modInteractables.loadInteractableModule)


return modInteractables;
