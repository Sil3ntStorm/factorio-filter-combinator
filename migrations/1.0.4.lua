-- Copyright 2024 Sil3ntStorm https://github.com/Sil3ntStorm
--
-- Licensed under MS-RL, see https://opensource.org/licenses/MS-RL

for _, data in pairs(global.sil_fc_data) do
    --- @type FilterCombinatorData
    if not (data.filter and data.filter.valid) then
        data.filter = data.calc[9]
    end
    if not (data.inp and data.inp.valid) then
        data.inp = data.calc[1]
    end
    if not (data.input_neg and data.input_neg.valid) then
        data.input_neg = data.calc[5]
    end
    if not (data.input_pos and data.input_pos.valid) then
        data.input_pos = data.calc[7]
    end
    if not (data.inv and data.inv.valid) then
        data.inv = data.calc[11]
    end
end
