--[[
REQUIREMENTS 
  CelestialLight - [A]
  HolyBlast - [S]
  HealingPrayer - [F]
  Macro - [T]
    - Shield of Archon
	- Celestial Guardian
	- Holy Relic
--]]


g_PriestBot = nil

class 'CPriestBot'
function CPriestBot:__init(app)
  self.app = app
  self.game = app.Game
  self.dx = app.DirectX
  self.fontDesc  = self.dx:CreateFont(18, 10, 400, false, "Arial")  
  self.fontObjectList  = self.dx:CreateFont(13, 8, 400, false, "Arial")  
  self.mouse = Vector2(0,0)
  self.myPC = nil  
  self.camera = nil
  self.mainsystem = self.game:GetMainSystem()
  self.objects = { {} }
  self.enabled = false
  self.state = 1
  self.time_lastheal = 0
  self.time_bufmanager = 0
  self.time_queue = 0
  self.queuedkeys = { }
  
  print("CPriestBot()") --debug
end

function CPriestBot:CelestialLight()
  self:QueueKeyEvent(0x1E)  -- A
  --self:QueueKeyEvent(0x2D)  -- X
end

function CPriestBot:HolyBlast()
  self:QueueKeyEvent(0x1F) -- S
  --self:QueueKeyEvent(0x2C) -- Z
end

function CPriestBot:HealingPrayer()
  self:QueueKeyEvent(0x21) -- F
  --self:QueueKeyEvent(0x2F) -- V
end

function CPriestBot:ShieldOfArchon()
  self:QueueKeyEvent(0x12) -- E
end

function CPriestBot:CelestialGuardian()
  self:QueueKeyEvent(0x10) -- Q
end

function CPriestBot:HolyRelic()
  self:QueueKeyEvent(0x11) -- W
  --self:QueueKeyEvent(0x14) -- T
end

function CPriestBot:GetClientTime()
  return self.mainsystem:GetClientTime()
end

function CPriestBot:QueueKeyEvent(key)
  local t = { vk = key, 
              state = 0, -- 0 awaiting, 1 = down, 2 = up (finished)
			  t = self:GetClientTime() 
			}
  self.queuedkeys[#self.queuedkeys+1] = t
end

function CPriestBot:KeyPressManager()
  for i = 1, #self.queuedkeys do
    local t = self.queuedkeys[i]
	if t.state == 0 then
	  local interval = self:GetClientTime() - self.time_queue
	  if interval > 50 then
	    t.state = 1
	    self.app:KeyDown(t.vk)
	    self.time_queue = self:GetClientTime()
	  end
	elseif t.state == 1 then
	  local interval = self:GetClientTime() - t.t
	  if interval > 50 then
	    self.app:KeyUp(t.vk)
		t.state = 2
	  end
    end    	
  end 
end

function CPriestBot:AttackManager(target)

   local dist = self:GetDistance(target)
   local pos = target:GetPos()
    
   if dist > 2 then
     local out = Vector3(0,0,0)
	 if self.camera:WorldToScreen(pos, out) then
		local screen = Vector2(out.x,out.y)
		self.game:Move2D(screen)
	 end
   end
   
   local _floor = math.abs(pos.z - self.myPC:GetPos().z)/100
  
   if _floor > 1 then -- 1m above or below of local pc
   
     -- can't hit :((
     return
   end
      
   if dist > 8 then
     -- enemy too far	 
	 --print("too far")
     return
   end

   if dist > 4 then	    -- enemy only in celestial light (8m range)
     self:CelestialLight()
	 return
   end
   
   local spirit = self.myPC:GetSpirit()
   
   --print(string.format("attack!! %d", self:GetClientTime()))

   -- got him in my attack range!!   
   if spirit > 45 then --check if can use holyblast
     self:HolyBlast()
   else -- no spirt enough :((
     self:CelestialLight()
   end
end

function CPriestBot:SkillManager(target)
  local t = self:GetClientTime() - self.time_lastheal
  if t < 400 then
    return
  end

  local health = self.myPC:GetHealth()
  local maxHealth = self.myPC:GetMaxHealth()
    
  local percent = 70
  local minHealth = (percent/100)*maxHealth
  
  --print(string.format("%f %f", health, minHealth))
  
  --print("min health %f", minHealth)
      
  if health < minHealth then
    self:HealingPrayer()
  else
    self:BufManager()
    self:AttackManager(target)
  end
  
  self.time_lastheal = self:GetClientTime()  
end

function CPriestBot:Macro()
  self:QueueKeyEvent(0x14) -- T
end

function CPriestBot:BufManager()
  local t = self:GetClientTime() - self.time_bufmanager
  if t < 1000*1 then --every 10s
    return
  end
  --self:ShieldOfArchon()
  --self:CelestialGuardian()
  --self:HolyRelic()
  self:Macro()
  self.time_bufmanager = self:GetClientTime()
end

function CPriestBot:DrawArea(camera, range, color, pos)
  local step = (math.pi * 2) / 30 -- 30 is the precision, a higher value will increase a lot the cpu usage
  local a = 0.0;
  
  local sp = Vector3(0,0,0)
  local ep = Vector3(0,0,0)
	
  local oldpos = Vector3(0,0,0)
  local newpos = Vector3(0,0,0)
  
  if not camera:WorldToScreen(pos, newpos) then --first checks if the object is in screen space
    return
  end
        
  repeat  
    oldpos.x = (range * math.cos(a)) + pos.x
    oldpos.y = (range * math.sin(a)) + pos.y
    oldpos.z = pos.z
	
	a = a + step
	
	newpos.x = (range * math.cos(a)) + pos.x
	newpos.y = (range * math.sin(a)) + pos.y
	newpos.z = pos.z
  	    		
	if camera:WorldToScreen(newpos, sp) and camera:WorldToScreen(oldpos, ep) then	  
	  self.dx:Draw2DLine(sp.x,sp.y,ep.x,ep.y,1, color)
	end		
  until a >= math.pi * 2
end

function CPriestBot:GetDistance(obj)
  local p1 = self.game:GetMyPC():GetPos()
  local p2 = obj:GetPos()

  local fLen = (p2.x - p1.x) * (p2.x - p1.x) + (p2.y - p1.y) * (p2.y - p1.y) + (p2.z - p1.z) * (p2.z - p1.z);
  if fLen > 0 then
	return math.sqrt(fLen) / 100
  end
  return 0
end

function CPriestBot:ListObjects()
  local x = 10
  local y = 100 
  local olddist = 999
  local target = nil
    
  self.fontObjectList:Draw(x,y,0,0, clYellow, string.format("count %d", #self.objects))
  
  local out = Vector3(0,0,0)
      
  for i = 1, #self.objects do
   
    local pc = self.objects[i]
	local oid = pc:GetOID()
     
	if pc:GetType() ~= 2 and  --drops are type 2 then we ignore them
	   oid > 0x10000 and  --npcs oids are usually < 0x10000, not a safe way but works
	   pc:GetHealth() > 0 and --ignore if dead
	   pc:GetMaxHealth() > 150000.0 
	   then --this check is for identifying targets in lulu village map, also, without this pets and players are also listed (an uid will be added soon)	   
	   if oid ~= self.myPC:GetOID() then	    
	    
		 local dist = self:GetDistance(pc)
	     local pos = pc:GetPos()
		 		 
		 y = y + 10
         self.fontObjectList:Draw(x,y,0,0, clYellow, string.format("%02.0f M", dist))
		 
		 if self.camera:WorldToScreen(pos, out) then		  
		   self.fontObjectList:Draw(out.x,out.y,0,0, clGreen, string.format("%1.0fM", dist))
         end
		 
	     if dist < olddist then
	       olddist = dist
		   target = pc
	     end
	   end
	end
  end  
  
  -- check if our target is visible on screen
  
  if target then 
    local pos = target:GetPos()
	local out = Vector3(0,0,0)
    if self.camera:WorldToScreen(pos, out) then
	  self:DrawArea(self.camera, 1*100, clRed, pos) -- 1m radius
	  return target
	end
  end  
end

function CPriestBot:OnUpdate()
  --self.fontDesc:Draw(100,200,0,0, clGreen, string.format("MapID - %u", self.game:GetCurrentMapID()))
  
  local color = clRed
  local sBotStatus = "OFF"
  
  if self.enabled then
    sBotStatus = "ON"
	color = clGreen
  end
    
  self.fontObjectList:Draw(10,90,0,0, color, string.format("[F2] PriestBot %s", sBotStatus))
  
  if not self.enabled then
    return
  end

  
  self.myPC = self.game:GetMyPC()
  if not self.myPC then
    return
  end
  
  self.state = self.myPC:GetSubState()
  self.camera = self.game:GetCamera()
  
  self.objects = self.game:GetObjects()
  
  local out = Vector3(0,0,0)  
  local pos = self.myPC:GetPos()
    	
  if self.camera:WorldToScreen(pos, out) then
    self.fontObjectList:Draw(out.x,out.y,0,0, clYellow, string.format("%d", self.state))
	self:DrawArea(self.camera, 4*100, clLightBlue, pos) --4m radius
	self:DrawArea(self.camera, 8*100, clYellow, pos) --8m radius
  end    
  
  local target = self:ListObjects()
  
  if not self.enabled then
    return
  end  
  
  if not target then
    return
  end
  
  self:SkillManager(target)
 
  self:KeyPressManager()
end

function CPriestBot:WindowProc(msg)
   if msg.message == WM_KEYUP then
    if msg.wParam == VK_F2 then
      self.enabled = not self.enabled
	  self:KeyPressManager()
	end
  elseif msg.message == WM_MOUSEMOVE then
    self.mouse.x = LOWORD(msg.lParam)
	self.mouse.y = HIWORD(msg.lParam)
  end	
end

--------------- // -------------

function PriestBot_OnUpdate()
  g_PriestBot:OnUpdate()
end

function PriestBot_WindowProc(msg)
  g_PriestBot:WindowProc(msg)
end

function Initialize()
  g_PriestBot = CPriestBot(g_App)  
  g_App:RegisterEventListener(EVENT_FRAMERENDER_UPDATE, PriestBot_OnUpdate)
  g_App:RegisterEventListener(EVENT_WINDOWPROC, PriestBot_WindowProc)  
end

Initialize()
