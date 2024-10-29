local constants = require "src.constants"
local Paths = require "src.Paths"
local Hotkeys = require "src.Hotkeys"

local M = {}

function M.main()
  M.add_network_chest()
  M.add_loader()
  M.add_network_tank()
  M.add_network_sensor()

  data:extend(Hotkeys.hotkeys)
end

function M.add_network_chest()
  local name = "network-chest"
  local override_item_name = "iron-chest"
  local overwrite_prototype = "container"

  local entity = table.deepcopy(data.raw[overwrite_prototype][override_item_name])
  entity.name = name
  entity.picture = {
    filename = Paths.graphics .. "/entities/network-chest.png",
    size = 64,
    scale = 0.5,
  }
  entity.inventory_size = constants.NUM_INVENTORY_SLOTS
  entity.inventory_type = "with_filters_and_bar"
  entity.minable.result = name

  -- Add new fields if required by Factorio 2.0
  entity.circuit_wire_connection_points = data.raw[overwrite_prototype][override_item_name].circuit_wire_connection_points or {}
  entity.circuit_connector_sprites = data.raw[overwrite_prototype][override_item_name].circuit_connector_sprites or {}
  entity.circuit_wire_max_distance = data.raw[overwrite_prototype][override_item_name].circuit_wire_max_distance or 0

  local item = table.deepcopy(data.raw["item"][override_item_name])
  item.name = name
  item.place_result = name
  item.icon = Paths.graphics .. "/items/network-chest.png"
  item.icon_size = 64

  local recipe = {
    name = name,
    type = "recipe",
    enabled = true,
    energy_required = 0.5,
    ingredients = {},
    results = {{type="item",name=name,amount=1}},
  }

  data:extend({ entity, item, recipe })
end

function M.add_loader()
  local name = "network-loader"

  local entity = {
    name = "network-loader",
    type = "loader-1x1",
    icon = Paths.graphics .. "/entities/express-loader.png",
    icon_size = 64,
    flags = { "placeable-neutral", "player-creation" },
    minable = {
      mining_time = 0.2,
      result = "network-loader",
    },
    max_health = 300,
    corpse = "small-remnants",
    collision_box = { { -0.4, -0.45 }, { 0.4, 0.45 } },
    selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
    drawing_box = { { -0.4, -0.4 }, { 0.4, 0.4 } },
    animation_speed_coefficient = 32,
    belt_animation_set = data.raw["transport-belt"]["express-transport-belt"].belt_animation_set,
    container_distance = 0.75,
    belt_length = 0.5,
    fast_replaceable_group = "loader",
    filter_count = 1,
    speed = 0.75,
    structure = {
      direction_in = {
        sheet = {
          filename = Paths.graphics .. "/entities/express-loader.png",
          priority = "extra-high",
          shift = { 0.15625, 0.0703125 },
          width = 106 * 2,
          height = 85 * 2,
          y = 85 * 2,
          scale = 0.25,
        },
      },
      direction_out = {
        sheet = {
          filename = Paths.graphics .. "/entities/express-loader.png",
          priority = "extra-high",
          shift = { 0.15625, 0.0703125 },
          width = 106 * 2,
          height = 85 * 2,
          scale = 0.25,
        },
      },
    },
    se_allow_in_space = true,
  }

  local item = {
    name = name,
    type = "item",
    place_result = name,
    icon = Paths.graphics .. "/items/express-loader.png",
    icon_size = 64,
    stack_size = 50,
    subgroup = data.raw["item"]["iron-chest"].subgroup,
    order = data.raw["item"]["iron-chest"].order,
  }

  local recipe = {
    name = name,
    type = "recipe",
    enabled = true,
    energy_required = 0.5,
    ingredients = {},
    results = {{type="item",name=name,amount=1}},
  }

  data:extend({ entity, item, recipe })
end

function M.add_network_tank()
  local name = "network-tank"
  local override_item_name = "storage-tank"
  
  -- Start by deep copying the existing tank prototype
  local entity = table.deepcopy(data.raw["storage-tank"][override_item_name])
  entity.name = name
  entity.icon = Paths.graphics .. "/entities/network-tank.png"
  entity.icon_size = 64
  entity.selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } }
  entity.collision_box = { { -0.4, -0.4 }, { 0.4, 0.4 } }
  entity.fluid_box.volume=100000
  entity.fluid_box.base_area = constants.TANK_AREA
  entity.fluid_box.height = constants.TANK_HEIGHT
  entity.fluid_box.pipe_connections = {
        { direction = defines.direction.north, position = {0, 0.2} }
  }
  entity.two_direction_only = false
  entity.pictures = {
    picture = {
      sheet = {
        filename = Paths.graphics .. "/entities/network-tank.png",
        size = 64,
        scale = 0.5,
      },
    },
    window_background = {
      filename = Paths.graphics .. "/empty-pixel.png",
      size = 1,
    },
    fluid_background = {
      filename = Paths.graphics .. "/entities/fluid-background.png",
      size = { 32, 32 },
    },
    flow_sprite = {
      filename = Paths.graphics .. "/empty-pixel.png",
      size = 1,
    },
    gas_flow = {
      filename = Paths.graphics .. "/empty-pixel.png",
      size = 1,
    },
  }
  entity.flow_length_in_ticks = 1
  entity.minable = { mining_time = 0.5, result = name }
  entity.se_allow_in_space = true
  entity.allow_copy_paste = true
  entity.additional_pastable_entities = { "network-tank" }
  entity.max_health = 200

  -- Define the item for the network tank
  local item = table.deepcopy(data.raw["item"][override_item_name])
  item.name = name
  item.place_result = name
  item.icon = Paths.graphics .. "/items/network-tank.png"
  item.icon_size = 64

  -- Define the recipe for the network tank
  local recipe = {
    name = name,
    type = "recipe",
    enabled = true,
    energy_required = 0.5,
    ingredients = {},
    results = { { type = "item", name = name, amount = 1 } },  -- Correcting the results format
  }

  data:extend({ entity, item, recipe })
end


function M.add_network_sensor()
  local name = "network-sensor"
  local override_item_name = "constant-combinator"
  local override_prototype = "constant-combinator"

  local entity = table.deepcopy(data.raw[override_prototype][override_item_name])
  entity.name = name
  entity.minable.result = name
  entity.item_slot_count = 1000

  -- Add circuit fields if required for Factorio 2.0
  entity.circuit_wire_connection_points = data.raw[override_prototype][override_item_name].circuit_wire_connection_points or {}
  entity.circuit_connector_sprites = data.raw[override_prototype][override_item_name].circuit_connector_sprites or {}
  entity.circuit_wire_max_distance = data.raw[override_prototype][override_item_name].circuit_wire_max_distance or 0

  local item = table.deepcopy(data.raw["item"][override_item_name])
  item.name = name
  item.place_result = name
  item.order = item.order .. "2"

  local recipe = table.deepcopy(data.raw["recipe"][override_item_name])
  recipe.name = name
  recipe.results = {{type="item",name=name,amount=1}}
  recipe.enabled = true

  data:extend({ entity, item, recipe })
end

M.main()
