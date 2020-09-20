# Framing API

A **minetest** API for item framing.

This mod provides an API for other mods to use.

Dependencies:
- `default`
- (optional) `itemframes` - part of the "homedecor" modpack, and only used for crafting recipes.
- (optional) `screwdriver`, `mesecons_mvps` - just to play well with these when they are enabled.

## API

Everything resides in the `framing_api` namespace.

As of version 1.0, there might be other things in this object, but they are not considered mature enough (and hence, are subject to changes), so are not part of the public API.

`framing_api.version`

Version of the API. Minor changes should break compatibility, while major changes may introduce
breaking changes.

`framing_api.core.remove_item(pos)`

Removes the framed item(s) located at *pos*, if any.

`framing_api.core.update_item(pos, node)`

Removes the framed item and adds a new framed item defined by the "item" metadata at *pos*, based on the frame node's property.

`framing_api.core.drop_item(pos, node)`

Drops the framed item.

`framing_api.register_node(itemname, nodedata)`

Registers a new frame node "itemname", with visual properties and groups defined
in _nodedata_ specification.

The node specification must include the "framing" group, with a value defining the type of frame:
- 1: Thin frame-like node (same depth as an homedecor itemframe) = item is displayed slightly extruded.
- 2: Full block (assumingly glass-like, or very thin vertically) = item is displayed inside the node and rotates over the Y-axis.
- 3: Half block = item is displayed on the half-block top.
