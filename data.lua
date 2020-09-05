local function copyPrototype(type, name, newName)
  if not data.raw[type][name] then error("type "..type.." "..name.." doesn't exist") end
  local p = table.deepcopy(data.raw[type][name])
  p.name = newName
  if p.minable and p.minable.result then
    p.minable.result = newName
  end
  if p.place_result then
    p.place_result = newName
  end
  if p.result then
    p.result = newName
  end
  if p.results then
		for _,result in pairs(p.results) do
			if result.name == name then
				result.name = newName
			end
		end
	end
  return p
end

local function makeBotShots(prefix)
  local botshots_gun = copyPrototype("gun","artillery-wagon-cannon",prefix.."-cannon")
  botshots_gun.attack_parameters.ammo_category = prefix.."-shell"

  local botshots_turret = copyPrototype("artillery-turret","artillery-turret",prefix.."-turret")
  botshots_turret.gun = botshots_gun.name
  botshots_turret.disable_automatic_firing = true
  botshots_turret.collision_box = {{-1.45, -1.45}, {1.45, 0.9}}

  local botshots_turret_item = copyPrototype("item","artillery-turret",prefix.."-turret")

  local botshots_remote = copyPrototype("capsule","artillery-targeting-remote",prefix.."-targeting-remote")
  botshots_remote.capsule_action.flare = prefix.."-flare"

  local botshots_flare = copyPrototype("artillery-flare","artillery-flare",prefix.."-flare")
  botshots_flare.shot_category = prefix.."-shell"

  local artytecheffects = data.raw["technology"]["artillery"].effects

  artytecheffects[#artytecheffects+1] = { type = "unlock-recipe", recipe = prefix.."-cannon" }
  artytecheffects[#artytecheffects+1] = { type = "unlock-recipe", recipe = prefix.."-shell" }
  artytecheffects[#artytecheffects+1] = { type = "unlock-recipe", recipe = prefix.."-targeting-remote" }


  data:extend({
    {
      type = "ammo-category",
      name = prefix.."-shell"
    },
    botshots_gun,
    botshots_turret,
    botshots_turret_item,
    botshots_remote,
    botshots_flare,
    {
      type = "ammo",
      name = prefix.."-shell",
      icon = "__base__/graphics/icons/artillery-shell.png",
      icon_size = 64, icon_mipmaps = 4,
      ammo_type =
      {
        category = prefix.."-shell",
        target_type = "position",
        action =
        {
          type = "direct",
          action_delivery =
          {
            type = "artillery",
            projectile = prefix.."-projectile",
            starting_speed = 1,
            direction_deviation = 0,
            range_deviation = 0,
            trigger_fired_artillery = true,
            source_effects =
            {
              type = "create-explosion",
              entity_name = "artillery-cannon-muzzle-flash"
            },
          }
        },
      },
      subgroup = "ammo",
      order = "d[explosive-cannon-shell]-r[roboshell]",
      stack_size = 1
    },
  }
  )
end


-- and make the normal remote exclusive to normal shots
data.raw["artillery-flare"]["artillery-flare"].shot_category = "artillery-shell"

--TODO: rename things with bumble bots, use locale prefix "beeshots"
makeBotShots("botshots")
makeBotShots("spidershots")

local botshots_chest = copyPrototype("container","steel-chest","botshots-chest")
botshots_chest.collision_box = {{-1.45,  0.0}, {1.45, 0.4}}

local botshots_chest_item = copyPrototype("item","steel-chest","botshots-chest")

local botshots_roboport = copyPrototype("roboport","roboport","botshots-roboport")
botshots_roboport.minable = nil
botshots_roboport.order = "foo"
botshots_roboport.energy_source = {type="void"}

local botshots_radar = copyPrototype("radar","radar","botshots-radar")
botshots_radar.minable = nil
botshots_radar.order = "foo"
botshots_radar.energy_source = {type="void"}


data:extend{
  botshots_chest,
  botshots_chest_item,
  botshots_roboport,
  botshots_radar,
  -- botshots recipes
  {
    type = "recipe",
    name = "botshots-cannon",
    enabled = "false",
    ingredients =
    {
      {"artillery-turret", 1},
      {"roboport", 1},
    },
    energy_required = 10,
    result="botshots-turret",
  },
  {
    type = "recipe",
    name = "botshots-shell",
    enabled = "false",
    ingredients =
    {
      {"construction-robot", 2},
      {"logistic-robot", 2},
      {"cannon-shell", 4},
      {"roboport", 1},
      {"radar", 1},
    },
    energy_required = 15,
    result="botshots-shell",
  },
  {
    type = "recipe",
    name = "botshots-targeting-remote",
    enabled = "false",
    ingredients =
    {
      {"processing-unit", 1},
      {"roboport", 1},
    },
    result="botshots-targeting-remote",
  },

  -- spidershots recipes
  {
    type = "recipe",
    name = "spidershots-cannon",
    enabled = "false",
    ingredients =
    {
      {"artillery-turret", 1},
      {"spidertron-remote", 1},
    },
    energy_required = 10,
    result="spidershots-turret",
  },
  {
    type = "recipe",
    name = "spidershots-shell",
    enabled = "false",
    ingredients =
    {
      {"spidertron", 1},
      {"cannon-shell", 4},
    },
    energy_required = 15,
    result="spidershots-shell",
  },
  {
    type = "recipe",
    name = "spidershots-targeting-remote",
    enabled = "false",
    ingredients =
    {
      {"processing-unit", 1},
      {"spidertron-remote", 1},
    },
    result="spidershots-targeting-remote",
  },

  -- projectiles
  {
    type = "artillery-projectile",
    name = "botshots-projectile",
    flags = {"not-on-map"},
    acceleration = 0,
    direction_only = true,
    reveal_map = true,
    map_color = {r=0, g=0, b=1},
    picture =
    {
      filename = "__base__/graphics/entity/artillery-projectile/hr-shell.png",
      width = 64,
      height = 64,
      scale = 0.5,
    },
    shadow =
    {
      filename = "__base__/graphics/entity/artillery-projectile/hr-shell-shadow.png",
      width = 64,
      height = 64,
      scale = 0.5,
    },
    chart_picture =
    {
      filename = "__base__/graphics/entity/artillery-projectile/artillery-shoot-map-visualization.png",
      flags = { "icon" },
      frame_count = 1,
      width = 64,
      height = 64,
      priority = "high",
      scale = 0.25,
    },
    action =
    {
      type = "direct",
      action_delivery =
      {
        type = "instant",
        target_effects =
        {
          {
            type = "create-trivial-smoke",
            smoke_name = "artillery-smoke",
            initial_height = 0,
            speed_from_center = 0.05,
            speed_from_center_deviation = 0.005,
            offset_deviation = {{-4, -4}, {4, 4}},
            max_radius = 3.5,
            repeat_count = 4 * 4 * 15
          },
          {
            type = "create-entity",
            entity_name = "botshots-roboport",
            check_buildability = false,
            trigger_created_entity = true
          },
          {
            type = "create-entity",
            entity_name = "construction-robot",
            check_buildability = false,
            offset_deviation = {{-4, -4}, {4, 4}},
            repeat_count = 2
          },
          {
            type = "create-entity",
            entity_name = "logistic-robot",
            check_buildability = false,
            offset_deviation = {{-4, -4}, {4, 4}},
            repeat_count = 2
          }
        }
      }
    },
    final_action =
    {
      type = "direct",
      action_delivery =
      {
        type = "instant",
        target_effects =
        {
          {
            type = "create-entity",
            entity_name = "small-scorchmark",
            check_buildability = true
          }
        }
      }
    },
    animation =
    {
      filename = "__base__/graphics/entity/bullet/bullet.png",
      frame_count = 1,
      width = 3,
      height = 50,
      priority = "high"
    },
    height_from_ground = 280 / 64
  },
  {
    type = "artillery-projectile",
    name = "spidershots-projectile",
    flags = {"not-on-map"},
    acceleration = 0,
    direction_only = true,
    reveal_map = true,
    map_color = {r=0, g=0, b=1},
    picture =
    {
      filename = "__base__/graphics/entity/artillery-projectile/hr-shell.png",
      width = 64,
      height = 64,
      scale = 0.5,
    },
    shadow =
    {
      filename = "__base__/graphics/entity/artillery-projectile/hr-shell-shadow.png",
      width = 64,
      height = 64,
      scale = 0.5,
    },
    chart_picture =
    {
      filename = "__base__/graphics/entity/artillery-projectile/artillery-shoot-map-visualization.png",
      flags = { "icon" },
      frame_count = 1,
      width = 64,
      height = 64,
      priority = "high",
      scale = 0.25,
    },
    action =
    {
      type = "direct",
      action_delivery =
      {
        type = "instant",
        target_effects =
        {
          {
            type = "create-trivial-smoke",
            smoke_name = "artillery-smoke",
            initial_height = 0,
            speed_from_center = 0.05,
            speed_from_center_deviation = 0.005,
            offset_deviation = {{-4, -4}, {4, 4}},
            max_radius = 3.5,
            repeat_count = 4 * 4 * 15
          },
          {
            type = "create-entity",
            entity_name = "spidertron",
            check_buildability = false,
            trigger_created_entity = true
          },
        }
      }
    },
    final_action =
    {
      type = "direct",
      action_delivery =
      {
        type = "instant",
        target_effects =
        {
          {
            type = "create-entity",
            entity_name = "small-scorchmark",
            check_buildability = true
          }
        }
      }
    },
    animation =
    {
      filename = "__base__/graphics/entity/bullet/bullet.png",
      frame_count = 1,
      width = 3,
      height = 50,
      priority = "high"
    },
    height_from_ground = 280 / 64
  },
}