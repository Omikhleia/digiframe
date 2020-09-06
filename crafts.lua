local wire = 'digilines:wire_std_00000000'
local frame = 'itemframes:frame'

minetest.register_craft({
  output = 'digiframe:frame',
  type = 'shapeless',
  recipe = {frame, wire},
})

minetest.register_craft({
  output = "digiframe:pedestal",
  type = 'shapeless',
  recipe = {frame, wire, 'group:wood'},
})

minetest.register_craft({
  output = "digiframe:glass",
  type = 'shapeless', 
  recipe = {frame, wire, 'default:obsidian_glass'},
})

-- EOF