-- Copyright 2024 Sil3ntStorm https://github.com/Sil3ntStorm
--
-- Licensed under MS-RL, see https://opensource.org/licenses/MS-RL

require('__core__/lualib/util.lua')

local local_data = table.deepcopy(global.sil_fc_data)
global.sil_fc_data = {}
global.sil_filter_combinators = {}

--- @param ent LuaEntity
local function log_and_destruct(ent)
    log('1.1.0 - killing ' .. ent.name .. ' on ' .. ent.surface.name .. ' at ' .. serpent.line(ent.position))
    global.sil_filter_combinators[ent.unit_number] = nil
    ent.destroy()
end

local function kill_due_to_missing(data)
    if data and data.main and data.main.valid then
        log_and_destruct(data.main)
    end
    if data and data.cc and data.cc.valid then
        log_and_destruct(data.cc)
    end
    if data and data.ex and data.ex.valid then
        log_and_destruct(data.ex)
    end
    if data and data.filter and data.filter.valid then
        log_and_destruct(data.filter)
    end
    if data and data.inp and data.inp.valid then
        log_and_destruct(data.inp)
    end
    if data and data.input_neg and data.input_neg.valid then
        log_and_destruct(data.input_neg)
    end
    if data and data.input_pos and data.input_pos.valid then
        log_and_destruct(data.input_pos)
    end
    if data and data.inv and data.inv.valid then
        log_and_destruct(data.inv)
    end
    for _, c in pairs(data.calc) do
        if c and c.valid then
            log_and_destruct(c)
        end
    end
end

for _, data in pairs(local_data) do
    if data and data.main and data.main.valid then
        local new_idx = data.main.unit_number
        if new_idx then
            log('Moving entity internal tracking from ' .. _ .. ' to ' .. new_idx .. ' for entity at ' .. serpent.line(data.main.position) .. ' on ' .. data.main.surface.name)
            global.sil_fc_data[new_idx] = data
            global.sil_filter_combinators[data.main.unit_number] = new_idx
            global.sil_filter_combinators[data.cc.unit_number] = new_idx
            global.sil_filter_combinators[data.ex.unit_number] = new_idx
            global.sil_filter_combinators[data.filter.unit_number] = new_idx
            global.sil_filter_combinators[data.inp.unit_number] = new_idx
            global.sil_filter_combinators[data.input_neg.unit_number] = new_idx
            global.sil_filter_combinators[data.input_pos.unit_number] = new_idx
            global.sil_filter_combinators[data.inv.unit_number] = new_idx
            for _, c in pairs(data.calc) do
                if c and c.valid and c.unit_number then
                    global.sil_filter_combinators[c.unit_number] = new_idx
                end
            end
        end
    else
        log('Missing main entity - killing internals')
        kill_due_to_missing(data)
    end
end
