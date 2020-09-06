--[[
  Sample digiline-enabled frame
  Omikhleia 2020.
  MIT-lisenced.
--]]
local S = digiframe.S

digiframe.register_node("digiframe:frame", {
  description = S("Digiline frame"),
  drawtype = "nodebox",
  node_box = {
    type = "fixed",
    fixed = {-0.5, -0.5, 7/16, 0.5, 0.5, 0.5}, -- Same as homedecor's item frame
  },
  tiles = {"digiframe_frame.png"},
  inventory_image = "digiframe_frame.png",
  wield_image = "digiframe_frame.png",  
  paramtype = "light",
  paramtype2 = "facedir",
  sunlight_propagates = true,
  groups = { choppy=2, dig_immediate=2, digiframe=1 },
  sounds = default.node_sound_wood_defaults(),
})

digiframe.register_node("digiframe:glass", {
  description = S("Digiline glass"),
  drawtype = "glasslike_framed",
  tiles = {
    "default_obsidian_glass.png", -- sides
    "default_glass_detail.png", -- shine/details
  },
  use_texture_alpha = true,
  sunlight_propagates = true,
  paramtype = "light",
  paramtype2 = "facedir",
  sunlight_propagates = true,
  groups = { choppy=2, dig_immediate=2, digiframe=2 },
  sounds = default.node_sound_wood_defaults(),
})

digiframe.register_node("digiframe:pedestal", {
  description = S("Digiline pedestal"),
  drawtype = "nodebox",
  node_box = {
    type = "fixed",
    fixed = { -- half-block (slab) height pedestal
      {-0.4375, -0.5, -0.4375, 0.4375, -0.4375, 0.4375},
      {-0.375, -0.4375, -0.375, 0.375, -0.375, 0.375},
      {-0.25, -0.375, -0.25, 0.25, -0.125, 0.25},
      {-0.3125, -0.125, -0.3125, 0.3125, -0.0625, 0.3125},
      {-0.375, -0.0625, -0.375, 0.375, 0, 0.375},
    },
  },  
  tiles = {"default_wood.png"},
  paramtype  = "light",
  paramtype2 = "facedir",
  groups = { choppy=2, oddly_breakable_by_hand=3, digiframe=3 },
  sounds = default.node_sound_wood_defaults(),
})

-- digiframe.register_node("digiframe:aquarium", {
  -- description = S("Digiline aquarium"),
  -- drawtype = "glasslike_framed",
  -- tiles = {
    -- "default_obsidian_glass.png", -- sides
    -- "default_glass_detail.png", -- shine/details
    -- "default_wood.png", -- bottom (not working?)
    -- "default_wood.png", -- top (not working?)
  -- },
  -- special_tiles = {{
      -- name = "default_water_source_animated.png",
      -- animation = {
        -- type = "vertical_frames",
        -- aspect_w = 16,
        -- aspect_h = 16,
        -- length = 2.0,
      -- }
    -- }
  -- },
  -- use_texture_alpha = true,
  -- sunlight_propagates = true,
  -- paramtype = "light",
  -- paramtype2 = "glasslikeliquidlevel",
  -- place_param2 = 50,
  -- groups = { cracky = 3, oddly_breakable_by_hand=3, digiframe=2 },
  -- sounds = default.node_sound_glass_defaults(),
-- })

-- EOF