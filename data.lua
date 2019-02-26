function copyPrototype(type, name, newName)
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


botshots_gun = copyPrototype("gun","artillery-wagon-cannon","botshots-cannon")
botshots_gun.attack_parameters.ammo_category = "botshots-shell"

botshots_turret = copyPrototype("artillery-turret","artillery-turret","botshots-turret")
botshots_turret.gun = botshots_gun.name
botshots_turret.disable_automatic_firing = true

botshots_turret_item = copyPrototype("item","artillery-turret","botshots-turret")


botshots_roboport = copyPrototype("roboport","roboport","botshots-roboport")
botshots_roboport.minable = nil
botshots_roboport.order = "foo"
botshots_roboport.energy_source = {type="void"}

botshots_radar = copyPrototype("radar","radar","botshots-radar")
botshots_radar.minable = nil
botshots_radar.order = "foo"
botshots_radar.energy_source = {type="void"}

botshots_remote = copyPrototype("capsule","artillery-targeting-remote","botshots-targeting-remote")
botshots_remote.capsule_action.flare = "botshots-flare"

botshots_flare = copyPrototype("artillery-flare","artillery-flare","botshots-flare")
botshots_flare.shot_category = "botshots-shell"

-- and make the normal remote exclusive to normla shots
data.raw["artillery-flare"]["artillery-flare"].shot_category = "artillery-shell"


data:extend({
  {
    type = "ammo-category",
    name = "botshots-shell"
  },
  {
    type = "recipe",
    name = "botshots-cannon",
    enabled = "true",
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
    enabled = "true",
    ingredients =
    {
      {"construction-robot", 5},
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
    enabled = "true",
    ingredients =
    {
      {"processing-unit", 1},
      {"roboport", 1},
    },
    result="botshots-targeting-remote",
  },
  botshots_gun,
  botshots_turret,
  botshots_turret_item,
  botshots_roboport,
  botshots_radar,
  botshots_remote,
  botshots_flare,
  {
    type = "ammo",
    name = "botshots-shell",
    icon = "__base__/graphics/icons/artillery-shell.png",
    icon_size = 32,
    ammo_type =
    {
      category = "botshots-shell",
      target_type = "position",
      action =
      {
        type = "direct",
        action_delivery =
        {
          type = "artillery",
          projectile = "botshots-projectile",
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
            repeat_count = 5
          },
          {
            type = "create-entity",
            entity_name = "logistic-robot",
            check_buildability = false,
            offset_deviation = {{-4, -4}, {4, 4}},
            repeat_count = 5
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
}
)
