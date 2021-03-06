reinforced_nodes = {}

reinforced_nodes.reinforceable_nodes = {}

local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
local S = minetest.get_translator(modname)

local function deep_copy(table_in)
	local table_out = {}
	for index, value in pairs(table_in) do
		if type(value) == "table" then
			table_out[index] = deep_copy(value)
		else
			table_out[index] = value
		end
	end
	return table_out
end


-- reinforcement_def:
--{
--	overlay_texture = 
--}

local reinforcers_per_ingot = 4

reinforced_nodes.register_reinforced_node = function(base_node_name, new_node_name, reinforcement_def)
	local base_def = minetest.registered_nodes[base_node_name]
	assert(base_def ~= nil)
	local new_def = deep_copy(base_def)
	
	if new_def._doc_items_longdesc == nil then
		new_def._doc_items_longdesc = S("A node that's had reinforcement embedded into it.")
	else
		new_def._doc_items_longdesc = new_def._doc_items_longdesc .. "\n" .. S("This particular node has been reinforced.")
	end
	if new_def._doc_items_usagehelp == nil then
		new_def._doc_items_usagehelp = S("The reinforcement added to this node makes it much harder to dig using conventional hand tools. Perhaps dynamite or other specialized equipment will help.")
	else
		new_def._doc_items_usagehelp = new_def._doc_items_usagehelp .. "\n" .. S("The reinforcement added to this node makes it much harder to dig using conventional hand tools. Perhaps dynamite or other specialized equipment will help.")
	end
	
	if type(new_def.tiles) == "string" then
		new_def.tiles = {new_def.tiles}
	end	
	-- TODO: more sophisticated overlay_texture handling that allows a table to be used
	for i, base_tile in ipairs(new_def.tiles) do
		if type(base_tile) == "string" then		
			new_def.tiles[i] = base_tile .. "^" .. reinforcement_def.overlay_texture
		elseif type(base_tile) == "table" then
			base_tile.name = base_tile.name .. "^" .. reinforcement_def.overlay_texture
		end
	end
	
	if new_def.groups == nil then
		new_def.groups = {}
	end
	new_def.groups["reinforced_node"] = 1
	new_def.groups["level"] = 3
	
	local drop_name = base_node_name
	if type(new_def.drop) == "string" then
		drop_name = new_def.drop
		new_def.drop = nil
	end	
	if new_def.drop == nil then
		new_def.drop = {
            max_items = 2,
            items = {
                {
                    rarity = 1,
                    items = {drop_name},
                },
                {
                    rarity = reinforcers_per_ingot,
                    items = {"default:steel_ingot"},
                },
			}
		}
	end
	
	minetest.register_node(new_node_name, new_def)
	reinforced_nodes.reinforceable_nodes[base_node_name] = new_node_name
end

minetest.register_craftitem("reinforced_nodes:steel_reinforcement", {
    description = S("Steel Reinforcement"),
    inventory_image = "reinforced_nodes_steel_reinforcement.png",

	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" then
			return itemstack
		end
		
		local pos = pointed_thing.under
		local player_name = user:get_player_name()
		
		if minetest.is_protected(pos, player_name) then
			minetest.record_protection_violation(pos, player_name)
			return itemstack
		end
		
		local node = minetest.get_node(pos)
		
		if not node then
			return itemstack
		end
		
		local replacement = reinforced_nodes.reinforceable_nodes[node.name]
		
		if replacement == nil then
			return itemstack
		end
		
		local node = minetest.get_node(pos)
		node.name = replacement
		minetest.swap_node(pos, node)
		minetest.sound_play({name="reinforced_nodes_clink", gain=0.25}, {pos = pos}, true)
		
		if not minetest.is_creative_enabled(player_name) then
			itemstack:take_item(1)
		end
		return itemstack		
	end,
})

minetest.register_craft({
    output = "reinforced_nodes:steel_reinforcement " .. tostring(reinforcers_per_ingot*4),
    recipe = {
        {'default:steel_ingot', '', 'default:steel_ingot'},
        {'', '', ''},
        {'default:steel_ingot', '', 'default:steel_ingot'},
    },
})

if minetest.get_modpath("default") then
	reinforced_nodes.register_reinforced_node("default:stonebrick", "reinforced_nodes:stonebrick",
		{overlay_texture = "reinforced_nodes_default_stone_brick.png"})
	reinforced_nodes.register_reinforced_node("default:desert_stonebrick", "reinforced_nodes:desert_stonebrick",
		{overlay_texture = "reinforced_nodes_default_stone_brick.png"})
	reinforced_nodes.register_reinforced_node("default:sandstonebrick", "reinforced_nodes:sandstonebrick",
		{overlay_texture = "reinforced_nodes_default_stone_brick.png"})
	reinforced_nodes.register_reinforced_node("default:desert_sandstone_brick", "reinforced_nodes:desert_sandstone_brick",
		{overlay_texture = "reinforced_nodes_default_stone_brick.png"})
	reinforced_nodes.register_reinforced_node("default:silver_sandstone_brick", "reinforced_nodes:silver_sandstone_brick",
		{overlay_texture = "reinforced_nodes_default_stone_brick.png"})
	reinforced_nodes.register_reinforced_node("default:obsidianbrick", "reinforced_nodes:obsidianbrick",
		{overlay_texture = "reinforced_nodes_default_stone_brick.png"})
		
	if minetest.get_modpath("stairs") then
		local stair_reinforcement = function(stair_name)
			reinforced_nodes.register_reinforced_node("stairs:slab_"..stair_name, "reinforced_nodes:slab_"..stair_name,
				{overlay_texture = "reinforced_nodes_default_stone_brick.png"})
			reinforced_nodes.register_reinforced_node("stairs:stair_"..stair_name, "reinforced_nodes:stair_"..stair_name,
				{overlay_texture = "reinforced_nodes_default_stone_brick.png"})
			reinforced_nodes.register_reinforced_node("stairs:stair_inner_"..stair_name, "reinforced_nodes:stair_inner_"..stair_name,
				{overlay_texture = "reinforced_nodes_default_stone_brick.png"})
			reinforced_nodes.register_reinforced_node("stairs:stair_outer_"..stair_name, "reinforced_nodes:stair_outer_"..stair_name,
				{overlay_texture = "reinforced_nodes_default_stone_brick.png"})
		end
		stair_reinforcement("stonebrick")
		stair_reinforcement("desert_stonebrick")
		stair_reinforcement("sandstonebrick")
		stair_reinforcement("desert_sandstone_brick")
		stair_reinforcement("silver_sandstone_brick")
		stair_reinforcement("obsidianbrick")		
	end
end