local M = {}

function M.main()
  M.add_network_chest_as_pastable_target_for_assemblers()
end

function M.add_network_chest_as_pastable_target_for_assemblers()
  -- Check if network-chest is defined
  local network_chest_proto = data.raw["container"]["network-chest"]
  if not network_chest_proto then
    log("Warning: network-chest prototype not found.")
    return
  end

  -- Get or initialize pastable targets list
  local nc_paste = network_chest_proto.additional_pastable_entities or {}
  
  for _, assembler in pairs(data.raw["assembling-machine"]) do
    local entities = assembler.additional_pastable_entities or {}

    -- Ensure "network-chest" is not already in assembler's pastable entities
    if not table.find(entities, "network-chest") then
      table.insert(entities, "network-chest")
    end
    assembler.additional_pastable_entities = entities

    -- Add assembler name to network chest's pastable targets if not already present
    if not table.find(nc_paste, assembler.name) then
      table.insert(nc_paste, assembler.name)
    end
  end

  network_chest_proto.additional_pastable_entities = nc_paste
end

-- Helper function to check if a value exists in a table (Factorio 2.0 doesn't have a native `table.find`)
function table.find(tbl, value)
  for _, v in pairs(tbl) do
    if v == value then
      return true
    end
  end
  return false
end

M.main()
