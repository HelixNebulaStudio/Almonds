---
tags:
  - technical
  - systems
---
ItemProcessor is a system that handles different item processing mechanics. E.g. Crafting, Deconstructing, unlocking Recipes, unloading ammo from weapons.. etc

These process all have a time and resource cost. The process consumes items and time to complete.

**ProcessTypes**:
- [x] CraftRecipe
- [x] Deconstruct
- ~~UnlockRecipe~~

A concurrent queue will be used for each process types. It is a queue that process 1 or more items in front of the list at a time.

**Features**:
- Equipping a `toolbelt` will set the CraftRecipe queue to from 2 items at a time instead of 1.
- Standing next to [[Shredding Stations]] increases Deconstruct queue to process 4 items at the same time. 