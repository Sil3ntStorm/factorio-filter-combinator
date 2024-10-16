-- Copyright 2023 Sil3ntStorm https://github.com/Sil3ntStorm
--
-- Licensed under MS-RL, see https://opensource.org/licenses/MS-RL

local flib_gui = require("__flib__/gui")

local config = require('dev')
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

local function create_internal_entity(main, proto, desc, offset)
    local pos = config['debug_mode'] and {x=main.position.x + offset[1], y=main.position.y + offset[2]} or main.position
    local ent = main.surface.create_entity{
        name = proto,
        position = pos,
        force = main.force,
        create_build_effect_smoke = false,
        spawn_decorations = false,
        move_stuck_players = true,
    }
    if ent and config['debug_mode'] then
        ent.combinator_description = desc
    end
    return ent
end

local name_prefix = 'sil-filter-combinator'
local name_prefix_len = #name_prefix

--- @param comb LuaEntity
local function set_all_signals(comb)
    ---@type LuaConstantCombinatorControlBehavior
    local behavior = comb.get_or_create_control_behavior()
    if behavior.sections_count < 1 then
        behavior.add_section()
    end
    local section = behavior.get_section(1)
    local max_used_slot = section.filters_count
    local idx = 1
    local had_error = false
    for sig_name, _ in pairs(prototypes.item) do
        section.set_slot(idx, {value = {type = 'item', name = sig_name, quality = "normal", comparator = "="}, min = 1})
        idx = idx + 1
    end
    for sig_name, _ in pairs(prototypes.fluid) do
        section.set_slot(idx, {value = {type = 'fluid', name = sig_name, quality = "normal", comparator = "="}, min = 1})
        idx = idx + 1
    end
    for sig_name, proto in pairs(prototypes.virtual_signal) do
        if not proto.special then
            section.set_slot(idx, {value = {type = 'virtual', name = sig_name, quality = "normal", comparator = "="}, min = 1})
            idx = idx + 1
        end
    end
    if idx < max_used_slot then
        while idx < max_used_slot do
            section.clear_slot(idx)
            idx = idx + 1
        end
    end
end

--- @return FilterCombinatorConfig
local function get_default_config()
    --- @type FilterCombinatorConfig
    local conf = {
        enabled = true,
        filter_input_from_wire = false,
        filter_input_wire = defines.wire_type.green,
        exclusive = false
    }
    return conf
end

--- @param data FilterCombinatorData
local function update_entity(data)
    local non_filter_wire = defines.wire_type.red
    local filter_wire = defines.wire_type.green
    if data.config.filter_input_wire == defines.wire_type.red then
        non_filter_wire = defines.wire_type.green
        filter_wire = defines.wire_type.red
    end
    local wire_origin = config['debug_mode'] and defines.wire_origin.player or defines.wire_origin.script

    -- Disconnect main, which was potentially rewired for wire input based filtering
    data.main.get_wire_connector(defines.wire_connector_id.combinator_input_red, true).disconnect_from(data.inp.get_wire_connector(defines.wire_connector_id.combinator_input_red, true), wire_origin)
    data.main.get_wire_connector(defines.wire_connector_id.combinator_input_green, true).disconnect_from(data.inp.get_wire_connector(defines.wire_connector_id.combinator_input_green, true), wire_origin)
    data.main.get_wire_connector(defines.wire_connector_id.combinator_input_red, true).disconnect_from(data.filter.get_wire_connector(defines.wire_connector_id.combinator_input_red, true), wire_origin)
    data.main.get_wire_connector(defines.wire_connector_id.combinator_input_green, true).disconnect_from(data.filter.get_wire_connector(defines.wire_connector_id.combinator_input_green, true), wire_origin)
    if not data.config.enabled then
        -- If disabled nothing else to do after disconnecting main entity
        return
    end
    -- Disconnect configured input, which gets rewired for exclusive mode and wire input filtering
    data.cc.get_wire_connector(defines.wire_connector_id.circuit_red, true).disconnect_all(wire_origin)
    -- Disconnect inverter, which gets rewired for exclusive mode
    data.inv.get_wire_connector(defines.wire_connector_id.combinator_output_red, true).disconnect_from(data.input_pos.get_wire_connector(defines.wire_connector_id.combinator_input_red, true), wire_origin)
    data.inv.get_wire_connector(defines.wire_connector_id.combinator_output_red, true).disconnect_from(data.input_neg.get_wire_connector(defines.wire_connector_id.combinator_input_red, true), wire_origin)
    -- Disconnect filter, which gets rewired for wire input based filtering
    data.filter.get_wire_connector(defines.wire_connector_id.combinator_output_red, true).disconnect_from(data.input_pos.get_wire_connector(defines.wire_connector_id.combinator_input_red, true), wire_origin)
    data.filter.get_wire_connector(defines.wire_connector_id.combinator_output_red, true).disconnect_from(data.input_neg.get_wire_connector(defines.wire_connector_id.combinator_input_red, true), wire_origin)
    if data.config.exclusive and not data.config.filter_input_from_wire then
        -- All but the configured signals
        data.inv.get_wire_connector(defines.wire_connector_id.combinator_output_red, true).connect_to(data.input_pos.get_wire_connector(defines.wire_connector_id.combinator_input_red, true), false, wire_origin)
        data.inv.get_wire_connector(defines.wire_connector_id.combinator_output_red, true).connect_to(data.input_neg.get_wire_connector(defines.wire_connector_id.combinator_input_red, true), false, wire_origin)
        data.main.get_wire_connector(defines.wire_connector_id.combinator_input_red, true).connect_to(data.inp.get_wire_connector(defines.wire_connector_id.combinator_input_red, true), false, wire_origin)
        data.main.get_wire_connector(defines.wire_connector_id.combinator_input_green, true).connect_to(data.inp.get_wire_connector(defines.wire_connector_id.combinator_input_green, true), false, wire_origin)
        data.cc.get_wire_connector(defines.wire_connector_id.circuit_red, true).connect_to(data.inv.get_wire_connector(defines.wire_connector_id.combinator_input_red, true), false, wire_origin)
    elseif not data.config.filter_input_from_wire then
        -- Default config
        data.cc.get_wire_connector(defines.wire_connector_id.circuit_red, true).connect_to(data.input_pos.get_wire_connector(defines.wire_connector_id.combinator_input_red, true), false, wire_origin)
        data.cc.get_wire_connector(defines.wire_connector_id.circuit_red, true).connect_to(data.input_neg.get_wire_connector(defines.wire_connector_id.combinator_input_red, true), false, wire_origin)
        data.main.get_wire_connector(defines.wire_connector_id.combinator_input_red, true).connect_to(data.inp.get_wire_connector(defines.wire_connector_id.combinator_input_red, true), false, wire_origin)
        data.main.get_wire_connector(defines.wire_connector_id.combinator_input_green, true).connect_to(data.inp.get_wire_connector(defines.wire_connector_id.combinator_input_green, true), false, wire_origin)
    elseif data.config.exclusive then
        -- All but those present on an input wire
        if data.config.filter_input_wire == defines.wire_type.green then
            data.main.get_wire_connector(defines.wire_connector_id.combinator_input_red, true).connect_to(data.inp.get_wire_connector(defines.wire_connector_id.combinator_input_red, true), false, wire_origin)
            data.main.get_wire_connector(defines.wire_connector_id.combinator_input_green, true).connect_to(data.filter.get_wire_connector(defines.wire_connector_id.combinator_input_green, true), false, wire_origin)
        else
            data.main.get_wire_connector(defines.wire_connector_id.combinator_input_green, true).connect_to(data.inp.get_wire_connector(defines.wire_connector_id.combinator_input_green, true), false, wire_origin)
            data.main.get_wire_connector(defines.wire_connector_id.combinator_input_red, true).connect_to(data.filter.get_wire_connector(defines.wire_connector_id.combinator_input_red, true), false, wire_origin)
        end
        data.inv.get_wire_connector(defines.wire_connector_id.combinator_output_red, true).connect_to(data.input_pos.get_wire_connector(defines.wire_connector_id.combinator_input_red, true), false, wire_origin)
        data.inv.get_wire_connector(defines.wire_connector_id.combinator_output_red, true).connect_to(data.input_neg.get_wire_connector(defines.wire_connector_id.combinator_input_red, true), false, wire_origin)
    else
        -- Wire input is the signals we want
        if data.config.filter_input_wire == defines.wire_type.green then
            data.main.get_wire_connector(defines.wire_connector_id.combinator_input_red, true).connect_to(data.inp.get_wire_connector(defines.wire_connector_id.combinator_input_red, true), false, wire_origin)
            data.main.get_wire_connector(defines.wire_connector_id.combinator_input_green, true).connect_to(data.filter.get_wire_connector(defines.wire_connector_id.combinator_input_green, true), false, wire_origin)
        else
            data.main.get_wire_connector(defines.wire_connector_id.combinator_input_green, true).connect_to(data.inp.get_wire_connector(defines.wire_connector_id.combinator_input_green, true), false, wire_origin)
            data.main.get_wire_connector(defines.wire_connector_id.combinator_input_red, true).connect_to(data.filter.get_wire_connector(defines.wire_connector_id.combinator_input_red, true), false, wire_origin)
        end
        data.filter.get_wire_connector(defines.wire_connector_id.combinator_output_red, true).connect_to(data.input_pos.get_wire_connector(defines.wire_connector_id.combinator_input_red, true), false, wire_origin)
        data.filter.get_wire_connector(defines.wire_connector_id.combinator_output_red, true).connect_to(data.input_neg.get_wire_connector(defines.wire_connector_id.combinator_input_red, true), false, wire_origin)
    end
end

--- @param event EventData.on_built_entity | EventData.on_robot_built_entity | EventData.script_raised_revive
local function onEntityCreated(event)
    if (event.created_entity and event.created_entity.valid and (event.created_entity.name == name_prefix or event.created_entity.name == name_prefix .. '-packed')) or (event.entity and event.entity.valid and (event.entity.name == name_prefix or event.entity.name == name_prefix .. '-packed')) then
        local main = event.created_entity or event.entity
        local signal_each = { type = 'virtual', name = 'signal-each' }

        --- @type FilterCombinatorConfig
        local conf = get_default_config()
        -- Logic Circuitry Entities
        local cc  = create_internal_entity(main, 'sil-filter-combinator-cc', 'CC\n\nFilters selected by user', {5, 4})
        local d1  = create_internal_entity(main, 'sil-filter-combinator-dc', 'D1 / inp\n\nNegative Signals Input Filter', {1, 4})
        local d2  = create_internal_entity(main, 'sil-filter-combinator-dc', 'D2\n\nPositive Signals Input Filter', {2, 4})
        local d3  = create_internal_entity(main, 'sil-filter-combinator-dc', 'D3\n\nPositive Input Filter', {1, 0})
        local d4  = create_internal_entity(main, 'sil-filter-combinator-dc', 'D4\n\nNegative Input Filter', {2, 0})
        local a1  = create_internal_entity(main, 'sil-filter-combinator-ac', 'A1 / input_neg\n\nNegative Inputs Negative Infinity', {3, 2})
        local a2  = create_internal_entity(main, 'sil-filter-combinator-ac', 'A2\n\nNegative Inputs Signal Inverter', {0, 2})
        local a3  = create_internal_entity(main, 'sil-filter-combinator-ac', 'A3 / input_pos\n\nPositive Inputs Positive Infinity', {4, 2})
        local a4  = create_internal_entity(main, 'sil-filter-combinator-ac', 'A4\n\nPositive Inputs Signal Inverter', {3, 0})
        local ccf = create_internal_entity(main, 'sil-filter-combinator-dc', 'CCF / filter\n\nSignal present filter. Converts every non-zero signal to 1. For Wire based filter mode', {6, 2})
        local out = create_internal_entity(main, 'sil-filter-combinator-ac', 'OUT\n\nCombines signals, prevents backflow and allows using both wires without affecting internals', {2,-2})
        local ex  = create_internal_entity(main, 'sil-filter-combinator-cc', 'EX\n\nContains every signal in the game at 1 for exclusive mode', {5, 0})
        local inv = create_internal_entity(main, 'sil-filter-combinator-ac', 'INV\n\nInverts incoming signals', {5, 2})
        -- Check if this was a blueprint which we added custom data to
        if event.tags then
            local behavior = cc.get_or_create_control_behavior()
            if event.tags.config ~= nil and event.tags.params ~= nil then
                conf = event.tags.config
                log('Restoring parameters from tags: ' .. serpent.line(event.tags.params) .. ' conf: ' .. serpent.line(conf))
                for id, sec in pairs(event.tags.params) do
                    log('Section ' .. serpent.line(id) .. ': ' .. serpent.line(sec))
                    if not behavior.get_section(id) then
                        behavior.add_section()
                    end
                    local section = behavior.get_section(id)
                    section.filters = sec
                end
            elseif event.tags.cc_config ~= nil and event.tags.cc_params ~= nil then
                conf = event.tags.cc_config
                for id, sec in pairs(event.tags.cc_params) do
                    if not behavior.get_section(id) then
                        behavior.add_section()
                    end
                    local section = behavior.get_section(id)
                    section.filters = sec.filters
                end
            end
            behavior.enabled = conf.enabled
            ex.get_or_create_control_behavior().enabled = conf.enabled
        end
        -- Set up Exclusive mode Combinator signals
        set_all_signals(ex)
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
        inv.get_or_create_control_behavior().parameters = { first_signal = signal_each, output_signal = signal_each, operation = '*', second_constant = -1 }

        local wire_origin = config['debug_mode'] and defines.wire_origin.player or defines.wire_origin.script
        -- Exclusive Mode
        ex.get_wire_connector(defines.wire_connector_id.circuit_red, true).connect_to(inv.get_wire_connector(defines.wire_connector_id.combinator_output_red, true), false, wire_origin)
        cc.get_wire_connector(defines.wire_connector_id.circuit_red, true).connect_to(inv.get_wire_connector(defines.wire_connector_id.combinator_input_red, true), false, wire_origin)
        -- Connect Logic
        ccf.get_wire_connector(defines.wire_connector_id.combinator_output_red, true).connect_to(inv.get_wire_connector(defines.wire_connector_id.combinator_input_red, true), false, wire_origin)
        d1.get_wire_connector(defines.wire_connector_id.combinator_input_red, true).connect_to(d2.get_wire_connector(defines.wire_connector_id.combinator_input_red, true), false, wire_origin)
        d1.get_wire_connector(defines.wire_connector_id.combinator_input_green, true).connect_to(d2.get_wire_connector(defines.wire_connector_id.combinator_input_green, true), false, wire_origin)
        -- Negative Inputs
        a1.get_wire_connector(defines.wire_connector_id.combinator_input_red, true).connect_to(cc.get_wire_connector(defines.wire_connector_id.circuit_red, true), false, wire_origin)
        a2.get_wire_connector(defines.wire_connector_id.combinator_input_red, true).connect_to(a1.get_wire_connector(defines.wire_connector_id.combinator_output_red, true), false, wire_origin)
        d3.get_wire_connector(defines.wire_connector_id.combinator_input_red, true).connect_to(a2.get_wire_connector(defines.wire_connector_id.combinator_output_red, true), false, wire_origin)
        d3.get_wire_connector(defines.wire_connector_id.combinator_input_red, true).connect_to(d1.get_wire_connector(defines.wire_connector_id.combinator_output_red, true), false, wire_origin)
        -- Positive Inputs
        a3.get_wire_connector(defines.wire_connector_id.combinator_input_red, true).connect_to(cc.get_wire_connector(defines.wire_connector_id.circuit_red, true), false, wire_origin)
        a4.get_wire_connector(defines.wire_connector_id.combinator_input_red, true).connect_to(a3.get_wire_connector(defines.wire_connector_id.combinator_output_red, true), false, wire_origin)
        d4.get_wire_connector(defines.wire_connector_id.combinator_input_red, true).connect_to(a4.get_wire_connector(defines.wire_connector_id.combinator_output_red, true), false, wire_origin)
        d4.get_wire_connector(defines.wire_connector_id.combinator_input_red, true).connect_to(d2.get_wire_connector(defines.wire_connector_id.combinator_output_red, true), false, wire_origin)
        -- Wire up output (to be able to use any color wire again)
        out.get_wire_connector(defines.wire_connector_id.combinator_input_green, true).connect_to(a1.get_wire_connector(defines.wire_connector_id.combinator_output_green, true), false, wire_origin)
        out.get_wire_connector(defines.wire_connector_id.combinator_input_green, true).connect_to(d3.get_wire_connector(defines.wire_connector_id.combinator_output_green, true), false, wire_origin)
        out.get_wire_connector(defines.wire_connector_id.combinator_input_green, true).connect_to(a3.get_wire_connector(defines.wire_connector_id.combinator_output_green, true), false, wire_origin)
        out.get_wire_connector(defines.wire_connector_id.combinator_input_green, true).connect_to(d4.get_wire_connector(defines.wire_connector_id.combinator_output_green, true), false, wire_origin)
        -- Connect main entity
        main.get_wire_connector(defines.wire_connector_id.combinator_output_red, true).connect_to(out.get_wire_connector(defines.wire_connector_id.combinator_output_red, true), false, wire_origin)
        main.get_wire_connector(defines.wire_connector_id.combinator_output_green, true).connect_to(out.get_wire_connector(defines.wire_connector_id.combinator_output_green, true), false, wire_origin)
        main.get_wire_connector(defines.wire_connector_id.combinator_input_red, true).connect_to(d1.get_wire_connector(defines.wire_connector_id.combinator_input_red, true), false, wire_origin)
        main.get_wire_connector(defines.wire_connector_id.combinator_input_green, true).connect_to(d1.get_wire_connector(defines.wire_connector_id.combinator_input_green, true), false, wire_origin)

        -- Store Entities
        local idx = main.unit_number
        storage.sil_fc_data[idx] = {main = main, cc = cc, calc = {d1, d2, d3, d4, a1, a2, a3, a4, ccf, out, inv}, ex = ex, inv = inv, input_pos = a3, input_neg = a1, filter = ccf, inp = d1, config = conf}
        storage.sil_filter_combinators[main.unit_number] = idx
        storage.sil_filter_combinators[cc.unit_number]   = idx
        storage.sil_filter_combinators[ccf.unit_number]  = idx
        storage.sil_filter_combinators[out.unit_number]  = idx
        storage.sil_filter_combinators[d1.unit_number]   = idx
        storage.sil_filter_combinators[d2.unit_number]   = idx
        storage.sil_filter_combinators[d3.unit_number]   = idx
        storage.sil_filter_combinators[d4.unit_number]   = idx
        storage.sil_filter_combinators[a1.unit_number]   = idx
        storage.sil_filter_combinators[a2.unit_number]   = idx
        storage.sil_filter_combinators[a3.unit_number]   = idx
        storage.sil_filter_combinators[a4.unit_number]   = idx
        storage.sil_filter_combinators[ex.unit_number]   = idx
        storage.sil_filter_combinators[inv.unit_number]  = idx

        -- check for default config
        if not (conf.enabled == true and conf.filter_input_from_wire == false and conf.filter_input_wire == defines.wire_type.green and conf.exclusive == false) then
            update_entity(storage.sil_fc_data[idx])
        end
    end
end

--- @param data FilterCombinatorData
local function kill_internal_entities(data)
    if data and data.cc and data.cc.valid then
        storage.sil_filter_combinators[data.cc.unit_number] = nil
        data.cc.destroy()
    end
    if data and data.ex and data.ex.valid then
        storage.sil_filter_combinators[data.ex.unit_number] = nil
        data.ex.destroy()
    end
    if data and data.calc then
        for _,e in pairs(data.calc) do
            if e and e.valid then
                storage.sil_filter_combinators[e.unit_number] = nil
                e.destroy()
            end
        end
    end
end

local function onEntityDeleted(event)
    if (not (event.entity and event.entity.valid)) then
        return
    end
    if string.sub(event.entity.name, 1, name_prefix_len) == name_prefix then
        local unit_number = event.entity.unit_number
        local match = storage.sil_filter_combinators[unit_number]
        if match then
            local data = storage.sil_fc_data[match]
            if data and data.main and data.main.valid and data.main.unit_number ~= unit_number then
                storage.sil_filter_combinators[data.main.unit_number] = nil
                data.main.destroy()
            end
            kill_internal_entities(data)
            storage.sil_fc_data[match] = nil
        end
        storage.sil_filter_combinators[unit_number] = nil
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
        local match = storage.sil_filter_combinators[unit_number]
        if match then
            local data = storage.sil_fc_data[match]
            if data and data.cc and data.cc.valid then
                data.cc.teleport(event.moved_entity.position)
            end
            if data and data.ex and data.ex.valid then
                data.ex.teleport(event.moved_entity.position)
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

--- @param event EventData.on_entity_cloned
local function onEntityCloned(event)
    -- Space Exploration Support
    if (not (event.source and event.source.valid and event.destination and event.destination.valid)) then
        return
    end

    local src = event.source
    local dst = event.destination

    if string.sub(src.name, 1, name_prefix_len) == name_prefix then
        local src_unit = src.unit_number
        local match = storage.sil_filter_combinators[src_unit]
        if match then
            local data = storage.sil_fc_data[match]
            if src.name == name_prefix then
                data.main = dst
            elseif src.name == name_prefix .. '-ac' or src.name == name_prefix .. '-dc' then
                for i,e in pairs(data.calc) do
                    if e and e.valid and e.unit_number == src_unit then
                        data.calc[i] = dst
                        break
                    end
                end
                if src_unit == data.inv.unit_number then
                    data.inv = dst
                elseif src_unit == data.input_pos.unit_number then
                    data.input_pos = dst
                elseif src_unit == data.input_neg.unit_number then
                    data.input_neg = dst
                elseif src_unit == data.filter.unit_number then
                    data.filter = dst
                elseif src_unit == data.inp.unit_number then
                    data.inp = dst
                end
            elseif src.name == name_prefix .. '-cc' then
                if data.cc.unit_number == src_unit then
                    data.cc = dst
                elseif data.ex.unit_number == src_unit then
                    data.ex = dst
                else
                    log('Failed to update ' .. src.name .. ' ' .. src_unit .. ' -> ' .. dst.unit_number)
                end
            else
                log('Unmatched entity ' .. src.name)
            end
            storage.sil_filter_combinators[dst.unit_number] = match
            storage.sil_filter_combinators[src_unit] = nil
        end
    end
end

--#region gui

--- @param player LuaPlayer
local function destroy_gui(player)
    if not storage.sil_fc_gui then
        storage.sil_fc_gui = {}
    end
    local ui = storage.sil_fc_gui[player.index]
    if not ui then
        return
    end
    local main = ui.ui.sil_fc_filter_ui
    if not (main and main.valid) then
        return
    end
    if player.opened == main then
        player.opened = nil
    end
    main.destroy()
end

--- @param event EventData.on_gui_click
local function on_window_closed(event)
    destroy_gui(game.players[event.player_index])
end

--- @param event EventData.on_gui_switch_state_changed
local function on_switch_enabled(event)
    local ui = storage.sil_fc_gui[event.player_index]
    if not ui then
        return
    end
    local match = storage.sil_filter_combinators[ui.unit]
    if not match then
        return
    end
    local data = storage.sil_fc_data[match]
    if not (data and data.config) then
        return
    end
    data.config.enabled = event.element.switch_state == "right"
    data.cc.get_or_create_control_behavior().enabled = data.config.enabled
    data.ex.get_or_create_control_behavior().enabled = data.config.enabled
    data.main.active = data.config.enabled
    data.main.custom_status = {diode = data.config.enabled and defines.entity_status_diode.green or defines.entity_status_diode.red, label = data.config.enabled and {'entity-status.working'} or {'entity-status.disabled'}}
    ui.ui.sil_fc_content.status_flow.status.caption = data.config.enabled and {'entity-status.working'} or {'entity-status.disabled'}
    ui.ui.sil_fc_content.status_flow.lamp.sprite = data.config.enabled and 'flib_indicator_green' or 'flib_indicator_red'
    update_entity(data)
end

--- @param event EventData.on_gui_switch_state_changed
local function on_switch_exclusive(event)
    local ui = storage.sil_fc_gui[event.player_index]
    if not ui then
        return
    end
    local match = storage.sil_filter_combinators[ui.unit]
    if not match then
        return
    end
    local data = storage.sil_fc_data[match]
    if not (data and data.config) then
        return
    end
    data.config.exclusive = event.element.switch_state == "right"
    update_entity(data)
end

--- @param event EventData.on_gui_checked_state_changed
local function on_switch_wire(event)
    local ui = storage.sil_fc_gui[event.player_index]
    if not ui then
        return
    end
    local match = storage.sil_filter_combinators[ui.unit]
    if not match then
        return
    end
    local data = storage.sil_fc_data[match]
    if not (data and data.config) then
        return
    end
    if event.element.name == "sil_fc_red_wire" then
        data.config.filter_input_wire = defines.wire_type.red
        ui.ui.sil_fc_content.sil_fc_row2.sil_fc_green_wire.state = not event.element.state
    elseif event.element.name == "sil_fc_green_wire" then
        data.config.filter_input_wire = defines.wire_type.green
        ui.ui.sil_fc_content.sil_fc_row2.sil_fc_red_wire.state = not event.element.state
    else
        return
    end
    update_entity(data)
end

--- @param event  EventData.on_gui_checked_state_changed
local function on_toggle_wire_mode(event)
    local ui = storage.sil_fc_gui[event.player_index]
    if not ui then
        return
    end
    local match = storage.sil_filter_combinators[ui.unit]
    if not match then
        return
    end
    local data = storage.sil_fc_data[match]
    if not (data and data.config) then
        return
    end
    -- ui.ui.sil_fc_content.sil_fc_row2.sil_fc_red_wire.enabled = event.element.state
    -- ui.ui.sil_fc_content.sil_fc_row2.sil_fc_green_wire.enabled = event.element.state
    data.config.filter_input_from_wire = event.element.state
    ui.ui.sil_fc_content.sil_fc_row3.visible = not event.element.state
    update_entity(data)
end

--- @param event EventData.on_gui_elem_changed
local function on_signal_selected(event)
    local ui = storage.sil_fc_gui[event.player_index]
    if not ui then
        return
    end
    if not event.element.tags then
        return
    end
    local match = storage.sil_filter_combinators[ui.unit]
    if not match then
        return
    end
    local data = storage.sil_fc_data[match]
    if not (data and data.config) then
        return
    end
    local signal = event.element.elem_value;
    local slot = event.element.tags.idx
    local behavior = data.cc.get_or_create_control_behavior()
    if behavior.sections_count < 1 then
        behavior.add_section()
    end
    local section = behavior.get_section(1)
    if signal then
        -- 2.0 errors out when setting the same signal twice, previously this was handled for us (probably by flib?)
        for i = 1, section.filters_count do
            local s = section.get_slot(i)
            if s and s.value and s.value.name == signal.name then
                section.clear_slot(slot)
                return
            end
        end
        section.set_slot(slot, {value = {comparator = "=", quality = "normal", name = signal.name, type = signal.type}, min = 1 })
    else
        section.clear_slot(slot)
    end
end

-- for some reason this shit ain't doing anything
flib_gui.add_handlers({
    on_window_closed = on_window_closed,
    on_switch_enabled = on_switch_enabled,
    on_switch_exclusive = on_switch_exclusive,
    on_switch_wire = on_switch_wire,
    on_toggle_wire = on_toggle_wire_mode,
    on_select_signal = on_signal_selected,
})
local handler = require("__core__.lualib.event_handler")
handler.add_lib(flib_gui)
flib_gui.handle_events()

--- @param cc LuaEntity
local function make_grid_buttons(cc)
    --- @type LuaConstantCombinatorControlBehavior
    local behavior = cc.get_or_create_control_behavior()
    local list = {}
    local empty_slot_count = 0
    if behavior.sections_count < 1 then
        behavior.add_section()
    end
    local section = behavior.get_section(1)
    local max_slots = #prototypes.item + #prototypes.fluid + #prototypes.virtual_signal

    -- For some reason it always is a table as big as the max signals supported... kinda unexpected but it works out I guess
    for i = 1, max_slots do
        local sig = section.get_slot(i)
        if (sig.value) then
            table.insert(list, {type = 'choose-elem-button', tags = {idx = i}, style = 'slot_button', elem_type = 'signal', signal = sig.value, handler = {[defines.events.on_gui_elem_changed] = on_signal_selected}})
        elseif empty_slot_count < settings.startup['sfc-empty-slots'].value or #list % 10 ~= 0 then
            empty_slot_count = empty_slot_count + 1
            table.insert(list, {type = 'choose-elem-button', tags = {idx = i}, style = 'slot_button', elem_type = 'signal', handler = {[defines.events.on_gui_elem_changed] = on_signal_selected}})
        end
    end
    return list
end


--- @param event EventData.on_gui_opened
local function onGuiOpen(event)
    if not (event.entity and event.entity.valid and event.entity.name == name_prefix) then
        -- some other GUI was opened, we don't care
        return
    end
    local player = game.players[event.player_index]
    local match = storage.sil_filter_combinators[event.entity.unit_number]
    if not match then
        log('Data missing for ' .. event.entity.name .. ' on ' .. event.entity.surface.name .. ' at ' .. serpent.line(event.entity.position) .. ' refusing to display UI')
        player.opened = nil
        return
    end
    destroy_gui(player)
    local data = storage.sil_fc_data[match]
    if not (data and data.cc and data.cc.valid) then
        player.opened = nil
        return
    end
    local slot_buttons = make_grid_buttons(data.cc)
    --- @type GuiElemDef
    local ui = {
        type = "frame",
        name = "sil_fc_filter_ui",
        direction  = "vertical",
        handler = { [defines.events.on_gui_closed] = on_window_closed },
        { -- Title Bar
            type = "flow",
            style = "flib_titlebar_flow",
            drag_target = "sil_fc_filter_ui",
            {
                type = "label",
                style = "frame_title",
                caption = {'entity-name.sil-filter-combinator'},
                drag_target = "sil_fc_filter_ui",
                ignored_by_interaction = true
            },
            {
                type = "empty-widget",
                style = "flib_titlebar_drag_handle",
                ignored_by_interaction = true
            },
            {
                type = "sprite-button",
                name = "sil_fc_close_button",
                style = "close_button",
                sprite = "utility/close",
                --hovered_sprite = "utility/close_black",
                --clicked_sprite = "utility/close_black",
                mouse_button_filter = { "left" },
                handler = { [defines.events.on_gui_click] = on_window_closed}
            }
        }, -- Title Bar End
        {
            type= "frame",
            style = "inside_shallow_frame_with_padding",
            name = "sil_fc_content",
            direction = "vertical",
            {
                type = "flow",
                style = "flib_indicator_flow",
                name = "status_flow",
                {
                    type = "sprite",
                    name = "lamp",
                    style = "flib_indicator",
                    sprite = data.config.enabled and "flib_indicator_green" or "flib_indicator_red"
                },
                {
                    type = "label",
                    style = "label",
                    name = "status",
                    caption = data.config.enabled and {'entity-status.working'} or {'entity-status.disabled'}
                }
            },
            { -- Add some spacing
                type = "frame",
                style = "invisible_frame",
                padding = 20,
            },
            {
                type = "frame",
                style = "deep_frame_in_shallow_frame",
                name = "preview_frame",
                {
                    type = "entity-preview",
                    name = "preview",
                    style = "wide_entity_button",
                }
            },
            { -- Add some spacing
                type = "frame",
                style = "invisible_frame",
                padding = 20,
            },
            {
                type = "frame",
                style = "invisible_frame",
                padding = 8,
                {
                    type = "label",
                    style = "semibold_label",
                    caption = {'gui-constant.output'},
                },
            },
            {
                type = "switch",
                switch_state = data.config.enabled and "right" or "left",
                right_label_caption = {'gui-constant.on'},
                left_label_caption = {'gui-constant.off'},
                handler = { [defines.events.on_gui_switch_state_changed] = on_switch_enabled},
            },
            { -- Add some spacing
                type = "frame",
                style = "invisible_frame",
                padding = 8,
            },
            {
                type = "frame",
                style = "invisible_frame",
                padding = 8,
                {
                    type = "label",
                    style = "semibold_label",
                    caption = {'sil-filter-combinator-gui.mode-heading'},
                },
            },
            {
                type = "switch",
                switch_state = data.config.exclusive and "right" or "left",
                right_label_caption = {'sil-filter-combinator-gui.mode-exclusive'},
                right_label_tooltip = {'sil-filter-combinator-gui.mode-exclusive-tooltip'},
                left_label_caption = {'sil-filter-combinator-gui.mode-inclusive'},
                left_label_tooltip = {'sil-filter-combinator-gui.mode-inclusive-tooltip'},
                handler = { [defines.events.on_gui_switch_state_changed] = on_switch_exclusive}
            },
            { -- Add some spacing
                type = "frame",
                style = "invisible_frame",
                padding = 8,
            },
            {
                type = "flow",
                name = "sil_fc_row2",
                direction = "horizontal",
                {
                    type = "checkbox",
                    caption = {'sil-filter-combinator-gui.mode-wire'},
                    name = "sil_fc_wire_content",
                    state = data.config.filter_input_from_wire,
                    handler = { [defines.events.on_gui_checked_state_changed] = on_toggle_wire_mode}
                },
                {
                    type = "radiobutton",
                    state = data.config.filter_input_wire == defines.wire_type.red,
                    -- enabled = data.config.filter_input_from_wire,
                    caption = {'item-name.red-wire'},
                    name = "sil_fc_red_wire",
                    handler = { [defines.events.on_gui_checked_state_changed] = on_switch_wire}
                },
                {
                    type = "radiobutton",
                    state = data.config.filter_input_wire == defines.wire_type.green,
                    -- enabled = data.config.filter_input_from_wire,
                    caption = {'item-name.green-wire'},
                    name = "sil_fc_green_wire",
                    handler = { [defines.events.on_gui_checked_state_changed] = on_switch_wire}
                }
            },
            { -- Just so we can hide this entire block in one go
                type = "flow",
                direction = "vertical",
                visible = not data.config.filter_input_from_wire,
                name = "sil_fc_row3",
                { -- Add some spacing
                    type = "frame",
                    style = "invisible_frame",
                    padding = 8,
                },
                {
                    type = "line",
                },
                {
                    type = "frame",
                    style = "invisible_frame",
                    padding = 8,
                    {
                        type = "label",
                        style = "semibold_label",
                        caption = {'sil-filter-combinator-gui.signals-heading'},
                    },
                },
                {
                    type = "scroll-pane",
                    style = "flib_shallow_scroll_pane",
                    name = "sil_fc_filter_section",
                    {
                        type = "frame",
                        style = "deep_frame_in_shallow_frame",
                        name = "frame",
                        {
                            type = "table",
                            name = "sil_fc_signal_container",
                            style = 'sil_signal_table',
                            -- style = "compact_slot_table", -- Best vanilla match, still too wide a gap
                            -- style = "slot_table", -- No real difference to the compact one?
                            -- style = "filter_slot_table", -- Correct but has light background instead of dark
                            -- style = "logistics_slot_table", -- Same as above
                            -- style = "filter_group_table", -- Kinda weird with dark in between some but not all?
                            -- style = "inset_frame_container_table", -- Massive gaps
                            -- style = "logistic_gui_table", -- even worse gaps. No idea where this is ever used
                            column_count = 10,
                            children = slot_buttons
                        },
                    }
                }
            }
        }
    }
    if not storage.sil_fc_gui then
        storage.sil_fc_gui = {}
    end
    local created = flib_gui.add(player.gui.screen, ui)
    created.sil_fc_filter_ui.auto_center = true
    created.sil_fc_content.preview_frame.preview.entity = data.main
    player.opened = created.sil_fc_filter_ui
    storage.sil_fc_gui[event.player_index] = {ui = created, unit = event.entity.unit_number}
end

--#endregion

local function onEntityPasted(event)
    local pl = game.get_player(event.player_index)
    if not pl or not pl.valid or pl.force ~= event.source.force or pl.force ~= event.destination.force then
        return
    end
    if event.source.name ~= name_prefix or event.destination.name ~= name_prefix then
        return
    end
    local dest_idx = storage.sil_filter_combinators[event.destination.unit_number]
    local source_idx = storage.sil_filter_combinators[event.source.unit_number]
    if not dest_idx or not source_idx then
        return
    end
    local src = storage.sil_fc_data[source_idx].cc
    local dst = storage.sil_fc_data[dest_idx].cc
    if src and src.valid and src.force == pl.force and dst and dst.valid and dst.force == pl.force then
        dst.copy_settings(src)
        storage.sil_fc_data[dest_idx].config = storage.sil_fc_data[source_idx].config
        update_entity(storage.sil_fc_data[dest_idx])
    end
end

--#region Blueprint and copy / paste support

--- @param bp LuaItemStack
local function save_to_blueprint(data, bp)
    if not data then
        log('save_to_blueprint: No Data')
        return false
    end
    if #data < 1 then
        log('save_to_blueprint: Empty Data')
        return false
    end
    if not bp then
        log('save_to_blueprint: no Blueprint')
        return false
    end
    if not bp or not bp.is_blueprint_setup() then
        log('save_to_blueprint: Blueprint not ready')
        return false
    end
    local entities = bp.get_blueprint_entities()
    if not entities or #entities < 1 then
        log('save_to_blueprint: No Entities in Blueprint: ' .. serpent.line(entities))
        return false
    end
    for _, unit in pairs(data) do
        local idx = storage.sil_filter_combinators[unit]
        --- @type LuaEntity
        local src = storage.sil_fc_data[idx].cc
        local main = storage.sil_fc_data[idx].main
        log('save_to_blueprint: cc unit=' .. src.unit_number .. ' main unit=' .. main.unit_number)
        --- @type LuaConstantCombinatorControlBehavior
        local behavior = src.get_or_create_control_behavior()
        for __, e in ipairs(entities) do
            -- Because LUA is a fucking useless piece of shit we cannot compare values that are tables... because you know why the fuck would you want to....
            -- if e.position == main.position then
            if e.position.x == main.position.x and e.position.y == main.position.y then
                local params = {}
                for i = 1, behavior.sections_count do
                    local sec = behavior.get_section(i)
                    if sec then
                        table.insert(params, sec.filters)
                    end
                end
                bp.set_blueprint_entity_tag(__, 'config', storage.sil_fc_data[idx].config)
                bp.set_blueprint_entity_tag(__, 'params', params)
                log('save_to_blueprint - Stored Config in blueprint:' .. serpent.line(storage.sil_fc_data[idx].config))
                log('save_to_blueprint - Stored Params in blueprint:' .. serpent.line(params))
                break
            else
                log('save_to_blueprint - Entity position mismatch: ' .. serpent.line(e.position) .. ' vs ' .. serpent.line(main.position))
            end
        end
    end
    return true
end

--- @param event EventData.on_player_setup_blueprint
local function onEntityCopy(event)
    if not event.area then
        log('onEntityCopy - no area selected')
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
        log('onEntityCopy - no filter combinators in seleection')
        return
    end
    if event.stack and event.stack.valid_for_read and event.stack.name == 'blueprint' and event.stack.is_blueprint_setup() then
        log('onEntityCopy - event stack is blueprint setup = ' .. serpent.line(event.stack.is_blueprint_setup()))
        save_to_blueprint(result, event.stack)
    elseif player.cursor_stack.valid_for_read and player.cursor_stack.name == 'blueprint' and player.cursor_stack.is_blueprint_setup() then
        log('onEntityCopy - is blueprint setup=' .. serpent.line(player.cursor_stack.is_blueprint_setup()))
        save_to_blueprint(result, player.cursor_stack)
    else
        -- Player is editing the blueprint, no access for us yet. Continue this in onBlueprintReady
        if not storage.sil_fc_blueprint_data then
            storage.sil_fc_blueprint_data = {}
        end
        if player then
            log('onEntityCopy - FAIL - has player')
            if storage.sil_fc_blueprint_data[event.player_index] then
                log('onEntityCopy - FAIL - has player cache data')
            end
            if player.cursor_stack then
                log('onEntityCopy - FAIL - has player.cursor_stack')
                if player.cursor_stack.valid_for_read then
                    log('onEntityCopy - FAIL - player cursor_stack is valid_for_read')
                    if player.cursor_stack.name == 'blueprint' then
                        log('onEntityCopy - FAIL - player cursor_stack is blueprint - is_blueprint_setup=' .. serpent.line(player.cursor_stack.is_blueprint_setup()))
                    end
                end
            end
        end
        storage.sil_fc_blueprint_data[event.player_index] = result
        log('onEntityCopy - Stored filter combinators in selection for player ' .. event.player_index)
    end
end

--- @param event EventData.on_player_configured_blueprint
local function onBlueprintReady(event)
    log('onBlueprintReady')
    if not storage.sil_fc_blueprint_data then
        storage.sil_fc_blueprint_data = {}
    end
    local player = game.players[event.player_index]
    local success = false
    if player and player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.name == 'blueprint' and storage.sil_fc_blueprint_data[event.player_index] then
        success = save_to_blueprint(storage.sil_fc_blueprint_data[event.player_index], player.cursor_stack)
        log('onBlueprintReady - saved success=' .. serpent.line(success))
    else
        log('onBlueprintReady - FAIL - missing player, player not holding blueprint, no player cached data or player stack not valid for reading')
        if player then
            log('onBlueprintReady - FAIL - has player')
            if storage.sil_fc_blueprint_data[event.player_index] then
                log('onBlueprintReady - FAIL - has player cache data')
            end
            if player.cursor_stack then
                log('onBlueprintReady - FAIL - has player.cursor_stack')
                if player.cursor_stack.valid_for_read then
                    log('onBlueprintReady - FAIL - player cursor_stack is valid_for_read')
                    if player.cursor_stack.name == 'blueprint' then
                        log('onBlueprintReady - FAIL - player cursor_stack is blueprint')
                    end
                end
            end
        end
    end
    if success and storage.sil_fc_blueprint_data[event.player_index] then
        storage.sil_fc_blueprint_data[event.player_index] = nil
        log('onBlueprintReady - removed cached data')
    end
end

--#endregion

--#region Compact Circuits Support

---@param entity LuaEntity
local function ccs_get_info(entity)
    if not entity or not entity.valid then
        return nil
    end
    local idx = storage.sil_filter_combinators[entity.unit_number]
    local data = storage.sil_fc_data[idx]
    if not data then
        return
    end
    ---@type LuaConstantCombinatorControlBehavior
    local behavior = data.cc.get_or_create_control_behavior()
    return {
        cc_config = data.config,
        cc_params = behavior.parameters
    }
end

--- @param ent LuaEntity?
local function ccs_handle_spawned(ent, info)
    if ent and ent.valid then
        onEntityCreated({entity = ent})
        local idx = storage.sil_filter_combinators[ent.unit_number]
        local data = storage.sil_fc_data[idx]
        data.config = info.cc_config
        ---@type LuaConstantCombinatorControlBehavior
        local behavior = data.cc.get_or_create_control_behavior()
        behavior.parameters = info.cc_params
        behavior.enabled = data.config.enabled
        data.ex.get_or_create_control_behavior().enabled = data.config.enabled
        update_entity(data)
    end
end

---@param surface LuaSurface
---@param position MapPosition
---@param force LuaForce
local function ccs_create_packed_entity(info, surface, position, force)
    local ent = surface.create_entity{name = name_prefix .. '-packed', position = position, force = force, direction = info.direction, raise_built = false}
    ccs_handle_spawned(ent, info)
    return ent
end

---@param surface LuaSurface
---@param force LuaForce
local function ccs_create_entity(info, surface, force)
    local ent = surface.create_entity{name = name_prefix, position = info.position, force = force, direction = info.direction, raise_built = false}
    ccs_handle_spawned(ent, info)
    return ent
end

--#endregion

local function cleanup_for_missing_main()
    if not storage.sil_fc_data then
        return
    end
    for _, data in pairs(storage.sil_fc_data) do
        if data and not (data.main and data.main.valid) then
            log('Missing main entity - killing internal entities')
            kill_internal_entities(data)
            storage.sil_fc_data[_] = nil
        end
    end
end

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

--- @param changed ConfigurationChangedData
local function on_configuration_changed(changed)
    if changed.mod_changes['silent-filter-combinator'] and changed.mod_changes['silent-filter-combinator'].new_version == '1.0.0' then
        -- Apply second stage of migration
        for _, mig in pairs(storage.sil_fc_migration_data) do
            if mig.ent and mig.con then
                local _, ent, __ = mig.ent.silent_revive{raise_revive = true}
                if ent then
                    for _, con in pairs(mig.con) do
                        ent.connect_neighbour(con)
                    end
                else
                    log('Failed to revive ghost on ' .. mig.ent.surface.name .. ' at ' .. serpent.line(mig.ent.position))
                end
            end
        end
        storage.sil_fc_migration_data = nil
    else
        storage.sil_fc_slot_error_logged = false
        log('Checking for missing main entities and cleaning up leftovers...')
        cleanup_for_missing_main()
        log('Updating for potentially changed signals...')
        for _, data in pairs(storage.sil_fc_data) do
            if data and data.ex and data.ex.valid then
                set_all_signals(data.ex)
            end
        end
    end
end

script.on_event(defines.events.on_runtime_mod_setting_changed, onRTSettingChanged)

script.on_event(defines.events.on_gui_opened, onGuiOpen)
script.on_event({defines.events.on_pre_player_mined_item, defines.events.on_robot_pre_mined, defines.events.on_entity_died, defines.events.script_raised_destroy}, onEntityDeleted)
script.on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity, defines.events.script_raised_revive, defines.events.script_raised_built}, onEntityCreated)
script.on_event(defines.events.on_entity_cloned, onEntityCloned)
script.on_event(defines.events.on_entity_settings_pasted, onEntityPasted)

script.on_event(defines.events.on_player_setup_blueprint, onEntityCopy)
script.on_event(defines.events.on_player_configured_blueprint, onBlueprintReady)

script.on_init(function()
    if not storage.sil_filter_combinators then
        storage.sil_filter_combinators = {}
    end
    if not storage.sil_fc_data then
        --- @type FilterCombinatorData[]
        storage.sil_fc_data = {}
    end
    initCompat()
end)

script.on_load(function()
    initCompat()
end)

script.on_configuration_changed(on_configuration_changed)

--- @class FilterCombinatorConfig
--- @field enabled boolean Whether this filter combinator is active
--- @field filter_input_from_wire boolean Whether the signals on the specified wire are used as a filter input
--- @field filter_input_wire defines.wire_type The wire that speficies the signals to filter from the other wire
--- @field exclusive boolean Whether this filter combinator is running in exclusive mode

--- @class FilterCombinatorData
--- @field main LuaEntity
--- @field cc LuaEntity
--- @field calc LuaEntity[]
--- @field ex LuaEntity
--- @field inv LuaEntity
--- @field input_pos LuaEntity
--- @field input_neg LuaEntity
--- @field filter LuaEntity
--- @field inp LuaEntity
--- @field config FilterCombinatorConfig
