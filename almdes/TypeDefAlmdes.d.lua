export type DAMAGE_TYPE_ALMDES =
    | "Starvation"
    | "Dehydration"
    ;

--MARK: ProfileAlmdes
export type ProfileAlmdes = Profile & {

};

-- MARK: GameSaveAlmdes
export type GameSaveAlmdes = GameSave & {
    WorkbenchSeed: number;
};
