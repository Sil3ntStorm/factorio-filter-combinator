-- Copyright 2023 Sil3ntStorm https://github.com/Sil3ntStorm
--
-- Licensed under MS-RL, see https://opensource.org/licenses/MS-RL

require('__core__/lualib/util.lua')

require('prototypes/hidden-constant.lua')
require('prototypes/hidden-combinators.lua')
require('prototypes/filter.lua')

local item = table.deepcopy(data.raw.item['arithmetic-combinator'])
item.name = 'sil-filter-combinator'
item.place_result = item.name
item.icon = '__silent-filter-combinator__/graphics/filter-combinator.png'
item.flags = {'mod-openable'}
item.order = 'c[combinators]-b[filter-combinator]'

local recipe = table.deepcopy(data.raw.recipe['arithmetic-combinator'])
recipe.name = item.name
recipe.result = item.name
recipe.order = item.order
if mods['nullius'] then
    recipe.name = 'sil-filter-combinator'
    recipe.ingredients = {{'copper-cable', 5}, {'decider-combinator', 2}}
    recipe.group = 'logistics'
    recipe.category = 'tiny-crafting'
    recipe.order = 'nullius-fa'
end

data:extend{item, recipe}

table.insert(data.raw['technology']['circuit-network'].effects, { type = 'unlock-recipe', recipe = recipe.name })
if mods['nullius'] then
    table.insert(data.raw['technology']['nullius-computation'].effects, { type = 'unlock-recipe', recipe = recipe.name })
end
