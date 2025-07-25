export type DAMAGE_TYPE_ALMDES =
    | "Starvation"
    | "Dehydration"
    ;

--MARK: ProfileAlmdes
export type ProfileAlmdes = Profile & {

};

--MARK: PlayerClassAlmdes
export type PlayerClassAlmdes = PlayerClass & {
};

-- MARK: GameSaveAlmdes
export type GameSaveAlmdes = GameSave & {
    WorkbenchSeed: number;
    ItemProcessor: anydict;
    RecipesUnlocked: anydict;
};
