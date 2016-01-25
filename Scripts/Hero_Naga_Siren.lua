require("libs.Utils")
require("libs.ScriptConfig")

local config = ScriptConfig.new()
config:SetParameter("ToggleKey", "T", config.TYPE_HOTKEY)
config:Load()

local toggleKey = config.ToggleKey
local play = false

local Wheel = {}
Wheel.smallFont = drawMgr:CreateFont("defaultFont","Arial",25,1000)
Wheel.bigFont = drawMgr:CreateFont("defaultFont","Arial",40,1000)
Wheel.whilesize = 180*(math.floor(client.screenSize.x/160))/10

local main = {}
main.block = {}
main.ill = {}
main.sleep = {}
main.time = nil
main.stage = nil
main.action = 0
main.good = {Vector(1625,-3690,256),Vector(3136,-3472,256),Vector(3080,-4664,256),Vector(-279,-2975,128),Vector(-1191,-4100,128)}
main.bad = {Vector(-4491,3538,256),Vector(-3062,4595,256),Vector(-308,3711,256),Vector(-1592,2600,256),Vector(1172,3298,256)}

function Tick(tick)

    if client.console or client.paused then return end

	local me = entityList:GetMyHero() 
	if not me then return end
	
	if activated then
		local func = {"Stop","Near Dire Jungle","Far Dire Jungle","Far Radiant Jungle","Near Radiant Jungle"}
		if not Wheel.Pos then
			Wheel.Pos = client.mouseScreenPosition
			Wheel.wheel = drawMgr:CreateRect(Wheel.Pos.x - Wheel.whilesize/2,Wheel.Pos.y - Wheel.whilesize/2,Wheel.whilesize,Wheel.whilesize,0x000000FF,drawMgr:GetTextureId("FWT/wheel"))
			Wheel.cursor = drawMgr:CreateRect(Wheel.Pos.x - Wheel.whilesize/4,Wheel.Pos.y - Wheel.whilesize/4,Wheel.whilesize/2,Wheel.whilesize/2,0x000000FF,drawMgr:GetTextureId("FWT/cursor"))
			Wheel.wheel.visible = true
			Wheel.cursor.visible = true
			Wheel.names = {}
			Wheel.recs = {}	
			for i,v in ipairs(func) do
				local alpha = (2*math.pi*(i - 1)/#func - math.pi/2)%(2*math.pi)
				local center = Wheel.Pos + Vector2D(85*math.cos(alpha),85*math.sin(alpha))
				local font = Wheel.smallFont
				name = v
				center = center - GetRelativePlacement(alpha,font,name)
				Wheel.names[i] = drawMgr:CreateText(center.x,center.y,0xD9D9D9FF,name,font)
				Wheel.names[i].visible = true
			end
		else
			local newPos = client.mouseScreenPosition
			local dist = GetDistance2D(Wheel.Pos,newPos)
			if dist > 38 then
				newPos = (newPos - Wheel.Pos) * 38 / dist + Wheel.Pos
			end		
			Wheel.cursor:SetPosition(newPos - Vector2D(Wheel.whilesize/4,Wheel.whilesize/4), Vector2D(Wheel.whilesize/2,Wheel.whilesize/2))
			local currentIndex = nil
			if dist >= 30 then
				currentIndex = math.floor(((math.atan2(Wheel.Pos.y - newPos.y,Wheel.Pos.x - newPos.x) - math.pi/2 + math.pi/#func)%(2*math.pi))/(2*math.pi/#func)) + 1
			end
			for i,v in ipairs(Wheel.names) do
				if i ~= currentIndex then
					if v.font.tall == Wheel.bigFont.tall then
						local alpha = (2*math.pi*(i - 1)/#func - math.pi/2)%(2*math.pi)
						local center = Wheel.Pos + Vector2D(85*math.cos(alpha),85*math.sin(alpha))
						center = center - GetRelativePlacement(alpha,Wheel.smallFont,name)
						v.font = Wheel.smallFont
						v.position = center
					end
				else
					if v.font.tall == Wheel.smallFont.tall then
						local alpha = (2*math.pi*(i - 1)/#func - math.pi/2)%(2*math.pi)
						local center = Wheel.Pos + Vector2D(85*math.cos(alpha),85*math.sin(alpha))
						center = center - GetRelativePlacement(alpha,Wheel.bigFont,name)
						v.font = Wheel.bigFont
						v.position = center
						main.action = i - 1
					end
				end
			end
		end
	elseif Wheel.Pos then
		Wheel.Pos = nil
		Wheel.wheel.visible = false
		Wheel.cursor.visible = false
		for i = 1,5 do
			if Wheel.names[i] then
				Wheel.names[i].visible = false
			end
		end
	end

	if SleepCheck() then
		if main.action ~= 0 then
			local side = GetSide()
			local illusion = entityList:GetEntities({type = LuaEntity.TYPE_HERO,team = me.team,illusion = true,alive = true, controllable=true})
			if not main.time then main.time = client.gameTime end
			if not main.stage then
				main.stage = true
				for i,v in ipairs(illusion) do
					local spot = GetSpots(v,side)
					if type(spot) == "table" then
						main.block[spot[2]] = true
						v:Move(spot[1],false)	
						v:AttackMove(spot[1],true)
					end					
				end	
				Sleep(1000)
				return
			else
				for i,v in ipairs(illusion) do
					if not main.ill[i] then
						if (v.activity == LuaEntityNPC.ACTIVITY_IDLE or v.activity == LuaEntityNPC.ACTIVITY_IDLE1) and v.recentDamage == 0 then
							if not main.sleep[i] then
								main.sleep[i] = tick + 1000
							end
							if main.sleep[i] < tick then
								local spot = GetSpots(v,side)
								if type(spot) == "table" then
									main.block[spot[2]] = true
									v:Move(spot[1],false)	
									v:AttackMove(spot[1],true)
									main.ill[i] = true
								else
									v:AttackMove(me.position)
								end
							end
						else 
							main.sleep[i] = nil
						end
					end
				end
			end
			if client.gameTime - main.time > 30 then 
				main.time = nil
				main.action = 0
				main.stage = false
				main.block = {}
				main.ill = {}
				main.sleep = {}
			end
		elseif main.stage then
			main.time = nil
			main.stage = false
			main.block = {}
			main.ill = {}
			main.sleep = {}
		end		
		Sleep(100)
	end
	
end

function Key(msg,code)
	if client.chat or client.console then return end
	if msg == KEY_DOWN and code == toggleKey then
		activated = true
	else 
		activated = false
	end
end

function GetSpots(ent,tab)
	local sp = nil
	if main.action == 1 or main.action == 4 then
		local distance = 20000		
		for k,l in ipairs(tab) do	
			if not main.block[k] then
				local dis = ent:GetDistance2D(l)
				if distance > dis then
					distance = dis
					sp = {l,k}
				end
			end
		end
	else
		local distance = 0
		for k,l in ipairs(tab) do	
			if not main.block[k] then
				local dis = ent:GetDistance2D(l)
				if distance < dis then
					distance = dis
					sp = {l,k}
				end
			end
		end
	end
	return sp
end

function GetSide()
	if main.action > 2 then
		return main.good
	else
		return main.bad
	end
end

function GetRelativePlacement(alpha,font,text)
	local alphaR = alpha/math.pi
	if alphaR < .25 then
		return Vector2D(0,2*(.25 - alphaR)*font:GetTextSize(text).y)
	elseif alphaR < .5 then
		return Vector2D(4*(alphaR - .25)*font:GetTextSize(text).x/2,0)
	elseif alphaR < .75 then
		return Vector2D(2*(alphaR - .25)*font:GetTextSize(text).x,0)
	elseif alphaR < 1.25 then
		return Vector2D(font:GetTextSize(text).x,2*(alphaR - .75)*font:GetTextSize(text).y)
	elseif alphaR < 1.75 then
		return Vector2D(2*(1.75 - alphaR)*font:GetTextSize(text).x,font:GetTextSize(text).y)
	else
		return Vector2D(0,2*(2.25 - alphaR)*font:GetTextSize(text).y)
	end
end

function Load()
	if PlayingGame() then
		local me = entityList:GetMyHero()
		if me.classId == CDOTA_Unit_Hero_Naga_Siren then			
			play = true
			script:RegisterEvent(EVENT_KEY,Key)
			script:RegisterEvent(EVENT_TICK,Tick)
			script:UnregisterEvent(Load)
		else
			script:Disable()
		end
	end
end

function GameClose()
	main.block = {}
	main.ill = {}
	main.time = nil
	main.stage = false
	main.action = 0
	if play then
		script:UnregisterEvent(Key)
		script:UnregisterEvent(Tick)
		script:RegisterEvent(EVENT_TICK,Load)
		play = false
	end
end
 
script:RegisterEvent(EVENT_CLOSE,GameClose) 
script:RegisterEvent(EVENT_TICK,Load)
