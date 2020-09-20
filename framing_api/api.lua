--[[
  Digiline item framing API
  Omikhleia 2020.
  MIT-lisenced.
--]]
framing_api = {
  version = 1.0,
  S = function(s)
    return s -- FIXME: Later for intllib support if eventually requested
  end,
  core = {},
}

local tmp = {}
screwdriver = screwdriver or {}

local S = framing_api.S

local function logger(msg, arg, nodename, pos)
  minetest.log("action","[framing_api] "..msg.." "
    ..arg.." in " ..nodename.." at "
    ..minetest.pos_to_string(pos))
end

-- Groups for types of frame
--[[
  The group defines the type of frame:
  - offset from node position (reminder: items are seached with a radius
    of 0.5 so the offset shall not set the item farther than that.
  - rotation
--]]
framing_api.groups = {
  -- 1 = same constants as homedecor item frame
  --     i.e. frame-like
  {
    offset = { x = 6.5/16, y = 0, z = 6.5/16 },
  }, 
  -- 2 = inside node, rotating over Y-axis
  --     i.e. pedestal-like, but inside the node (assumingly glass-like)
  {
    offset = { x = 0, y = 0, z = 0 },
  },
  -- 3 = rotated on top of a half-size block
  --     i.e. anvil-like, but inside the node (assumingly slab-like)
  { 
    offset = { x = 0, y = 0.5/16, z = 0,
               rot = { pitch = -1.5708, yaw = math.pi / 20 }},
  },
}
 
-- Orientation for frame item
--
local framing_facedir = {}
framing_facedir[0] = { x = 0, z = 1 }
framing_facedir[1] = { x = 1, z = 0 }
framing_facedir[2] = { x = 0, z = -1 }
framing_facedir[3] = { x = -1, z = 0 }

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

-- Functions for removing/adding items
-- 
framing_api.core.remove_item = function(pos)
  local objs = minetest.get_objects_inside_radius(pos, 0.5)
  if objs then
    for _, obj in ipairs(objs) do
      if obj and obj:get_luaentity() and obj:get_luaentity().name == "framing_api:item" then
        obj:remove()
      end
    end
  end
end

framing_api.core.update_item = function(pos, node)
  framing_api.core.remove_item(pos)

  local meta = minetest.get_meta(pos)
  local itemname = meta:get_string("item")

  if itemname ~= "" then
    local delta = framing_facedir[node.param2] or framing_facedir[0]
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
    local group = minetest.get_item_group(node.name, "framing")
    local offset = framing_api.groups[group].offset

    pos.x = pos.x + delta.x * offset.x
    pos.y = pos.y + offset.y
    pos.z = pos.z + delta.z * offset.z
    
    tmp.nodename = node.name
    tmp.texture = stack:get_name()
    local ent = minetest.add_entity(pos, "framing_api:item")
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

framing_api.core.drop_item = function(pos, node)
  local meta = minetest.get_meta(pos)
  local itemname = meta:get_string("item")

  if itemname ~= "" then
    minetest.add_item(pos, itemname)
    meta:set_string("item", "")
  end
end

minetest.register_entity("framing_api:item",{
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
    if minetest.get_item_group(self.nodename, "framing") == 2 then
      self.object:set_properties({automatic_rotate = 1})
    end
    
    if self.texture ~= nil and self.nodename ~= nil then
      local entity_pos = vector.round(self.object:get_pos())
      local objs = minetest.get_objects_inside_radius(entity_pos, 0.5)
      if objs then
        for _, obj in ipairs(objs) do
          if obj ~= self.object and
            obj:get_luaentity() and
            obj:get_luaentity().name == "framing_api:item" and
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
  label = "Maintain frame entities",
  name = "framing_api:maintain_entities",
  nodenames = {"group:framing"},
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
            framing_api.core.update_item(pos, node)
          end
        end
      end,
      pos, node)
  end
})

-- Node registration

framing_api.register_node = function(itemname, nodedata)
  -- Ensure we get a framing group
  nodedata.groups = nodedata.groups or {}
  nodedata.groups.framing = nodedata.groups.framing or 1 -- default to frame-like

  -- Ensure the we have a default on_destruct
  nodedata.on_destruct = nodedata.on_destruct or function(pos)
    framing_api.core.remove_item(pos)
  end
  
  -- Disable screwdriver on frames
  nodedata.on_rotate = screwdriver.disallow

  -- Registration
  minetest.register_node(itemname, nodedata)

  -- Stop mesecon pistons from pushing frames
  if minetest.get_modpath("mesecons_mvps") then
    mesecon.register_mvps_stopper(itemname)
  end
end

-- EOF
