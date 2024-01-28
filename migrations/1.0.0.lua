-- Copyright 2023 Sil3ntStorm https://github.com/Sil3ntStorm
--
-- Licensed under MS-RL, see https://opensource.org/licenses/MS-RL

require('__core__/lualib/util.lua')

local name_prefix = 'sil-filter-combinator'
local name_prefix_len = #name_prefix
local local_data = table.deepcopy(global.sil_fc_data)
global.sil_fc_data = {}
global.sil_filter_combinators = {}
global.sil_fc_migration_data = {}

for _, data in pairs(local_data) do
    if data and data.cc and data.cc.valid and data.main and data.main.valid then
        log('Updating ' .. data.main.name .. ' on ' .. data.main.surface.name .. ' at ' .. serpent.line(data.main.position))
        local behavior = data.cc.get_or_create_control_behavior()
        local bp_data = { config = {enabled = behavior.enabled, filter_input_from_wire = false, filter_input_wire = defines.wire_type.green, exclusive = false}, params = behavior.parameters}
        --- @type LuaEntity
        local main = data.main
        local connected = main.circuit_connection_definitions
        local x = main.position.x
        local y = main.position.y
        local dir = main.direction
        local surf = main.surface
        local force = main.force
        local restore = {}
        local idx = global.sil_filter_combinators[main.unit_number]
        local unit_ids = {}
        table.insert(unit_ids, main.unit_number)
        table.insert(unit_ids, data.cc.unit_number)
        for _, sub_ent in pairs(data.calc) do
            table.insert(unit_ids, sub_ent.unit_number)
        end
        if connected then
            for _, con in ipairs(connected) do
                if string.sub(con.target_entity.name, 1, name_prefix_len) ~= name_prefix then
                    table.insert(restore, con)
                end
            end
        end
        -- Kill Entities
        main.destroy()
        data.cc.destroy()
        for _, e in pairs(data.calc) do
            if e and e.valid then
                e.destroy()
            end
        end
        -- Create new entity
        local n_ghost = surf.create_entity{name = 'entity-ghost', inner_name = name_prefix, direction = dir, position = {x, y}, force = force}
        --- @type LuaEntity
        local n_ent = nil
        if n_ghost then
            n_ghost.tags = bp_data
            -- _, n_ent, __ = n_ghost.silent_revive{raise_revive = true}
            -- Our actual code does not run when simply creating the entity here, so we will defer that until the actual code can run?
            table.insert(global.sil_fc_migration_data, {ent = n_ghost, con = restore})
        else
            log('Failed to create ghost for combinator on ' .. surf.name .. ' at ' .. x .. ',' .. y .. ' with config ' .. serpent.line(bp_data.config))
        end
        -- Restore circuit connections
        --if n_ent then
        --    for _, con in pairs(restore) do
        --        n_ent.connect_neighbour(con)
        --    end
        --else
        --    log('Failed to create combinator on ' .. surf.name .. ' at ' .. x .. ',' .. y .. ' with config ' .. serpent.line(bp_data))
        --end
    else
        -- Missing vital parts, kill whats left
        if data.main and data.main.valid then
            data.main.destroy()
        end
        if data.cc and data.cc.valid then
            data.cc.destroy()
        end
        if data.calc then
            for _, e in pairs(data.calc) do
                if e and e.valid then
                    e.destroy()
                end
            end
        end
    end
end
