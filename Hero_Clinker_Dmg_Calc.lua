--<<summarizes all available damage (eb,dagon,spells)>>
--Подключение библиотеки
require("libs.Utils")

-- создаем таблицу
hero = {}

-- Шрифт
F16 = drawMgr:CreateFont("F16","Arial",16,500)

-- Таблицы урона скиллов
dmgL = {80,160,240,320}
dmgR = {100,175,250,325}
dmg = {400,500,600,700,800}


-- Главная функция
function Tick( tick )

-- Проверка играем ли мы, а также добавляем задержку в 200 мс.
	if not client.connected or client.loading or client.console or not SleepCheck() then return end
	Sleep(200)
	
-- Определняем своего героя
	local me = entityList:GetMyHero() 
	
-- Если нету героя тогда возращаемся обратно	
	if not me then return end
	
-- Проверка на конкретного героя (тинкера) героя
	if me.classId ~= CDOTA_Unit_Hero_Tinker then
		script:Disable()
		return
	end

-- Обозначаем способности
	local laser = me:GetAbility(1)
	local rocket = me:GetAbility(2)
	
-- Если оба скилла 0 уровня тогда возращаемся обратно
	if laser.level == 0 and rocket.level == 0 then
		return
	end

-- Определение дагона и эзериала
	local dagon = me:FindDagon()
	local eb = me:FindItem("item_ethereal_blade")
	
-- Рассчет урона с дагона в зависомти от его уровня
	if dagon then
		local lvl = string.match (dagon.name, "%d+")
		if not lvl then lvl = 1 end dmgD = dmg[lvl*1]
	end

-- Таблица героев
	local enemies = entityList:GetEntities({type=LuaEntity.TYPE_HERO, team = (5-me.team), illusion=false})
	
	--Для каждого юнита в таблице
		for i,v in ipairs(enemies) do
		
		local offset = v.healthbarOffset
		
		if offset == -1 then return end
		
		--Динамическая прорисовка текста
				if not hero[v.handle] then hero[v.handle] = {}			
					hero[v.handle].txt = drawMgr:CreateText(-20, - 45, 0xFFFFFFFF, "",F16) hero[v.handle].txt.visible = false hero[v.handle].txt.entity = v hero[v.handle].txt.entityPosition = Vector(0,0,offset)
				end	
			
				if v.visible and v.alive then
					local resist = v.magicDmgResist
					if laser.level == 0 then
						if v.health >  ((dmgR[rocket.level]) * (1 - resist)) then
							local hits = math.floor(v.health -  ((dmgR[rocket.level]) * (1 - resist)))
							hero[v.handle].txt.visible = true    hero[v.handle].txt.text = "No kill :" ..hits
						elseif v.health < ((dmgR[rocket.level]) * (1 - resist)) then
							hero[v.handle].txt.visible = true    hero[v.handle].txt.text = "Ezy kill"							
						end
					elseif rocket.level == 0 then
						if v.health >  dmgL[laser.level] then
							local hits = math.floor(v.health -  dmgL[laser.level])
							hero[v.handle].txt.visible = true    hero[v.handle].txt.text = "No kill :" ..hits
						elseif v.health < dmgL[laser.level] then
							hero[v.handle].txt.visible = true    hero[v.handle].txt.text = "Ezy kill"
						end
					elseif dagon then
						if eb then
							if v.health > (dmgL[laser.level] + 1.4*((dmgD + (me.intellectTotal*2+75) + dmgR[rocket.level]) * (1 - resist))) then		
								local hits = math.floor(v.health - (dmgL[laser.level] + 1.4*((dmgD + (me.intellectTotal*2+75) + dmgR[rocket.level]) * (1 - resist))))
								hero[v.handle].txt.visible = true    hero[v.handle].txt.text = "No kill :" ..hits
								elseif v.health < (dmgL[laser.level] + 1.4*((dmgD + (me.intellectTotal*2+75) + dmgR[rocket.level]) * (1 - resist))) then
								hero[v.handle].txt.visible = true    hero[v.handle].txt.text = "Ezy kill"
							end
						else
							if v.health > (dmgL[laser.level] + ((dmgD + dmgR[rocket.level]) * (1 - resist))) then		
								local hits = math.floor(v.health - (dmgL[laser.level] + ((dmgD+dmgR[rocket.level]) * (1 - resist))))
								hero[v.handle].txt.visible = true    hero[v.handle].txt.text = "No kill :" ..hits
							elseif v.health < (dmgL[laser.level] + ((dmgD + dmgR[rocket.level]) * (1 - resist))) then
								hero[v.handle].txt.visible = true    hero[v.handle].txt.text = "Ezy kill"
							end
						end
					elseif laser.level ~= 0 and rocket.level ~= 0 then
						if v.health > (dmgL[laser.level] + (dmgR[rocket.level] * (1 - resist))) then		
							local hits = math.floor(v.health - (dmgL[laser.level] + (dmgR[rocket.level] * (1 - resist))))
							hero[v.handle].txt.visible = true    hero[v.handle].txt.text = "No kill :" ..hits
						elseif v.health < (dmgL[laser.level] + (dmgR[rocket.level] * (1 - resist))) then
							hero[v.handle].txt.visible = true    hero[v.handle].txt.text = "Ezy kill"
						end
					else
						hero[v.handle].txt.visible = false
					end			
				else
					hero[v.handle].txt.visible = false
				end
		end
end

function GameClose()
	hero = {}
	collectgarbage("collect")	
end
 
script:RegisterEvent(EVENT_CLOSE,GameClose)
script:RegisterEvent(EVENT_TICK,Tick)

