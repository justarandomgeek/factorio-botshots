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
  if shell.name == "botshots-projectile" and cannon.name == "botshots-turret" then
    game.print("cannon " .. cannon.name .. " " .. cannon.unit_number .. " fired shell " .. shell.name)

    -- disable this cannon until the shot hits, to keep it to one each.
    -- Without actually tracking the projectile itself there's no way to keep them in-order for concurrent shots to varied ranges
    cannon.active = false

    local chestinv = global.cannons[cannon.unit_number].chest.get_inventory(defines.inventory.chest)
    global.shells[cannon.unit_number] = {
      items = chestinv.get_contents()
    }
    chestinv.clear()

  end
end)

script.on_event(defines.events.on_trigger_created_entity, function(event)
  local entity = event.entity
  local cannon = event.source
  if entity.name == "botshots-roboport" and cannon.name == "botshots-turret" then
    -- grab the roboport, build the radar and chest, record them all along with tick to expire
    game.print("cannon " .. cannon.name .. " " .. cannon.unit_number .. " created roboport " .. entity.unit_number)


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

    for name,count in pairs(global.shells[cannon.unit_number].items) do
        chest.insert{name=name,count=count}
    end

    global.shells[cannon.unit_number] = nil
    cannon.active = true

    local expire = game.tick + (60 * 60 * 1)
    local outpost = {
      roboport=entity,
      radar=radar,
      chest=chest,
    }

    global.outposts_expire[expire] = global.outposts_expire[expire] or {}
    global.outposts_expire[expire][#global.outposts_expire[expire]+1] = entity.unit_number
    global.outposts[entity.unit_number] = outpost
  end
end)

script.on_event(defines.events.on_tick, function()
  if global.outposts_expire[game.tick] then
    for _,id in pairs(global.outposts_expire[game.tick]) do

      local outpost = global.outposts[id]
      if outpost then
        global.outposts[outpost.roboport.unit_number] = nil
        --TODO: save the robots? launch them or transferto chest?
        -- morethan iniital bots may have parked here, if fired in range of an existing network for resupply
        outpost.roboport.destroy()
        outpost.radar.destroy()

        outpost.chest.operable = true
        outpost.chest.minable = true
        outpost.chest.destructible = true
      end
    end
    global.outposts_expire[game.tick] = nil
  end
end)

script.on_event({defines.events.on_robot_built_entity,defines.events.on_built_entity}, function(event)
  local entity = event.created_entity
  if entity.name == "botshots-turret" then
    local chest = entity.surface.create_entity{
        name='steel-chest',
        position = {entity.position.x,entity.position.y+1},
        force = entity.force
      }

    chest.minable=false
    chest.destructible = false

    global.cannons[entity.unit_number] = {
      cannon = entity,
      chest = chest,

    }
  end
end)
script.on_event({defines.events.on_robot_mined_entity,defines.events.on_player_mined_entity}, function(event)
  local entity = event.entity
  if entity.name == "botshots-turret" then
    for name,count in pairs(global.cannons[entity.unit_number].chest.get_inventory(defines.inventory.chest).get_contents()) do
      event.buffer.insert{name=name,count=count}
    end
    global.cannons[entity.unit_number].chest.destroy()
    global.cannons[entity.unit_number] = nil

  end
end)
script.on_event(defines.events.on_entity_died, function(event)
  local entity = event.entity
  if entity.name == "botshots-roboport" then
    local outpost = global.outposts[entity.unit_number]
    global.outposts[entity.unit_number] = nil
    outpost.radar.destroy()
    outpost.chest.destroy()

  elseif entity.name == "botshots-turret" then
    global.cannons[entity.unit_number].chest.destroy()
    global.cannons[entity.unit_number] = nil
  end
end)
