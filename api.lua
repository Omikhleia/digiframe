--[[
  Digiline item framing API
  Omikhleia 2020.
  MIT-lisenced.
--]]
digiframe = {
  version = 1.0,
  S = function(s)
    return s -- FIXME: Later for intllib support if eventually requested
  end
}

local tmp = {}
screwdriver = screwdriver or {}

local S = digiframe.S

local function logger(msg, arg, nodename, pos)
  -- minetest.chat_send_all("[digiframe] "..msg.." "
    -- ..arg.." in " ..nodename.." at "
    -- ..minetest.pos_to_string(pos))
  minetest.log("action","[digiframe] "..msg.." "
    ..arg.." in " ..nodename.." at "
    ..minetest.pos_to_string(pos))
end

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

-- Groups for types of frame
--[[
  The group defines the type of frame:
  - digiline wiring
  - offset from node position (reminder: items are seached with a radius
    of 0.5 so the offset shall not set the item farther than that.
  - rotation
--]]
digiframe.groups = {
  -- 1 = same constants as homedecor item frame, wiring from back
  --     i.e. frame-like
  { wiring = digiframe.rules.back, 
    offset = { x = 6.5/16, y = 0, z = 6.5/16 },
  }, 
  -- 2 = inside node, wiring from sides, rotating over Y-axis
  --     i.e. pedestal-like, but inside the node (assumingly glass-like)
  { wiring = digiframe.rules.sides, 
    offset = { x = 0, y = 0, z = 0 },
  },
  -- 3 = rotated on top of a half-size block, wiring from sides
  --     i.e. anvil-like, but inside the node (assumingly slab-like)
  { wiring = digiframe.rules.sides_bottom, 
    offset = { x = 0, y = 0.5/16, z = 0,
               rot = { pitch = -1.5708, yaw = math.pi / 20 }},
  },
}
 
-- Orientation for frame item
--
local digiframe_facedir = {}
digiframe_facedir[0] = { x = 0, z = 1 }
digiframe_facedir[1] = { x = 1, z = 0 }
digiframe_facedir[2] = { x = 0, z = -1 }
digiframe_facedir[3] = { x = -1, z = 0 }

-- Helper to guess how the "wielditem" is rendered
-- FIXME: Might not be generic enough, part is a guess: 
-- See minetest's lua_api.txt for "visual" in entities, but it doesn't fully explicit.
local function is_extruded(itemdef)
  if itemdef.type ~= "node" then
    -- assume craft items, tools, etc. use 2D inventory_image
    return true
  end
  -- Obey wield_image when defined
  if itemdef.wield_image and itemdef.wield_image ~= "" then
    return true
  end
  -- Some node types seem to always use wield/inventory image
  if itemdef.drawtype == "plantlike"
    or itemdef.drawtype == "planlike_rooted"
    or itemdef.drawtype == "torchlike"
    or itemdef.drawtype == "signlike" then
    return true
  end
  -- Normally here we are left with non-extruded wielditems,
  -- rendered as their regular cube:
  --   normal, mesh, nodebox
  --   liquid, flowingliquid, glasslike, glasslike_framed,
  --   glasslike_framed_optional, firelike
  -- And also I guess (not tested)
  --   allfaces, allfaces_optional,
  --   fencelike, raillike
  return false
end

-- Functions for removing/adding item image
-- 
local remove_item = function(pos)
  local objs = minetest.get_objects_inside_radius(pos, 0.5)
  if objs then
    for _, obj in ipairs(objs) do
      if obj and obj:get_luaentity() and obj:get_luaentity().name == "digiframe:item" then
        obj:remove()
      end
    end
  end
end

local update_item = function(pos, node)
  remove_item(pos)

  local meta = minetest.get_meta(pos)
  local itemname = meta:get_string("item")

  if itemname ~= "" then
    local delta = digiframe_facedir[node.param2] or digiframe_facedir[0]
    local stack = ItemStack(itemname)
    local itemdef = minetest.registered_items[itemname]

    -- Frame name based on content when possible
    local desc = stack.get_meta
      and stack:get_meta():get_string("description")
    if not desc or desc == "" then
      -- Use default description when none is set in the meta
      desc = itemdef and itemdef.description or S("Unknown item")
    end
    meta:set_string("infotext", desc.." "..S("(framed)"))

    -- Entity display
    local group = minetest.get_item_group(node.name, "digiframe")
    local offset = digiframe.groups[group].offset

    pos.x = pos.x + delta.x * offset.x
    pos.y = pos.y + offset.y
    pos.z = pos.z + delta.z * offset.z
    
    tmp.nodename = node.name
    tmp.texture = stack:get_name()
    local ent = minetest.add_entity(pos, "digiframe:item")
    local yaw = math.pi * 2 - node.param2 * math.pi / 2
    if (offset.rot ~= nil) then
      if itemdef and not is_extruded(itemdef) then
        -- Keep nodes upright
        pos.y = pos.y + 0.5*0.33 + 1/16
        ent:set_rotation({x = 0, y = yaw + offset.rot.yaw, z = 0}) -- pitch, yaw, roll        
        ent:set_pos(pos)
      else
        -- Flip everything else horizontally
        ent:set_rotation({x = offset.rot.pitch, y = yaw + offset.rot.yaw, z = 0})
      end
    else
      ent:set_yaw(yaw)
    end
  else
    meta:set_string("infotext", "")
  end
end

minetest.register_entity("digiframe:item",{
  hp_max = 1,
  visual="wielditem",
  visual_size={x = 0.33, y = 0.33},
  collisionbox = {0, 0, 0, 0, 0, 0},
  physical = false,
  textures = {"air"},
  on_activate = function(self, staticdata)
    if tmp.nodename ~= nil and tmp.texture ~= nil then
      self.nodename = tmp.nodename
      tmp.nodename = nil
      self.texture = tmp.texture
      tmp.texture = nil
    else
      if staticdata ~= nil and staticdata ~= "" then
      local data = staticdata:split(';')
        if data and data[1] and data[2] then
          self.nodename = data[1]
          self.texture = data[2]
        end
      end
    end
    if self.texture ~= nil then
      self.object:set_properties({textures = {self.texture}})
    end
    if minetest.get_item_group(self.nodename, "digiframe") == 2 then
      self.object:set_properties({automatic_rotate = 1})
    end
    
    if self.texture ~= nil and self.nodename ~= nil then
      local entity_pos = vector.round(self.object:get_pos())
      local objs = minetest.get_objects_inside_radius(entity_pos, 0.5)
      if objs then
        for _, obj in ipairs(objs) do
          if obj ~= self.object and
            obj:get_luaentity() and
            obj:get_luaentity().name == "digiframe:item" and
            obj:get_luaentity().nodename == self.nodename and
            obj:get_properties() and
            obj:get_properties().textures and
            obj:get_properties().textures[1] == self.texture then
            logger("Removing extra", self.texture, self.nodename, entity_pos)
            self.object:remove()
            break
          end
        end
      end
    end
  end,

  get_staticdata = function(self)
    if self.nodename ~= nil and self.texture ~= nil then
      return self.nodename .. ';' .. self.texture
    end
    return ""
  end,
})

-- LBM: Automatically restore entities lost from frames
-- due to /clearobjects or similar
minetest.register_lbm({
  label = "Maintain digiframe entities",
  name = "digiframe:maintain_entities",
  nodenames = {"group:digiframe"},
  run_at_every_load = true,
  action = function(pos, node)
    minetest.after(0,
      function(pos, node)
        local meta = minetest.get_meta(pos)
        local itemstring = meta:get_string("item")
        if itemstring ~= "" then
          local objs = minetest.get_objects_inside_radius(pos, 0.5)
          if #objs == 0 then
            logger("LBM replacing missing", itemstring, node.name, pos)
            update_item(pos, node)
          end
        end
      end,
      pos, node)
  end
})

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
            update_item(pos, node)
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
    remove_item(pos)
  end,

  on_rotate = screwdriver.disallow,
}

digiframe.register_node = function(itemname, nodedata)
  -- Node registration
  for k, v in pairs(nodeparts) do nodedata[k] = v end --[[
     FIXME: Maybe it would be more robust to only copy the necessary fields?
     --]]
  nodedata.groups = nodedata.groups or {}
  nodedata.groups.digiframe = nodedata.groups.digiframe or 1 -- default to frame-like

  nodedata.digiline.wire.rules = function(node)
    -- A bit messy, but easier for debug the nodes activate correct wiring rules...
    local group = minetest.get_item_group(node.name, "digiframe") or 1
    local f = digiframe.groups[group].wiring
    if type(f) == "function" then
      return f(node)
    else
      return f
    end
  end

  minetest.register_node(itemname, nodedata)

  -- Stop mesecon pistons from pushing digiframes
  if minetest.get_modpath("mesecons_mvps") then
    mesecon.register_mvps_stopper(itemname)
  end
end

-- EOF
