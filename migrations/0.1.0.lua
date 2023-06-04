-- Copyright 2023 Sil3ntStorm https://github.com/Sil3ntStorm
--
-- Licensed under MS-RL, see https://opensource.org/licenses/MS-RL

for _, f in pairs(game.forces) do
    f.recipes['sil-filter-combinator'].enabled = f.technologies['circuit-network'].researched
    if game.active_mods['nullius'] then
        f.recipes['sil-filter-combinator'].enabled = f.technologies['nullius-computation'].researched
    end
end
