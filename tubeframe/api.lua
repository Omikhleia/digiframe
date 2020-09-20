--[[
  Tube-enabled frames (API)
  Omikhleia 2020.
  MIT-lisenced.
--]]

tubeframe = {
  version = 1.0,
}

-- Node registration

local nodeparts = {
  tube = {
    insert_object = function(pos, node, stack, direction, owner)
      local meta = minetest.get_meta(pos)
      local s = stack:take_item(1)
      meta:set_string("item", s:to_string())
      framing_api.core.update_item(pos, node)
      return stack
    end,
    can_insert = function(pos, node, stack, direction, owner)
      local meta = minetest.get_meta(pos)
      return meta:get_string("item") == ""
    end,
    connect_sides = { bottom=1 },
  },

  on_rightclick = function(pos, node, clicker, itemstack)
    local meta = minetest.get_meta(pos)
    framing_api.core.drop_item(pos, node)
    minetest.sound_play("tubeframe_tap", {
      pos = pos,
      max_hear_distance = 5
    }, true)
    return itemstack
  end,
  on_punch = function(pos,node,puncher)
    local meta = minetest.get_meta(pos)
    framing_api.core.drop_item(pos, node)
  end,
  
  after_place_node = pipeworks.after_place,
  after_dig_node = pipeworks.after_dig,

  on_destruct = function(pos)
    local meta = minetest.get_meta(pos)
    local node = minetest.get_node(pos)
    if meta:get_string("item") ~= "" then
      framing_api.core.drop_item(pos, node)
    end
  end,
}

tubeframe.register_node = function(itemname, nodedata)
  -- Add behaviors
  for k, v in pairs(nodeparts) do nodedata[k] = v end

  -- Ensure the tubeframe group is set (default to frame-like)
  nodedata.groups = nodedata.groups or {}
  nodedata.groups.tubeframe = nodedata.groups.tubeframe or 1
  nodedata.groups.framing = nodedata.groups.tubeframe

  nodedata.groups.tubedevice = 1
  nodedata.groups.tubedevice_receiver = 1

  framing_api.register_node(itemname, nodedata)
end

-- EOF