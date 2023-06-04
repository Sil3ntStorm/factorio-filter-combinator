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
