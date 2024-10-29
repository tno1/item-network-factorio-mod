local GlobalState = require "src.GlobalState"
local UiConstants = require "src.UiConstants"
local Utils = require "src.Utils"
local Timer = require "src.Timer"

local M = {}

M.WIDTH = 490
M.HEIGHT = 500

-- Builds the GUI for the item, fluid, and shortage tabs.
local function build_item_page(parent)
  local main_flow = parent.add({
    type = "flow",
    direction = "vertical",
  })

  return main_flow
end

function M.open_main_frame(player_index)
  local ui = GlobalState.get_ui_state(player_index)
  if ui.net_view ~= nil then
    M.destroy(player_index)
    return
  end

  local player = game.get_player(player_index)
  if player == nil then
    return
  end

  local width = M.WIDTH
  local height = M.HEIGHT + 32

  --[[
  I want the GUI to look like this:

  +--------------------------------------------------+
  | Network View ||||||||||||||||||||||||||||| [R][X]|
  +--------------------------------------------------+
  | Items | Fluids | Shortages |                     | <- tabs
  +--------------------------------------------------+
  | [I]  [I]  [I]  [I]  [I]  [I]  [I]  [I]  [I]  [I] | <- content
    ... repeated ...
  | [I]  [I]  [I]  [I]  [I]  [I]  [I]  [I]  [I]  [I] |
  +--------------------------------------------------+

  [R] is refresh button and [X] is close. [I] are item icons with the number overlay.
  I want the ||||| stuff to make the window draggable.
  Right now, I can get it to look right, but it isn't draggable.
  OR I can omit the [R][X] buttons make it draggable.
  ]]

  -- create the main window
  local frame = player.gui.screen.add({
    type = "frame",
    name = UiConstants.NV_FRAME,
    -- enabling the frame caption enables dragging, but
    -- doesn't allow the buttons to be on the top line
    --caption = "Network View",
  })
  player.opened = frame
  frame.style.size = { width, height }
  frame.auto_center = true

  local main_flow = frame.add({
    type = "flow",
    direction = "vertical",
  })

  local header_flow = main_flow.add({
    type = "flow",
    direction = "horizontal",
  })
  header_flow.drag_target = frame

  header_flow.add {
    type = "label",
    caption = "Network View",
    style = "frame_title",
    ignored_by_interaction = true,
  }

  local header_drag = header_flow.add {
    type = "empty-widget",
    style = "draggable_space",
    ignored_by_interaction = true,
  }
  header_drag.style.size = { M.WIDTH - 210, 20 }

  header_flow.add {
    type = "sprite-button",
    sprite = "utility/refresh",
    style = "frame_action_button",
    tooltip = { "gui.refresh" },
    tags = { event = UiConstants.NV_REFRESH_BTN },
  }

  header_flow.add {
    type = "sprite-button",
    sprite = "utility/close",
    hovered_sprite = "utility/close_black",
    clicked_sprite = "utility/close_black",
    style = "close_button",
    tags = { event = UiConstants.NV_CLOSE_BTN },
  }

  -- add tabbed stuff
  local tabbed_pane = main_flow.add {
    type = "tabbed-pane",
    tags = { event = UiConstants.NV_TABBED_PANE },
  }

  local tab_item = tabbed_pane.add { type = "tab", caption = "Items" }
  local tab_fluid = tabbed_pane.add { type = "tab", caption = "Fluids" }
  local tab_shortage = tabbed_pane.add { type = "tab", caption = "Shortages" }


  tabbed_pane.add_tab(tab_item, build_item_page(tabbed_pane))
  tabbed_pane.add_tab(tab_fluid, build_item_page(tabbed_pane))
  tabbed_pane.add_tab(tab_shortage, build_item_page(tabbed_pane))

  local enable_perf_tab = settings.get_player_settings(player.index)
    ["item-network-enable-performance-tab"].value
  if enable_perf_tab then
    local tab_info = tabbed_pane.add { type = "tab", caption = "Performance" }
    tabbed_pane.add_tab(tab_info, build_item_page(tabbed_pane))
  end

  -- select "items" (not really needed, as that is the default)
  tabbed_pane.selected_tab_index = 1

  ui.net_view = {
    frame = frame,
    tabbed_pane = tabbed_pane,
  }

  M.update_items(player_index)
end

-- used when setting the active tab
local tab_idx_to_view_type = {
  "item",
  "fluid",
  "shortage",
  "performance",
}


local function get_item_tooltip(name, count)
  local info = prototypes.item[name]
  if info == nil then
    return {
      "",
      name or "Unknown Item",
      ": ",
      count,
    }
  else
    return {
      "in_nv.item_sprite_btn_tooltip",
      info.localised_name,
      count,
    }
  end
end

local function get_fluid_tooltip(name, temp, count)
  local localised_name
  local info = prototypes.fluid[name]
  if info == nil then
    localised_name = name or "Unknown Fluid"
  else
    localised_name = info.localised_name
  end
  return {
    "in_nv.fluid_sprite_btn_tooltip",
    localised_name,
    string.format("%.0f", count),
    { "format-degrees-c", string.format("%.0f", temp) },
  }
end

local function get_item_shortage_tooltip(name, count)
  local info = prototypes.item[name]
  local localised_name
  if info == nil then
    localised_name = name or "Unknown Item"
  else
    localised_name = info.localised_name
  end
  return {
    "in_nv.item_shortage_sprite_btn_tooltip",
    localised_name,
    count,
  }
end

function M.update_items(player_index)
  local ui = GlobalState.get_ui_state(player_index)
  local net_view = ui.net_view
  if net_view == nil then
    return
  end
  local tabbed_pane = net_view.tabbed_pane

  net_view.view_type = tab_idx_to_view_type[tabbed_pane.selected_tab_index]
  local main_flow = tabbed_pane.tabs[tabbed_pane.selected_tab_index].content
  if main_flow == nil then
    return
  end


  local item_flow = main_flow[UiConstants.NV_ITEM_FLOW]
  if item_flow ~= nil then
    item_flow.destroy()
  end

  local view_type = net_view.view_type

  if view_type == "performance" then
    local info_flow = main_flow.add({
      type = "flow",
      direction = "vertical",
      name = UiConstants.NV_ITEM_FLOW,
    })
    for _, timer_info in ipairs(GlobalState.get_timers()) do
      local timer_flow = info_flow.add({ type = "flow", direction = "horizontal" })
      timer_flow.add({
        type = "label",
        caption = {
          "",
          timer_info.name,
          " (",
          timer_info.timer.count,
          "):",
        },
      })
      local timer_label = timer_flow.add({ type = "label" })
      timer_label.caption = Timer.get_average(timer_info.timer)
    end
    return
  end

  item_flow = main_flow.add({
    type = "scroll-pane",
    direction = "vertical",
    name = UiConstants.NV_ITEM_FLOW,
    vertical_scroll_policy = "always",
  })
  item_flow.style.size = { width = M.WIDTH - 30, height = M.HEIGHT - 82 }

  local h_stack_def = {
    type = "flow",
    direction = "horizontal",
  }

  local rows = M.get_rows_of_items(view_type)
  for _, row in ipairs(rows) do
    local item_h_stack = item_flow.add(h_stack_def)
    for _, item in ipairs(row) do
      local sprite_button = M.get_sprite_button_def(item, view_type)
      local sprite_button_inst = item_h_stack.add(sprite_button)
      sprite_button_inst.number = item.count
    end
  end
end

function M.get_sprite_button_def(item, view_type)
  if item.is_deposit_slot then
    return {
      type = "sprite-button",
      sprite = "utility/close_black", -- TODO FIX THIS SHIT ICON
      tags = { event = UiConstants.NV_DEPOSIT_ITEM_SPRITE_BUTTON },
      -- FIXME: needs translation tag
      tooltip = { "in_nv.deposit_item_sprite_btn_tooltip" },
    }
  else
    local tooltip
    local sprite_path
    local elem_type
    local tags
    if item.temp == nil then
      elem_type = "item"
      if view_type == "shortage" then
        tooltip = get_item_shortage_tooltip(item.item, item.count)
      else
        tooltip = get_item_tooltip(item.item, item.count)
        tags = { event = UiConstants.NV_ITEM_SPRITE_BUTTON, item = item.item }
      end
      if prototypes.item[item.item] == nil then
        sprite_path = nil
      else
        sprite_path = "item/" .. item.item
      end
    else
      elem_type = "fluid"
      tags = { event = UiConstants.NV_FLUID_SPRITE_BUTTON }
      tooltip = get_fluid_tooltip(item.item, item.temp, item.count)
      if prototypes.fluid[item.item] == nil then
        sprite_path = nil
      else
        sprite_path = "fluid/" .. item.item
      end
    end
    return {
      type = "sprite-button",
      elem_type = elem_type,
      sprite = sprite_path,
      tooltip = tooltip,
      tags = tags,
    }
  end
end

function M.on_gui_click_item(event, element)
  --[[
  This handles a click on an item sprite in the item view.
  If the cursor has something in it, then the cursor content is dumped into the item network.
  If the cursor is empty then we grab something from the item network.
    left-click grabs one item.
    shift + left-click grabs one stack.
    ctrl + left-click grabs it all.
  ]]
  local player = game.players[event.player_index]
  if player == nil then
    return
  end
  local inv = player.get_main_inventory()
  if inv == nil then
    return
  end

  -- if we have an empty cursor, then we are taking items, which requires a valid target
  if player.is_cursor_empty() then
    local item_name = event.element.tags.item
    if item_name == nil then
      return
    end

    local network_count = GlobalState.get_item_count(item_name)
    local stack_size = prototypes.item[item_name].stack_size

    if event.button == defines.mouse_button_type.left then
      -- shift moves a stack, non-shift moves 1 item
      local n_transfer = 1
      if event.shift then
        n_transfer = stack_size
      elseif event.control then
        n_transfer = network_count
      end
      n_transfer = math.min(network_count, n_transfer)
      -- move one item or stack to player inventory
      if n_transfer > 0 then
        local n_moved = inv.insert({ name = item_name, count = n_transfer })
        if n_moved > 0 then
          GlobalState.set_item_count(item_name, network_count - n_moved)
          local count = GlobalState.get_item_count(item_name)
          element.number = count
          element.tooltip = get_item_tooltip(item_name, count)
        end
      end
    end
    return
  else
    -- There is a stack in the cursor. Deposit it.
    local cursor_stack = player.cursor_stack
    if not cursor_stack or not cursor_stack.valid_for_read then
      return
    end

    -- don't deposit tracked entities (can be unique)
    if cursor_stack.item_number ~= nil then
      prototypes.print(string.format(
        "Unable to deposit %s because it might be a vehicle with items that will be lost.",
        cursor_stack.name))
      return
    end

    if event.button == defines.mouse_button_type.left then
      GlobalState.increment_item_count(cursor_stack.name, cursor_stack.count)
      cursor_stack.clear()
      player.clear_cursor()
      M.update_items(event.player_index)
    end
  end
end

local function items_list_sort(left, right)
  if left.is_deposit_slot then
    return true
  end
  if right.is_deposit_slot then
    return false
  end
  return left.count > right.count
end

function M.get_list_of_items(view_type)
  local items = {}

  if view_type == "item" then
    -- manually insert a slot for players to deposit items
    table.insert(items, { is_deposit_slot = true })

    local items_to_display = GlobalState.get_items()
    for item_name, item_count in pairs(items_to_display) do
      if item_count > 0 then
        table.insert(items, { item = item_name, count = item_count })
      end
    end
  elseif view_type == "fluid" then
    local fluids_to_display = GlobalState.get_fluids()
    for fluid_name, fluid_temps in pairs(fluids_to_display) do
      for temp, count in pairs(fluid_temps) do
        table.insert(items, { item = fluid_name, count = count, temp = temp })
      end
    end
  elseif view_type == "shortage" then
    -- add item shortages
    local missing = GlobalState.missing_item_filter()
    for item_name, count in pairs(missing) do
      -- sometime shortages can have invalid item names.
      if prototypes.item_prototypes[item_name] ~= nil then
        table.insert(items, { item = item_name, count = count })
      end
    end

    -- add fluid shortages
    missing = GlobalState.missing_fluid_filter()
    for fluid_key, count in pairs(missing) do
      local fluid_name, temp = GlobalState.fluid_temp_key_decode(fluid_key)
      table.insert(items, { item = fluid_name, count = count, temp = temp })
    end
  end

  table.sort(items, items_list_sort)

  return items
end

function M.get_rows_of_items(view_type)
  local items = M.get_list_of_items(view_type)
  local max_row_count = 10
  local rows = Utils.split_list_by_batch_size(items, max_row_count)
  return rows
end

function M.destroy(player_index)
  local ui = GlobalState.get_ui_state(player_index)
  if ui.net_view ~= nil then
    ui.net_view.frame.destroy()
    ui.net_view = nil
  end
end

function M.on_gui_closed(event)
  M.destroy(event.player_index)
end

function M.on_every_5_seconds(event)
  for player_index, _ in pairs(GlobalState.get_player_info_map()) do
    M.update_items(player_index)
  end
end

return M
