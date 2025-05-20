function load_level()
	levels = {}

		levels[1] = {
			player_position = { x = 370, y = 265 },
			larme_position = {
				[1] = { x = 395, y = 70 },
				[2] = { x = 667, y = 275 },
				[3] = { x = 102, y = 275 },
				[4] = { x = 395, y = 490 }
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
				[4] = { x = 395, y = 490 }
			},
			aureole_position = { x = 100, y = 100},
			ange_position = { x = 300, y = 300 }
		}
		levels[3] = {
			player_position = { x = 370, y = 265 },
			larme_position = {
				[1] = { x = 395, y = 70 },
				[2] = { x = 667, y = 275 },--toujours en metre 2 pour eviter le bug
				[3] = { x = 102, y = 275 },
				[4] = { x = 395, y = 490 }
			},
			aureole_position = { x = 100, y = 100},
			ange_position = { x = 300, y = 300 }
		}
		levels[4] = {
			player_position = { x = 370, y = 265 },
			larme_position = {
				[1] = { x = 395, y = 70 },
				[2] = { x = 572, y = 130 },
				[3] = { x = 667, y = 275 },--toujours en metre 2 pour eviter le bug
				[4] = { x = 572, y = 420 },
				[5] = { x = 395, y = 490 },
				[6] = { x = 202, y = 420 },
				[7] = { x = 102, y = 275 },
				[8] = { x = 202, y = 130 }
			},
			aureole_position = { x = 100, y = 100},
			ange_position = { x = 300, y = 300 }
		}
		levels[5] = {
			player_position = { x = 370, y = 265 },
			larme_position = {
				[1] = { x = -50, y = -50 },
				[2] = { x = -50, y = -50 },
			},
			aureole_position = { x = 100, y = 100},
			ange_position = { x = 300, y = 300 }
		}
		levels[6] = {
			player_position = { x = 370, y = 265 },
			larme_position = {
				[1] = { x = 395, y = 70 },
				[2] = { x = 572, y = 130 },
				[3] = { x = 667, y = 275 },--toujours en metre 2 pour eviter le bug
				[4] = { x = 572, y = 420 },
				[5] = { x = 395, y = 490 },
				[6] = { x = 202, y = 420 },
				[7] = { x = 102, y = 275 },
				[8] = { x = 202, y = 130 }
			},
			aureole_position = { x = 100, y = 100},
			ange_position = { x = 300, y = 300 }
		}
		levels[7] = {
			player_position = { x = 370, y = 265 },
			larme_position = {
				[1] = { x = 395, y = 70 },
				[2] = { x = 572, y = 130 },
				[3] = { x = 667, y = 275 },--toujours en metre 2 pour eviter le bug
				[4] = { x = 572, y = 420 },
				[5] = { x = 395, y = 490 },
				[6] = { x = 202, y = 420 },
				[7] = { x = 102, y = 275 },
				[8] = { x = 202, y = 130 }
			},
			aureole_position = { x = 100, y = 100},
			ange_position = { x = 300, y = 300 }
		}
		levels[8] = {
			player_position = { x = 370, y = 265 },
			larme_position = {
				[1] = { x = 395, y = 70 },
				[2] = { x = 572, y = 130 },
				[3] = { x = 667, y = 275 },--toujours en metre 2 pour eviter le bug
				[4] = { x = 572, y = 420 },
				[5] = { x = 395, y = 490 },
				[6] = { x = 202, y = 420 },
				[7] = { x = 102, y = 275 },
				[8] = { x = 202, y = 130 }
			},
			aureole_position = { x = 100, y = 100},
			ange_position = { x = 300, y = 300 }
		}
		levels[9] = {
			player_position = { x = 370, y = 265 },
			larme_position = {
				[1] = { x = 395, y = 70 },
				[2] = { x = 572, y = 130 },
				[3] = { x = 667, y = 275 },--toujours en metre 2 pour eviter le bug
				[4] = { x = 572, y = 420 },
				[5] = { x = 395, y = 490 },
				[6] = { x = 202, y = 420 },
				[7] = { x = 102, y = 275 },
				[8] = { x = 202, y = 130 }
			},
			aureole_position = { x = 100, y = 100},
			ange_position = { x = 300, y = 300 }
		}
		levels[10] = {
			player_position = { x = 370, y = 265 },
			larme_position = {
				[1] = { x = 395, y = 70 },
				[2] = { x = 667, y = 275 },--toujours en metre 2 pour eviter le bug
				[3] = { x = 102, y = 275 },
				[4] = { x = 395, y = 490 }
			},
			aureole_position = { x = 100, y = 100},
			ange_position = { x = 300, y = 300 }
		}
	end

timer = 0
larme_float_timer = 0
larme_timer = 0
larme_interval = 1.5

function reset_level()

    load_mob()
    local level = levels[player.level]
    player.x = level.player_position.x
    player.y = level.player_position.y
	larme_timer = 0

	player.speed = 1
	player.freeze_timer = 0
	objet.larme_dropped = false


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

    if player.level == 1 then
		mob_lv1()
    elseif player.level == 2 then
		mob_lv2()
    elseif player.level == 3 then
		mob_lv3()
    elseif player.level == 4 then
		mob_lv4()
    elseif player.level == 5 then
		mob_lv5()
    elseif player.level == 6 then
		mob_lv6()
    elseif player.level == 7 then
		mob_lv7()
    elseif player.level == 8 then
		mob_lv8()
    elseif player.level == 9 then
		mob_lv9()
    elseif player.level == 10 then
		mob_lv10()
	elseif player.level == 11 then
		fin()
    end

    update_walls_level()
end














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



function update_larme_dos_ange()
	if player.level ~= 5 or objet.larme_dropped then return end

	for _, m in ipairs(mobs) do
		if m.type == "ange" and m.has_larme then
			local offset = 25
			local dir = m.dir or "down"

			if m.speed == 0 then
				objet.larme.x = m.x
				objet.larme.y = m.y + offset
			elseif dir == "up" then
				objet.larme.x = m.x
				objet.larme.y = m.y + offset
			elseif dir == "down" then
				objet.larme.x = m.x
				objet.larme.y = m.y - offset
			elseif dir == "left" then
				objet.larme.x = m.x + offset
				objet.larme.y = m.y
			elseif dir == "right" then
				objet.larme.x = m.x - offset
				objet.larme.y = m.y
			end

			break -- on a trouvé l'ange porteur, pas besoin de continuer
		end
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


function fin()
end
