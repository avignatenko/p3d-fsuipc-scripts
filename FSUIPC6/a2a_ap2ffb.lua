  -- SB 0x66C0 - a/p roll engaged (read only - 0 off, 1 on)
  -- SB 0x66C1 - a/p pitch engaged (read only - 0 off, 1 on)
  -- SB 0x66C2 - a/p roll disengage (write only - 1 to disengage, will auto return to 0)
  -- SB 0x66c3 - a/p pitch disengage (write only - 1 to disengage, will auto return to 0)
  -- SB 0x66c6 - a/p pitch limits
  
function sleep(s)
  local ntime = os.clock() + s
  repeat until os.clock() > ntime
end

local lvars = { }


function pitchEngaged()
 return (lvars["ApAltModeCL"] > 0 and 1 or 0)
end

function rollEngaged()
  return (lvars["ApMode"] > 0 and 1 or 0)
end

function updateCustomFSUIPCOffsets()
  
  ipc.writeSB(0x66c0, rollEngaged())
  ipc.writeSB(0x66C1, pitchEngaged())
  
  --ipc.display("pitch:" .. pitchEngaged() .. ", roll: " .. rollEngaged())
  
end

function updateCustomDisconnect()

   if lvars["ApDisconnectSwitchCL"] == 0 and not toDisconnect then return end
   if lvars["ApDisconnectSwitchCL"] == 1 then toDisconnect = true return end
   

   -- send our disconnect
   setCustomPitchMode(0)
	
   -- send a2a disconnect
   ipc.writeLvar("ApDisconnectSwitch", 1)
   sleep(0.5)
   ipc.writeLvar("ApDisconnectSwitch", 0)
   
   toDisconnect = nil
end

function updateCustomPitchMode()

   if rollEngaged() == 0 then return end 
   
   if lvars["ApAltSwitchCL"] == 0 and not altModeToSet then return end
   if lvars["ApAltSwitchCL"] == 1 then altModeToSet = (lvars["ApAltModeCL"] == 1 and 0 or 1) return end
 
   setCustomPitchMode(altModeToSet) 
   altModeToSet = nil
end

function setCustomPitchMode(enable)

   ipc.writeLvar("ApAltModeCL", enable)
   ipc.writeLvar("ApAltLightCL", enable)   

   if enable == 0 then onPitchTrimWarning("", 0) end
 
end

function onLVarChanged(varnaname, value)
  --ipc.log("var: " .. varnaname .. ": " .. value)

  lvars[varnaname] = value
  
  updateCustomPitchMode()
  updateCustomDisconnect()
  updateCustomFSUIPCOffsets()
end

function onRollDisengage(varname, value)
  if value ~= 1 then return end
  if rollEngaged() == 0 then return end
  
  ipc.writeLvar("ApDisconnectSwitch", 1)
  sleep(0.5)
  ipc.writeLvar("ApDisconnectSwitch", 0)
  ipc.writeSB(0x66c2, 0)
end

function onPitchDisengage(varname, value)
  if value ~= 1 then return end
  if pitchEngaged() == 0 then return end
 
  ipc.writeLvar("ApAltSwitch", 1)
  sleep(0.5)
  ipc.writeLvar("ApAltSwitch", 0)
  ipc.writeSB(0x66c3, 0)
end

local soundref  = next

function onPitchTrimWarning(varname, value)

  local pitchUpLight = 0
  local pitchDnLight = 0

  
  if value == 1 or value == 2 then 
    pitchUpLight = 1
	pitchDnLight = 0
	
  end
  
  if value == 3 or value == 4 then
    pitchUpLight = 0
	pitchDnLight = 1
	
  end

  -- play sound
  if value ~= 0 then 
    if not sound.query(soundref) then soundref = sound.playloop("backcourse_marker") end
  else
    sound.stop(soundref)
  end
    
  ipc.writeLvar("ApTrimUpLightCL", pitchUpLight)
  ipc.writeLvar("ApTrimDnLightCL", pitchDnLight) 

  --ipc.display("pitch warn:" .. value)
 
end

function onTerminate()
  onPitchTrimWarning("", 0) -- stop sounds if any
end

-- create custom vars

ipc.createLvar("ApAltSwitchCL", 0)
ipc.createLvar("ApAltModeCL", 0)
ipc.createLvar("ApDisconnectSwitchCL", 0)
ipc.createLvar("ApAltLightCL", 0)
ipc.createLvar("ApTrimUpLightCL", 0)
ipc.createLvar("ApTrimDnLightCL", 0)

-- set def values

lvars["ApAltSwitchCL"] = ipc.readLvar("ApAltSwitchCL")
lvars["ApAltModeCL"] = ipc.readLvar("ApAltModeCL")
lvars["ApDisconnectSwitchCL"] = ipc.readLvar("ApDisconnectSwitchCL")
lvars["ApAltLightCL"] = ipc.readLvar("ApAltLightCL")
lvars["ApTrimUpLightCL"] = ipc.readLvar("ApTrimUpLightCL")
lvars["ApTrimDnLightCL"] = ipc.readLvar("ApLTrimDnLightCL")
lvars["ApMode"] = ipc.readLvar("ApMode")
 

-- subscribe
event.Lvar("ApAltSwitchCL", 30, "onLVarChanged")
event.Lvar("ApAltModeCL", 30, "onLVarChanged")
event.Lvar("ApMode", 30, "onLVarChanged")
event.Lvar("ApDisconnectSwitchCL", 30, "onLVarChanged")


event.offset(0x66c2, "SB", "onRollDisengage")
event.offset(0x66c3, "SB", "onPitchDisengage")
event.offset(0x66c6, "SB", "onPitchTrimWarning")
 
event.terminate("onTerminate") 
