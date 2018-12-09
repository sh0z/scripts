--[[

Almost a carbon copy of priest.lua with modifications done to work with RuneBlader.
Script is simple but tested and ran for over 8 hours at lulu village with no problems. 

REQUIREMENTS 
  Flurry - [1]
  WhirlingBlade - [4]
  Storm Sigil (or other sigils) - [V]
  Pet with auto item - Herb at 70%, Pot at 50% (or however you want)
  My build - https://imgur.com/a/Gp4NUBP


Direct Input Key Codes - http://www.flint.jp/misc/?q=dik&lang=en
Microsoft Virtual Key Codes - http://nehe.gamedev.net/article/msdn_virtualkey_codes/15009/

--]]

g_RuneBladerBot = nil

class 'CRuneBladerBot'
function CRuneBladerBot:__init(app)
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
  self.time_lastheal = 0
  self.time_bufmanager = 0
  self.time_queue = 0
  self.queuedkeys = { }
  
  print("CRuneBladerBot()") --debug
end

function CRuneBladerBot:Flurry()
  self:QueueKeyEvent(0x03)  -- 1
end

function CRuneBladerBot:WhirlingBlade()
  self:QueueKeyEvent(0x05) -- 4
end

function CRuneBladerBot:StormSigil()
  self:QueueKeyEvent(0x2F) -- V
end


function CRuneBladerBot:GetClientTime()
  return self.mainsystem:GetClientTime()
end

function CRuneBladerBot:QueueKeyEvent(key)
  local t = { vk = key, 
              state = 0, -- 0 awaiting, 1 = down, 2 = up (finished)
			  t = self:GetClientTime() 
			}
  self.queuedkeys[#self.queuedkeys+1] = t
end

function CRuneBladerBot:KeyPressManager()
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

function CRuneBladerBot:AttackManager(target)

   local dist = self:GetDistance(target)
   local pos = target:GetPos()
    
   if dist > 1 then
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
      
   if dist > 10 then
     -- enemy too far	 
	 --print("too far")
     return
   end

   if dist < 4 then	    -- Use Flurry when enemy is within melee range
     self:Flurry()
	 return
   end
   
   local spirit = self.myPC:GetSpirit()
   
   --print(string.format("attack!! %d", self:GetClientTime()))

   -- got him in my attack range!!   
   if spirit > 40 then --check if can use WhirlingBlade
    if (dist > 4 and dist < 8) then -- only use WhirlingBlade if target is between 5-8m
      self:WhirlingBlade()
    end
   else -- no spirt enough :((
     self:Flurry() -- no spirit or target is within melee range, use flurry instead
   end
end

function CRuneBladerBot:SkillManager(target)
  local t = self:GetClientTime() - self.time_lastheal
  if t < 400 then
    return
  end

  local health = self.myPC:GetHealth()
  local maxHealth = self.myPC:GetMaxHealth()
    
  local percent = 70
  local minHealth = (percent/100)*maxHealth

  self:BufManager()
  self:AttackManager(target)
  
  self.time_lastheal = self:GetClientTime()  
end

function CRuneBladerBot:Macro()
  self:QueueKeyEvent(0x14) -- T
end

function CRuneBladerBot:BufManager()
  local t = self:GetClientTime() - self.time_bufmanager
  if t < 1000*120 then -- reapply sigil every 2 minutes
    return
  end   
  
  self:StormSigil() 
  self.time_bufmanager = self:GetClientTime()
end

function CRuneBladerBot:DrawArea(camera, range, color, pos)
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

function CRuneBladerBot:GetDistance(obj)
  local p1 = self.game:GetMyPC():GetPos()
  local p2 = obj:GetPos()

  local fLen = (p2.x - p1.x) * (p2.x - p1.x) + (p2.y - p1.y) * (p2.y - p1.y) + (p2.z - p1.z) * (p2.z - p1.z);
  if fLen > 0 then
	return math.sqrt(fLen) / 100
  end
  return 0
end

function CRuneBladerBot:ListObjects()
  local x = 10
  local y = 100 
  local olddist = 999
  local target = nil
  local color = clRed
  
  if self.enabled then
    color = clGreen
  end

  self.fontObjectList:Draw(x,y,0,0, color, "[F1] Bot disabled")
  y = y + 10
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

function CRuneBladerBot:OnUpdate()
  --self.fontDesc:Draw(100,200,0,0, clGreen, string.format("MapID - %u", self.game:GetCurrentMapID()))
  
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
	self:DrawArea(self.camera, 3*100, clLightBlue, pos) --3m radius
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

function CRuneBladerBot:WindowProc(msg)
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

function RuneBladerBot_OnUpdate()
  g_RuneBladerBot:OnUpdate()
end

function RuneBladerBot_WindowProc(msg)
  g_RuneBladerBot:WindowProc(msg)
end

function Initialize()
  g_RuneBladerBot = CRuneBladerBot(g_App)  
  g_App:RegisterEventListener(EVENT_FRAMERENDER_UPDATE, RuneBladerBot_OnUpdate)
  g_App:RegisterEventListener(EVENT_WINDOWPROC, RuneBladerBot_WindowProc)
end

Initialize()
