--[[
  Digiline-enabled frames (API)
  Omikhleia 2020.
  MIT-lisenced.
--]]

digiframe = {
  version = 1.0,
}

-- Rules for digiline wiring
--
digiframe.rules = {
  -- Connectivity from back side (based on node orientation)
  back = function(node)
    local rules = {{x=-1, y=0, z=0}}
    for i = 0, node.param2 do
      rules = mesecon.rotate_rules_left(rules)
    end
    return rules
  end,
  -- Connectivity from sides
  sides = {
    {x=-1, y=0, z= 0},
    {x= 1, y=0, z= 0},
    {x= 0, y=0, z=-1},
    {x= 0, y=0, z= 1},
  },
  -- Connectivity from sides and bottom
  sides_bottom = {
    {x=-1, y=0, z= 0},
    {x= 1, y=0, z= 0},
    {x= 0, y=0, z=-1},
    {x= 0, y=0, z= 1},
    {x= 0, y=-1, z= 0},
  },
}

-- Wiring groups for types of digiframe
digiframe.groups = {
  -- 1 = wiring from back
  { wiring = digiframe.rules.back, 
  }, 
  -- 2 = wiring from sides
  { wiring = digiframe.rules.sides, 
  },
  -- 3 = wiring from sides and bottom
  { wiring = digiframe.rules.sides_bottom,
  },
}

-- Node registration

local nodeparts = {
  digiline = {
    receptor = {},
    wire = {},
    effector = {
      action = function(pos, node, channel, msg)
        local setchan = minetest.get_meta(pos):get_string("channel")
        if channel ~= setchan then return end
        
        -- Be friendly with keyboards, digiline detector tube, etc.: 
        -- text message is interpreted as "set" command
        if type(msg) == "string" then
          msg = { cmd = "set", item = msg }
        elseif type(msg) ~= "table" then
          return
        end
        if msg.cmd == "set" then
          local itemstring = type(msg.item) == "string" 
            and string.split(msg.item, " ")[1] -- ignore anything after the item string
            or ""
          local meta = minetest.get_meta(pos)
          if itemstring == meta:get_string("item") then return end

          meta:set_string("item", itemstring)
          minetest.after(0, function() -- async object creation
            local meta = minetest.get_meta(pos)
            digilines.receptor_send(pos, digilines.rules.default, meta:get_string("channel"), {
              event = "notify",
              item = meta:get_string("item"),
              origin = pos
            })
            framing_api.core.update_item(pos, node)
          end, pos, node)
        elseif msg.cmd == "get" then
          minetest.after(0, function() -- async notification
            local meta = minetest.get_meta(pos)
            digilines.receptor_send(pos, digilines.rules.default, meta:get_string("channel"), {
              event = "get",
              item = meta:get_string("item"),
              origin = pos
            })
          end, pos, node)
        end
      end,
    },
  },
  
  on_construct = function(pos)
    local meta = minetest.get_meta(pos)
    meta:set_string("formspec", "field[channel;Channel;${channel}")
  end,

  on_receive_fields = function(pos, formname, fields, sender)
    local name = sender:get_player_name()
    if minetest.is_protected(pos, name) and not minetest.check_player_privs(name, {protection_bypass=true}) then
      minetest.record_protection_violation(pos, name)
      return
    end
    local meta = minetest.get_meta(pos)
    if fields.channel then
      meta:set_string("channel", fields.channel)
    end
  end,
  
  on_destruct = function(pos)
    framing_api.core.remove_item(pos)
  end,
}

digiframe.register_node = function(itemname, nodedata)
  -- Add behaviors
  for k, v in pairs(nodeparts) do nodedata[k] = v end
     
  -- Ensure the digiframe group is set (default to frame-like)
  nodedata.groups = nodedata.groups or {}
  nodedata.groups.digiframe = nodedata.groups.digiframe or 1
  nodedata.groups.framing = nodedata.groups.digiframe
  
  nodedata.digiline.wire.rules = function(node)
    -- A bit messy, but easier for debug to check the nodes activate correct wiring rules...
    local group = minetest.get_item_group(node.name, "digiframe") or 1
    local f = digiframe.groups[group].wiring
    if type(f) == "function" then
      return f(node)
    else
      return f
    end
  end

  framing_api.register_node(itemname, nodedata)
end

-- EOF