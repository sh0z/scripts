g_PriestBot = nil

local BOTSTATE_NONE    = 0
local BOTSTATE_HEALING = 1

class 'CPriestBot'
function CPriestBot:__init(app)
  self.app = app
  self.game = app.Game
  self.dx = app.DirectX
  self.fontDesc  = self.dx:CreateFont(18, 10, 400, false, "Arial")  
  self.fontObjectList  = self.dx:CreateFont(10, 6, 400, false, "Arial")  
  self.mouse = Vector2(0,0)
  self.myPC = nil  
  self.camera = nil
  self.mainsystem = self.game:GetMainSystem()
  self.objects = { {} }
  self.enabled = false
  self.state = 1
  self.botstate = BOTSTATE_NONE
  self.time_lastheal = 0
  self.time_bufmanager = 0
  self.time_queue = 0
  self.queuedkeys = { }
  
  print("CPriestBot::Construct()")
end

function CPriestBot:GetClientTime()
  return self.mainsystem:GetClientTime()
end

function CPriestBot:QueueKeyEvent(key)
  local t = {
    vk = key,
	state = 0,
	t = self:GetClientTime()
  }
  self.queuedkeys[#self.queuedkeys+1] = t  
end

function CPriestBot:KeyPressManager()
  for i = 1, #self.queuedkeys do
    local t = self.queuedkeys[i]
	if t.state == 0 then
	  local interval = self:GetClientTime() - self.time_queue
	  if interval > 100 then
	    t.state = 1
	    self.app:KeyDown(t.vk)
	    self.time_queue = self:GetClientTime()
	  end
	elseif t.state == 1 then
	  local interval = self:GetClientTime() - t.t
	  if interval > 100 then
	    self.app:KeyUp(t.vk)
		t.state = 2
	  end
    end    	
  end 
end

function CPriestBot:HealingManager(target)
  if not target then
    return
  end
  
  local pos = target:GetPos()
  
  self:DrawArea(self.camera, 80, clRed, pos)

  local t = self:GetClientTime() - self.time_lastheal
  if t < 400 then
    return
  end

  local health = self.myPC:GetHealth()
  local maxHealth = self.myPC:GetMaxHealth()
  local spirit = self.myPC:GetSpirit()
  
  local relevo = math.abs(pos.z - self.myPC:GetPos().z)/100
  
  if health < maxHealth/2 + maxHealth/4 then
    self:QueueKeyEvent(0x2F) --V heal 
  else
    local dist = self:GetDistance(target)
	
	--if dist > 9 and self.myPC:GetEstamine() > 15  then
	  --self:QueueKeyEvent(0x2E) -- C flash jump
    --else
	if dist > 2 then
	  local out = Vector3(0,0,0)
	  if self.camera:WorldToScreen(pos, out) then
		local screen = Vector2(out.x,out.y)
		self.game:Move2D(screen)
	  end
	end
  
    if relevo < 1 then    
      if dist < 4 and spirit > 45 then
         self:QueueKeyEvent(0x2C) -- Z holy blast
	   else
	     if dist < 8 then
	       self:QueueKeyEvent(0x2D)  -- X celestial light
		 end
       end
    end
  end
      
  self.time_lastheal = self:GetClientTime()
end

function CPriestBot:BufManager(target)
  if not target then
    return
  end

  local t = self:GetClientTime() - self.time_bufmanager
  if t < 1000*10 then
    return
  end
  self:QueueKeyEvent(0x12) -- E sheield of archon
  self:QueueKeyEvent(0x10) -- Q celestial guardian
  self:QueueKeyEvent(0x14) -- T holy relic
  --print("bufs activated")
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

function CPriestBot:FindClosest(objs, obj)
  local result = nil
  local olddist = 999    
  for i = 1, #objs do
	local pc = objs[i]
	local dist = self:GetDistance(pc)
	local oid = pc:GetOID()
	
	if oid ~= self.myPC:GetOID() then
	  if oid ~= obj:GetOID() and dist < olddist then
	    olddist = dist
	    result = pc
	  end
    end	  
  end
  return result
end

function CPriestBot:IsInList(list, obj)
  for i = 1, #list do
    if obj:GetOID() == list[i]:GetOID() then
	  return true
	end
  end
  return false
end

function CPriestBot:LoadObjectList()  
  --[[local objs = self.game:GetObjects()
  self.objects = {}
  for i = 1, #objs do
	local pc = objs[i]
    local closest = self:FindClosest(objs, pc)
	if closest then 
	  if not self:IsInList(self.objects, closest) then
	    self.objects[#self.objects + 1] = closest
	  end
	end
  end
  --]]
  self.objects = self.game:GetObjects()
end

function CPriestBot:UseSkill(state)
  local t = self.game:GetMainSystem():GetClientTime() - self.skilltime
  
  
  
  if t > 200 then
    
	--g_App:KeyDown(0x2D)
    --g_App:KeyUp(0x2D)
		
	self.skilltime = self.game:GetMainSystem():GetClientTime()
  end
end

function CPriestBot:checkName(pc)
  local name = pc:GetNameA()
  return 
    string.find(name, "Gyatus") or 
	string.find(name, "Cursed") or 
	string.find(name, "Drake")
end

function CPriestBot:ShowObjectList()
  local x = 10
  local y = 100 
  local olddist = 999
  local target = nil

  self.fontObjectList:Draw(x,y,0,0, clYellow, string.format("count %d", #self.objects))
  
  --[[
  local closest = self:FindClosest(#self.objects, self.myPC)
  if closest then
    self:DrawArea(self.game:GetCamera(), 10, closest:GetPos())
  end--]]
  
  --self:DrawArea(self.game:GetCamera(), 10, closest:GetPos())
  

  local out = Vector3(0,0,0)  
  local selfPos = self.myPC:GetPos()
  local state = self.state
    
  if self.camera:WorldToScreen(selfPos, out) then
    local estamine = self.myPC:GetEstamine()
    self.fontObjectList:Draw(out.x,out.y,0,0, clYellow, string.format("%d %d", state, estamine))
	self:DrawArea(self.camera, 8*100, clYellow, selfPos)
  end
      
  for i = 1, #self.objects do
   
    local pc = self.objects[i]
	local oid = pc:GetOID()
    	
	if pc:GetType() ~= 2 and oid > 0x10000 and pc:GetHealth() > 0 and pc:GetMaxHealth() > 150000.0 then
	  if oid ~= self.myPC:GetOID() then	    
	    
		local dist = self:GetDistance(pc)
	    local pos = pc:GetPos()
		local out = Vector3(0,0,0)
		y = y + 10
        self.fontObjectList:Draw(x,y,0,0, clYellow, string.format("%02.0f M", dist))
		
		if self.camera:WorldToScreen(pos, out) then
		  --local relevo = math.abs(target:GetPos().z - self.myPC:GetPos().z)/100
		  
		  
		  
		  self.fontObjectList:Draw(out.x,out.y,0,0, clGreen, string.format("%1.0fM", dist))
        end
		
	    if dist < olddist then
	      olddist = dist
		  target = pc
	    end		
	  end
	end
  end  
  
  if self.camera:WorldToScreen(target:GetPos(), out) then
    return target
  end
  
  
  --self.fontObjectList:Draw(x,target_y,0,0, clRed, string.format("%1.0fm << target", olddist))
  
  --[[
  local dist = self:GetDistance(target)
  
  if dist < 4 then
    local out = Vector3(0,0,0)  
	local pos = target:GetPos()
    if camera:WorldToScreen(pos, out) then
      self.fontObjectList:Draw(out.x,out.y,0,0, clYellow, string.format("%1.0fm", dist))
	  self:UseSkill()
	end
  end
  --]]
end

function CPriestBot:ShowMessage(text)
  
  self.fontDesc:Draw(100,200,0,0, clGreen, string.format("MapID - %u", self.game:GetCurrentMapID()))
end

function CPriestBot:OnUpdate()
  self.fontDesc:Draw(100,200,0,0, clGreen, string.format("MapID - %u", self.game:GetCurrentMapID()))
  
  if not self.enabled then
    return
  end
  
  self.myPC = self.game:GetMyPC()
  if not self.myPC then
    return
  end
  --[[
  if not (self.myPC:GetHealth() > 0) then
    return
  end
  --]]
  
  self.state = self.myPC:GetSubState()
  self.camera = self.game:GetCamera()
  
  self.myPC:SetAttackSpeed(100)
  self.myPC:SetSpeed(200)
  self.myPC:SetJump(130)
	
  self:LoadObjectList()
  local target = self:ShowObjectList()
  self:HealingManager(target)
  self:BufManager(target)
  self:KeyPressManager()
end

function CPriestBot:WindowProc(msg)
   if msg.message == WM_KEYUP then
    if msg.wParam == VK_F2 then
      self.enabled = not self.enabled
	 
	  self.app:KeyUp(0x2C) -- Z holy blast
	  self.app:KeyUp(0x2F) --V heal 
      self.app:KeyUp(0x2D)  -- X celestial light
	end
  elseif msg.message == WM_MOUSEMOVE then
    self.mouse.x = tonumber(LOWORD(msg.lParam))
	self.mouse.y = tonumber(HIWORD(msg.lParam))
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
