-- Copyright 2023 Sil3ntStorm https://github.com/Sil3ntStorm
--
-- Licensed under MS-RL, see https://opensource.org/licenses/MS-RL

for _, f in pairs(game.forces) do
    f.recipes['sil-filter-combinator'].enabled = f.technologies["circuit-network"].researched
end
