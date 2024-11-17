for _, surface in pairs(game.surfaces) do
    if surface.platform then
        local ents = surface.find_entities_filtered{name='sil-filter-combinator'}
        for _, ent in pairs(ents) do
            local pos = ent.position
            local force = ent.force
            local quality = ent.quality
            if ent.order_deconstruction(ent.force) then
                local replaced = surface.create_entity{name='entity-ghost', position = pos, force = force, inner_name = 'sil-filter-combinator', quality = quality}
                log('created replacement: ' .. serpent.line(replaced))
            end
        end
    end
end
