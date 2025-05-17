function load_level()
	levels = {}

	levels[1] = {
		player_position = { x = 370, y = 265 },
		larme_position = {
			[1] = { x = 395, y = 70 },
			[2] = { x = 667, y = 275 },
			[3] = { x = 102, y = 275 },
			[4] = { x = 395, y = 470 }
		},
		aureole_position = { x = 100, y = 100},
		ange_position = { x = 300, y = 300 }
	}
	levels[2] = {
		player_position = { x = 370, y = 265 },
		larme_position = {
			[1] = { x = 395, y = 70 },
			[2] = { x = 667, y = 275 },--toujours en metre 2 pour eviter le bug
			[3] = { x = 102, y = 275 },
			[4] = { x = 395, y = 470 }
		},
		aureole_position = { x = 100, y = 100},
		ange_position = { x = 300, y = 300 }
	}
end


function reset_level()
    local level = levels[player.level]
    player.x = level.player_position.x
    player.y = level.player_position.y

    local lp = level.larme_position
    if type(lp) == "table" and #lp > 1 then
        larme_indexes[player.level] = 1
        local pos = lp[1]
        objet.larme.x = pos.x
        objet.larme.y = pos.y
    else
        objet.larme.x = lp.x
        objet.larme.y = lp.y
    end

    objet.aureole.x = level.aureole_position.x
    objet.aureole.y = level.aureole_position.y

    load_mob()
    if player.level == 1 then
        spawn_piege(100, 100)
        spawn_piege(600, 400)
        spawn_ange(300, 300)
    elseif player.level == 2 then
        spawn_ange(400, 400)
        spawn_ange(200, 200)
        spawn_piege(500, 300)
    end

    update_walls_level()
end













local larme_indexes = {}
local larme_timer = 0
local larme_interval = 2

just_loaded = true
function draw_level()
	local draw_function = _G["draw_level_" .. tostring(player.level)]
	if draw_function then
		draw_function()
	end

	if just_loaded then
		reset_level()
		just_loaded = false
	end
end




function tp_larme(level, dt, nb_positions)
	larme_timer = larme_timer + dt
	if larme_timer >= larme_interval then
		larme_timer = 0

		-- Initialiser l'index si nécessaire
		if not larme_indexes[level] then
			larme_indexes[level] = 1
		end

		-- Incrémenter
		larme_indexes[level] = larme_indexes[level] + 1
		if larme_indexes[level] > nb_positions then
			larme_indexes[level] = 1
		end

		-- Appliquer la nouvelle position
		local pos = levels[level].larme_position[larme_indexes[level]]
		objet.larme.x = pos.x
		objet.larme.y = pos.y
	end
end

function select_tp_larme(dt)
	local level = player.level
	local nb_pos = #levels[level].larme_position or 1
	if nb_pos > 1 then
		tp_larme(level, dt, nb_pos)
	end
end

