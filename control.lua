script.on_init(function()
  global = {

    -- outposts_expire[expiretick]={ {roboport=roboport,radar=radar,chest=chest}, ... }
    outposts_expire = {},
    -- outposts[roboport.unit_number]={roboport=roboport,radar=radar,chest=chest}
    outposts = {},

    -- cannons [turret.unit_number] = {cannon = cannon, chest=chest}
    cannons = { },

    -- shells currently in-flight, indexed by cannon's unit_number
    -- [unit_number] = {items = { [name]=count, ... } }
    shells = {},
  }
end)

script.on_event(defines.events.on_trigger_fired_artillery, function(event)
  local shell = event.entity
  local cannon = event.source
  if not cannon then return end
  if shell.name == "botshots-projectile" and cannon.name == "botshots-turret" or
    shell.name == "spidershots-projectile" and cannon.name == "spidershots-turret" then
    -- disable this cannon until the shot hits, to keep it to one each.
    -- Without actually tracking the projectile itself there's no way to keep them in-order for concurrent shots to varied ranges
    cannon.active = false

    local chestinv = global.cannons[cannon.unit_number].chest.get_inventory(defines.inventory.chest)
    local size = #chestinv
    local inv = game.create_inventory(size)
    for i = 1, size do
      local slot = chestinv[i]
      if slot.valid_for_read then
        inv[i].set_stack(slot)
      end
    end
    global.shells[cannon.unit_number] = {
      inv = inv,
    }
    chestinv.clear()
  end
end)

script.on_event(defines.events.on_trigger_created_entity, function(event)
  local entity = event.entity
  local cannon = event.source
  if not cannon then return end
  if entity.name == "botshots-roboport" and cannon.name == "botshots-turret" then
    -- grab the roboport, build the radar and chest, record them all along with tick to expire
    entity.minable=false
    entity.operable=false

    local radar = entity.surface.create_entity{
        name='botshots-radar',
        position = {entity.position.x+.5 ,entity.position.y-1.5},
        force = entity.force
      }

    radar.operable=false
    radar.minable=false
    radar.destructible = false

    local chest = entity.surface.create_entity{
        name='logistic-chest-storage',
        position = {entity.position.x-1.5,entity.position.y-2.5},
        force = entity.force
      }

    chest.minable=false
    chest.destructible = false

    local shells = global.shells
    local shell = shells[cannon.unit_number]
    local inv = shell.inv
    if inv and inv.valid then
      for i = 1,#inv do
        local slot = inv[i]
        if slot.valid_for_read then
          local name = slot.name
          if name == 'logistic-robot' or name == 'construction-robot' then
            entity.insert(slot)
          else
            chest.insert(slot)
          end
        end
      end
    end

    global.shells[cannon.unit_number] = nil
    cannon.active = true

    local expire = game.tick + (60 * 60 * 1)
    local outpost = {
      roboport=entity,
      radar=radar,
      chest=chest,
    }

    local outposts_expire = global.outposts_expire
    outposts_expire[expire] = outposts_expire[expire] or {}
    outposts_expire[expire][#outposts_expire[expire]+1] = entity.unit_number
    global.outposts[entity.unit_number] = outpost
  elseif entity.name == "spidertron" and cannon.name == "spidershots-turret" then
    local shells = global.shells
    local shell = shells[cannon.unit_number]
    local inv = shell.inv
    local grid = entity.grid
    if inv and inv.valid then
      for i = 1,#inv do
        local slot = inv[i]
        if slot.valid_for_read then
          local equip = slot.prototype.place_as_equipment_result
          if equip then
            for j = 1,slot.count do
              if not grid.put{name=equip.name} then
                break
              end
              slot.count = slot.count - 1
              if not slot.valid_for_read then
                goto nextslot
              end
            end
          end
          entity.insert(slot)
        end
        ::nextslot::
      end
    end

    shells[cannon.unit_number] = nil
    cannon.active = true
  end
end)

script.on_event(defines.events.on_tick, function()
  local outposts_expire = global.outposts_expire
  local outposts_expiring = outposts_expire[game.tick]
  if outposts_expiring then
    for _,id in pairs(outposts_expiring) do

      local outpost = global.outposts[id]
      if outpost then
        global.outposts[id] = nil
        --TODO: save the robots? launch them or transferto chest?
        -- morethan iniital bots may have parked here, if fired in range of an existing network for resupply
        if outpost.roboport.valid then outpost.roboport.destroy() end
        if outpost.radar.valid then outpost.radar.destroy() end

        if outpost.chest.valid then
          outpost.chest.operable = true
          outpost.chest.minable = true
          outpost.chest.destructible = true
        end
      end
    end
    global.outposts_expire[game.tick] = nil
  end
end)

local function onBuilt(entity)
  if entity.name == "botshots-turret" or entity.name == "spidershots-turret" then
    local position = {entity.position.x,entity.position.y+1}
    local chest = entity.surface.find_entity('entity-ghost', position)
    if chest then
      _,chest = chest.revive()
    else
      chest = entity.surface.find_entity('botshots-chest', position) or
        entity.surface.create_entity{
          name='botshots-chest',
          position = position,
          force = entity.force
        }
    end

    chest.minable=false
    chest.destructible = false

    global.cannons[entity.unit_number] = {
      cannon = entity,
      chest = chest,
    }
  end
end

script.on_event({defines.events.on_robot_built_entity,defines.events.on_built_entity}, function(event) onBuilt(event.created_entity) end)
script.on_event(defines.events.on_entity_cloned, function(event) onBuilt(event.destination) end)
script.on_event(defines.events.script_raised_built, function(event) onBuilt(event.entity) end)
script.on_event(defines.events.script_raised_revive, function(event) onBuilt(event.entity) end)

script.on_event({defines.events.on_robot_mined_entity,defines.events.on_player_mined_entity}, function(event)
  local entity = event.entity
  if entity.name == "botshots-turret" or entity.name == "spidershots-turret" then
    local chest = global.cannons[entity.unit_number].chest
    if chest.valid then
      for name,count in pairs(chest.get_inventory(defines.inventory.chest).get_contents()) do
        event.buffer.insert{name=name,count=count}
      end
      chest.destroy()
    end
    global.cannons[entity.unit_number] = nil
  end
end)
script.on_event(defines.events.on_entity_died, function(event)
  local entity = event.entity
  if entity.name == "botshots-roboport" then
    local outpost = global.outposts[entity.unit_number]
    global.outposts[entity.unit_number] = nil
    if outpost.radar.valid then outpost.radar.destroy() end
    if outpost.chest.valid then outpost.chest.destroy() end

  elseif entity.name == "botshots-turret" or entity.name == "spidershots-turret" then
    local chest = global.cannons[entity.unit_number].chest
    if chest.valid then chest.destroy() end
    global.cannons[entity.unit_number] = nil
  end
end)
