-- Copyright 2023 Sil3ntStorm https://github.com/Sil3ntStorm
--
-- Licensed under MS-RL, see https://opensource.org/licenses/MS-RL

local comb = table.deepcopy(data.raw['arithmetic-combinator']['arithmetic-combinator'])
local sprite = {
    filename = '__silent-filter-combinator__/graphics/filter-combinator-display.png',
    width = 15,
    height = 11,
    scale = comb.and_symbol_sprites.north.scale,
    shift = comb.and_symbol_sprites.north.shift,
    hr_version = {
        filename = '__silent-filter-combinator__/graphics/hr-filter-combinator-display.png',
        width = 30,
        height = 22,
        scale = comb.and_symbol_sprites.north.hr_version.scale,
        shift = comb.and_symbol_sprites.north.hr_version.shift
    }
}
local sprite_v = {
    filename = '__silent-filter-combinator__/graphics/filter-combinator-display.png',
    width = 15,
    height = 11,
    scale = comb.and_symbol_sprites.east.scale,
    shift = comb.and_symbol_sprites.east.shift,
    hr_version = {
        filename = '__silent-filter-combinator__/graphics/hr-filter-combinator-display.png',
        width = 30,
        height = 22,
        scale = comb.and_symbol_sprites.east.hr_version.scale,
        shift = comb.and_symbol_sprites.east.hr_version.shift
    }
}
local full_sprite = { east = sprite_v, west = sprite_v, north = sprite, south = sprite }

comb.name = 'sil-filter-combinator'
comb.minable.result = comb.name
comb.circuit_wire_max_distance = 20
comb.and_symbol_sprites = full_sprite
comb.divide_symbol_sprites = full_sprite
comb.left_shift_symbol_sprites = full_sprite
comb.minus_symbol_sprites = full_sprite
comb.modulo_symbol_sprites = full_sprite
comb.multiply_symbol_sprites = full_sprite
comb.or_symbol_sprites = full_sprite
comb.plus_symbol_sprites = full_sprite
comb.power_symbol_sprites = full_sprite
comb.right_shift_symbol_sprites = full_sprite
comb.xor_symbol_sprites = full_sprite

data:extend{comb}

if mods['compaktcircuit'] then
    local packed = table.deepcopy(comb)
    packed.name = 'sil-filter-combinator-packed'
    packed.flags = {'placeable-off-grid', 'not-repairable', 'not-on-map', 'not-deconstructable', 'not-blueprintable', 'hidden', 'hide-alt-info', 'not-flammable', 'no-copy-paste', 'not-selectable-in-game', 'not-upgradable', 'not-in-kill-statistics', 'not-in-made-in'}
    packed.draw_circuit_wires = false
    packed.collision_box = nil
    packed.selection_box = nil
    packed.sprites = util.empty_sprite(1)
    packed.collision_mask = {}
    packed.minable = nil
    packed.selectable_in_game = false
    packed.activity_led_light_offsets = { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    packed.activity_led_sprites = util.empty_sprite(1)
    packed.and_symbol_sprites = util.empty_sprite(1)
    packed.divide_symbol_sprites = util.empty_sprite(1)
    packed.left_shift_symbol_sprites = util.empty_sprite(1)
    packed.minus_symbol_sprites = util.empty_sprite(1)
    packed.modulo_symbol_sprites = util.empty_sprite(1)
    packed.multiply_symbol_sprites = util.empty_sprite(1)
    packed.or_symbol_sprites = util.empty_sprite(1)
    packed.plus_symbol_sprites = util.empty_sprite(1)
    packed.power_symbol_sprites = util.empty_sprite(1)
    packed.right_shift_symbol_sprites = util.empty_sprite(1)
    packed.xor_symbol_sprites = util.empty_sprite(1)

    -- turn off the flashing icons when part of a compaktcircuit. This is visible when
    -- a packed cc is not powered.
    local energy_source = table.deepcopy(comb.energy_source)
    energy_source.render_no_network_icon = false
    energy_source.render_no_power_icon = false
    packed.energy_source = energy_source

    data:extend{packed}
end
