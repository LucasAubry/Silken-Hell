function load_level()
	levels = {}

	levels[1] = {
		player_position = { x = 355, y = 265 },
		larme_position = { x = 395, y = 70 },
		aureole_position = { x = 100, y = 100}
	}
	levels[2] = {
		player_position = { x = 300, y = 200 },
		larme_position = { x = 395, y = 10 },
		aureole_position = { x = 100, y = 100}
	}
end


function reset_level()
	local level = levels[player.level]
	player.x = level.player_position.x
	player.y = level.player_position.y

	objet.larme.x = level.larme_position.x
	objet.larme.y = level.larme_position.y

	objet.aureole.x = level.larme_position.x
	objet.aureole.y = level.larme_position.y

	update_walls_level()
end


local just_loaded = true
function draw_level()
	if player.level == 1 then
		draw_level_1()
	elseif player.level == 2 then
		draw_level_2()
		if just_loaded then
			reset_level()
			just_loaded = false
		end
	elseif player.level == 3 then
		draw_level_3()
		if just_loaded then
			reset_level()
			just_loaded = false
		end
	elseif player.level == 4 then
		draw_level_4()
		if just_loaded then
			reset_level()
			just_loaded = false
		end
	elseif player.level == 5 then
		draw_level_5()
		if just_loaded then
			reset_level()
			just_loaded = false
		end
	elseif player.level == 6 then
		draw_level_6()
		if just_loaded then
			reset_level()
			just_loaded = false
		end
	elseif player.level == 7 then
		draw_level_7()
		if just_loaded then
			reset_level()
			just_loaded = false
		end
	elseif player.level == 8 then
		draw_level_8()
		if just_loaded then
			reset_level()
			just_loaded = false
		end
	elseif player.level == 9 then
		draw_level_9()
		if just_loaded then
			reset_level()
			just_loaded = false
		end
	elseif player.level == 10 then
		draw_level_10()
		if just_loaded then
			reset_level()
			just_loaded = false
		end
	end
end
