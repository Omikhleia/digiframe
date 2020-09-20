--[[
  Pipeworks-enabled frames
  Omikhleia 2020.
  MIT-lisenced.
--]]

local S = framing_api.S

tube_entry = "^pipeworks_tube_connection_stony.png"

tubeframe.register_node("tubeframe:pedestal", {
  description = S("Tube-enabled pedestal"),
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
  tiles = {
    "tubeframe_pedestal_top.png",
    "default_wood.png"..tube_entry,
    "default_wood.png",
    "default_wood.png",
    "default_wood.png",
    "default_wood.png",
  },
  paramtype  = "light",
  paramtype2 = "facedir",
  groups = { choppy=2, oddly_breakable_by_hand=3, tubeframe=3 },
  sounds = default.node_sound_wood_defaults(),
})

-- EOF