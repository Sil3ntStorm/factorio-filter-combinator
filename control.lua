-- Copyright 2023 Sil3ntStorm https://github.com/Sil3ntStorm
--
-- Licensed under MS-RL, see https://opensource.org/licenses/MS-RL

local config = {}
local configPrefix = 'sfc-'
local prefixLength = #configPrefix

for k, v in pairs(settings.global) do
    if string.sub(k, 1, prefixLength) == configPrefix then
        config[string.sub(k, prefixLength + 1)] = v.value
    end
end

local function onRTSettingChanged(event)
    if string.sub(event.setting, 1, prefixLength) ~= configPrefix then
        return
    end
    config[string.sub(event.setting, prefixLength + 1)] = settings.global[event.setting].value
end

local function create_internal_entity(main, proto)
    local ent = main.surface.create_entity{
        name = proto,
        position = main.position,
        force = main.force,
        create_build_effect_smoke = false,
        spawn_decorations = false,
        move_stuck_players = true,
    }
    return ent
end

local name_prefix = 'sil-filter-combinator'
local name_prefix_len = #name_prefix

local function onEntityCreated(event)
    if (event.created_entity and event.created_entity.valid and (event.created_entity.name == name_prefix or event.created_entity.name == name_prefix .. '-packed')) or (event.entity and event.entity.valid and (event.entity.name == name_prefix or event.entity.name == name_prefix .. '-packed')) then
        local main = event.created_entity or event.entity
        local signal_each = { type = 'virtual', name = 'signal-each' }

        -- Logic Circuitry Entities
        local cc = create_internal_entity(main, 'sil-filter-combinator-cc')
        local d1 = create_internal_entity(main, 'sil-filter-combinator-dc')
        local d2 = create_internal_entity(main, 'sil-filter-combinator-dc')
        local d3 = create_internal_entity(main, 'sil-filter-combinator-dc')
        local d4 = create_internal_entity(main, 'sil-filter-combinator-dc')
        local a1 = create_internal_entity(main, 'sil-filter-combinator-ac')
        local a2 = create_internal_entity(main, 'sil-filter-combinator-ac')
        local a3 = create_internal_entity(main, 'sil-filter-combinator-ac')
        local a4 = create_internal_entity(main, 'sil-filter-combinator-ac')
        local ccf = create_internal_entity(main, 'sil-filter-combinator-dc')
        local out = create_internal_entity(main, 'sil-filter-combinator-ac')
        -- Set Conditions
        ccf.get_or_create_control_behavior().parameters = { first_signal = signal_each, output_signal = signal_each, comparator = '!=', copy_count_from_input = false }
        out.get_or_create_control_behavior().parameters = { first_signal = signal_each, output_signal = signal_each, operation = '+', second_constant = 0 }
        d1.get_or_create_control_behavior().parameters  = { first_signal = signal_each, output_signal = signal_each, comparator = '<'}
        d2.get_or_create_control_behavior().parameters  = { first_signal = signal_each, output_signal = signal_each, comparator = '>'}
        a1.get_or_create_control_behavior().parameters  = { first_signal = signal_each, output_signal = signal_each, operation = '*', second_constant = 0 - (2 ^ 31 - 1) }
        a2.get_or_create_control_behavior().parameters  = { first_signal = signal_each, output_signal = signal_each, operation = '*', second_constant = -1 }
        d3.get_or_create_control_behavior().parameters  = { first_signal = signal_each, output_signal = signal_each, comparator = '>'}
        a3.get_or_create_control_behavior().parameters  = { first_signal = signal_each, output_signal = signal_each, operation = '*', second_constant = 2 ^ 31 - 1 }
        a4.get_or_create_control_behavior().parameters  = { first_signal = signal_each, output_signal = signal_each, operation = '*', second_constant = -1 }
        d4.get_or_create_control_behavior().parameters  = { first_signal = signal_each, output_signal = signal_each, comparator = '<'}
        -- Connect Logic
        cc.connect_neighbour({wire = defines.wire_type.red, target_entity = ccf, target_circuit_id = defines.circuit_connector_id.combinator_input})
        d1.connect_neighbour({wire = defines.wire_type.red, target_entity = d2, target_circuit_id = defines.circuit_connector_id.combinator_input, source_circuit_id = defines.circuit_connector_id.combinator_input})
        d1.connect_neighbour({wire = defines.wire_type.green, target_entity = d2, target_circuit_id = defines.circuit_connector_id.combinator_input, source_circuit_id = defines.circuit_connector_id.combinator_input})
        -- Negative Inputs
        a1.connect_neighbour({wire = defines.wire_type.red, target_entity = ccf, target_circuit_id = defines.circuit_connector_id.combinator_output, source_circuit_id = defines.circuit_connector_id.combinator_input})
        a2.connect_neighbour({wire = defines.wire_type.red, target_entity = a1, target_circuit_id = defines.circuit_connector_id.combinator_output, source_circuit_id = defines.circuit_connector_id.combinator_input})
        d3.connect_neighbour({wire = defines.wire_type.red, target_entity = a2, target_circuit_id = defines.circuit_connector_id.combinator_output, source_circuit_id = defines.circuit_connector_id.combinator_input})
        d3.connect_neighbour({wire = defines.wire_type.red, target_entity = d1, target_circuit_id = defines.circuit_connector_id.combinator_output, source_circuit_id = defines.circuit_connector_id.combinator_input})
        -- Positive Inputs
        a3.connect_neighbour({wire = defines.wire_type.red, target_entity = ccf, target_circuit_id = defines.circuit_connector_id.combinator_output, source_circuit_id = defines.circuit_connector_id.combinator_input})
        a4.connect_neighbour({wire = defines.wire_type.red, target_entity = a3, target_circuit_id = defines.circuit_connector_id.combinator_output, source_circuit_id = defines.circuit_connector_id.combinator_input})
        d4.connect_neighbour({wire = defines.wire_type.red, target_entity = a4, target_circuit_id = defines.circuit_connector_id.combinator_output, source_circuit_id = defines.circuit_connector_id.combinator_input})
        d4.connect_neighbour({wire = defines.wire_type.red, target_entity = d2, target_circuit_id = defines.circuit_connector_id.combinator_output, source_circuit_id = defines.circuit_connector_id.combinator_input})
        -- Wire up output (to be able to use any color wire again)
        out.connect_neighbour({wire = defines.wire_type.green, target_entity = a1, target_circuit_id = defines.circuit_connector_id.combinator_output, source_circuit_id = defines.circuit_connector_id.combinator_input})
        out.connect_neighbour({wire = defines.wire_type.green, target_entity = d3, target_circuit_id = defines.circuit_connector_id.combinator_output, source_circuit_id = defines.circuit_connector_id.combinator_input})
        out.connect_neighbour({wire = defines.wire_type.green, target_entity = a3, target_circuit_id = defines.circuit_connector_id.combinator_output, source_circuit_id = defines.circuit_connector_id.combinator_input})
        out.connect_neighbour({wire = defines.wire_type.green, target_entity = d4, target_circuit_id = defines.circuit_connector_id.combinator_output, source_circuit_id = defines.circuit_connector_id.combinator_input})
        -- Connect main entity
        main.connect_neighbour({wire = defines.wire_type.red, target_entity = out, target_circuit_id = defines.circuit_connector_id.combinator_output, source_circuit_id = defines.circuit_connector_id.combinator_output})
        main.connect_neighbour({wire = defines.wire_type.green, target_entity = out, target_circuit_id = defines.circuit_connector_id.combinator_output, source_circuit_id = defines.circuit_connector_id.combinator_output})
        main.connect_neighbour({wire = defines.wire_type.red, target_entity = d1, target_circuit_id = defines.circuit_connector_id.combinator_input, source_circuit_id = defines.circuit_connector_id.combinator_input})
        main.connect_neighbour({wire = defines.wire_type.green, target_entity = d1, target_circuit_id = defines.circuit_connector_id.combinator_input, source_circuit_id = defines.circuit_connector_id.combinator_input})

        -- Check if this was a blueprint
        if event.tags then
            local tags = event.tags
            if tags.enabled ~= nil and tags.params ~= nil then
                local behavior = cc.get_or_create_control_behavior()
                behavior.enabled = tags.enabled
                behavior.parameters = tags.params
            end
        end

        -- Store Entities
        local idx = #global.sil_fc_data + 1
        global.sil_fc_data[idx] = {main = main, cc = cc, calc = {d1, d2, d3, d4, a1, a2, a3, a4, ccf, out}}
        global.sil_filter_combinators[main.unit_number] = idx
        global.sil_filter_combinators[cc.unit_number]   = idx
        global.sil_filter_combinators[ccf.unit_number]  = idx
        global.sil_filter_combinators[out.unit_number]  = idx
        global.sil_filter_combinators[d1.unit_number]   = idx
        global.sil_filter_combinators[d2.unit_number]   = idx
        global.sil_filter_combinators[d3.unit_number]   = idx
        global.sil_filter_combinators[d4.unit_number]   = idx
        global.sil_filter_combinators[a1.unit_number]   = idx
        global.sil_filter_combinators[a2.unit_number]   = idx
        global.sil_filter_combinators[a3.unit_number]   = idx
        global.sil_filter_combinators[a4.unit_number]   = idx
    end
end

local function onEntityDeleted(event)
    if (not (event.entity and event.entity.valid)) then
        return
    end
    if string.sub(event.entity.name, 1, name_prefix_len) == name_prefix then
        local unit_number = event.entity.unit_number
        local match = global.sil_filter_combinators[unit_number]
        if match then
            local data = global.sil_fc_data[match]
            if data and data.cc and data.cc.valid then
                data.cc.destroy()
            end
            if data and data.calc then
                for _,e in pairs(data.calc) do
                    if e and e.valid then
                        e.destroy()
                    end
                end
            end
        end
        global.sil_filter_combinators[unit_number] = nil
    end
end

local function onEntityMoved(event)
    -- Picker Dollies Support
    -- event.player_index
    -- event.mod_name
    -- event.name
    -- event.moved_entity
    -- event.start_pos
    -- event.tick
    if (not (event.moved_entity and event.moved_entity.valid)) then
        return
    end
    if event.moved_entity.name == name_prefix then
        local unit_number = event.moved_entity.unit_number;
        local match = global.sil_filter_combinators[unit_number]
        if match then
            local data = global.sil_fc_data[match]
            if data and data.cc and data.cc.valid then
                data.cc.teleport(event.moved_entity.position)
            end
            if data and data.calc then
                for _, e in pairs(data.calc) do
                    if e and e.valid then
                        e.teleport(event.moved_entity.position)
                    end
                end
            end
        end
    end
end

local function onEntityCloned(event)
    -- Space Exploration Support
    -- event.source
    -- event.destination
    -- event.name
    -- event.tick
    if (not (event.source and event.source.valid and event.destination and event.destination.valid)) then
        return
    end

    local src = event.source
    local dst = event.destination

    if string.sub(src.name, 1, name_prefix_len) == name_prefix then
        local src_unit = src.unit_number
        local match = global.sil_filter_combinators[src_unit]
        if match then
            local data = global.sil_fc_data[match]
            if src.name == name_prefix then
                data.main = dst
            elseif src.name == name_prefix .. '-ac' or src.name == name_prefix .. '-dc' then
                for i,e in pairs(data.calc) do
                    if e and e.valid and e.unit_number == src_unit then
                        data.calc[i] = dst
                        break
                    end
                end
            elseif src.name == name_prefix .. '-cc' then
                data.cc = dst
            else
                log('Unmatched entity ' .. src.name)
            end
            global.sil_filter_combinators[dst.unit_number] = match
            global.sil_filter_combinators[src_unit] = nil
        end
    end
end

local function onGuiOpen(event)
    -- event.player_index
    -- event.gui_type
    -- event.entity.name
    -- event.item.name
    -- event.equipment
    -- event.other_player
    -- event.element
    -- event.inventory
    -- event.name
    -- event.tick
    if (event.entity and event.entity.valid and event.entity.name == name_prefix) then
        local match = global.sil_filter_combinators[event.entity.unit_number]
        if match then
            local data = global.sil_fc_data[match]
            if data and data.cc and data.cc.valid then
                game.players[event.player_index].opened = data.cc
            end
        end
    end
end

local function onEntityPasted(event)
    local pl = game.get_player(event.player_index)
    if not pl or not pl.valid or pl.force ~= event.source.force or pl.force ~= event.destination.force then
        return
    end
    if event.source.name ~= name_prefix or event.destination.name ~= name_prefix then
        return
    end
    local dest_idx = global.sil_filter_combinators[event.destination.unit_number]
    local source_idx = global.sil_filter_combinators[event.source.unit_number]
    if not dest_idx or not source_idx then
        return
    end
    local src = global.sil_fc_data[source_idx].cc
    local dst = global.sil_fc_data[dest_idx].cc
    if src and src.valid and src.force == pl.force and dst and dst.valid and dst.force == pl.force then
        dst.copy_settings(src)
    end
end

--#region Blueprint and copy / paste support

--- @param bp LuaItemStack
local function save_to_blueprint(data, bp)
    if not data then
        return
    end
    if #data < 1 then
        return
    end
    if not bp or not bp.is_blueprint_setup() then
        return
    end
    local entities = bp.get_blueprint_entities()
    if #entities < 1 then
        return
    end
    for _, unit in pairs(data) do
        local idx = global.sil_filter_combinators[unit]
        --- @type LuaEntity
        local src = global.sil_fc_data[idx].cc
        local main = global.sil_fc_data[idx].main
        --- @type LuaConstantCombinatorControlBehavior
        local behavior = src.get_or_create_control_behavior()
        local tags = {enabled = behavior.enabled, params = behavior.parameters}
        for __, e in ipairs(entities) do
            -- Because LUA is a fucking useless piece of shit we cannot compare values that are tables... because you know why the fuck would you want to....
            -- if e.position == main.position then
            if e.position.x == main.position.x and e.position.y == main.position.y then
                e.tags = tags
                break
            end
        end
    end
    -- Since we actually got a copy instead of a reference
    bp.set_blueprint_entities(entities)
end

--- @param event EventData.on_player_setup_blueprint
local function onEntityCopy(event)
    if not event.area then
        return
    end

    local player = game.players[event.player_index]
    local entities = player.surface.find_entities_filtered{ area = event.area, force = player.force }
    local result = {}
    for _, ent in pairs(entities) do
        if ent.name == name_prefix then
            table.insert(result, ent.unit_number)
        end
    end
    if #result < 1 then
        return
    end
    if player.cursor_stack.valid_for_read and player.cursor_stack.name == 'blueprint' then
        save_to_blueprint(result, player.cursor_stack)
    else
        -- Player is editing the blueprint, no access for us yet. Continue this in onBlueprintReady
        if not global.sil_fc_blueprint_data then
            global.sil_fc_blueprint_data = {}
        end
        global.sil_fc_blueprint_data[event.player_index] = result
    end
end

--- @param event EventData.on_player_configured_blueprint
local function onBlueprintReady(event)
    if not global.sil_fc_blueprint_data then
        global.sil_fc_blueprint_data = {}
    end
    local player = game.players[event.player_index]

    if player and player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.name == 'blueprint' and global.sil_fc_blueprint_data[event.player_index] then
        save_to_blueprint(global.sil_fc_blueprint_data[event.player_index], player.cursor_stack)
    end
    if global.sil_fc_blueprint_data[event.player_index] then
        global.sil_fc_blueprint_data[event.player_index] = nil
    end
end

--#endregion

--#region Compact Circuits Support

---@param entity LuaEntity
local function ccs_get_info(entity)
    if not entity or not entity.valid then
        return nil
    end
    local idx = global.sil_filter_combinators[entity.unit_number]
    ---@type LuaConstantCombinatorControlBehavior
    local behavior = global.sil_fc_data[idx].cc.get_or_create_control_behavior()
    return {
        cc_enabled = behavior.enabled,
        cc_params = behavior.parameters
    }
end

---@param surface LuaSurface
---@param position MapPosition
---@param force LuaForce
local function ccs_create_packed_entity(info, surface, position, force)
    local ent = surface.create_entity{name = name_prefix .. '-packed', position = position, force = force, direction = info.direction, raise_built = false}
    if ent then
        onEntityCreated({entity = ent})
        local idx = global.sil_filter_combinators[ent.unit_number]
        ---@type LuaConstantCombinatorControlBehavior
        local behavior = global.sil_fc_data[idx].cc.get_or_create_control_behavior()
        behavior.enabled = info.cc_enabled
        behavior.parameters = info.cc_params
    end
    return ent
end

---@param surface LuaSurface
---@param force LuaForce
local function ccs_create_entity(info, surface, force)
    local ent = surface.create_entity{name = name_prefix, position = info.position, force = force, direction = info.direction, raise_built = false}
    if ent then
        onEntityCreated({entity = ent})
        local idx = global.sil_filter_combinators[ent.unit_number]
        ---@type LuaConstantCombinatorControlBehavior
        local behavior = global.sil_fc_data[idx].cc.get_or_create_control_behavior()
        behavior.enabled = info.cc_enabled
        behavior.parameters = info.cc_params
    end
    return ent
end

--#endregion

local function initCompat()
    if remote.interfaces["PickerDollies"] and remote.interfaces["PickerDollies"]["dolly_moved_entity_id"] then
        script.on_event(remote.call("PickerDollies", "dolly_moved_entity_id"), onEntityMoved)
    end
    if remote.interfaces['PickerDollies'] and remote.interfaces['PickerDollies']['add_oblong_name'] then
        remote.call('PickerDollies', 'add_oblong_name', name_prefix)
    end
    if script.active_mods['compaktcircuit'] and remote.interfaces['compaktcircuit'] and remote.interfaces['compaktcircuit']['add_combinator'] then
        remote.add_interface(name_prefix, {
            get_info = ccs_get_info,
            create_packed_entity = ccs_create_packed_entity,
            create_entity = ccs_create_entity
        })
        remote.call('compaktcircuit', 'add_combinator', {
            name = name_prefix,
            packed_names = { name_prefix .. '-packed' },
            interface_name = name_prefix
        })
    end
end

script.on_event(defines.events.on_runtime_mod_setting_changed, onRTSettingChanged)

script.on_event(defines.events.on_gui_opened, onGuiOpen)
script.on_event({defines.events.on_pre_player_mined_item, defines.events.on_robot_pre_mined, defines.events.on_entity_died}, onEntityDeleted)
script.on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity, defines.events.script_raised_revive}, onEntityCreated)
script.on_event(defines.events.on_entity_cloned, onEntityCloned)
script.on_event(defines.events.on_entity_settings_pasted, onEntityPasted)

script.on_event(defines.events.on_player_setup_blueprint, onEntityCopy)
script.on_event(defines.events.on_player_configured_blueprint, onBlueprintReady)

script.on_init(function()
    if not global.sil_filter_combinators then
        global.sil_filter_combinators = {}
    end
    if not global.sil_fc_data then
        global.sil_fc_data = {}
    end
    initCompat()
end)

script.on_load(function()
    initCompat()
end)
