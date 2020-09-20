local tube = 'pipeworks:tube_1'
local frame = 'itemframes:frame'

minetest.register_craft({
  output = "tubeframe:pedestal",
  type = 'shapeless',
  recipe = {frame, tube, 'group:wood'},
})


-- EOF