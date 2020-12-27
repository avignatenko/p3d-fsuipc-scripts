-- forward SB 0x66C7 to CLForceEnabled lvar for usage in AirManager

local bffcloffset = 0x66C7 -- this offset is set by AltBFF software (in settings)
local bffcllvar = "CLForceEnabled" -- this is consumed by AirManager to show status

ipc.createLvar(bffcllvar, 0)

function onCLActiveChanged(name, value)
  ipc.writeLvar(bffcllvar, value)
end

event.offset(bffcloffset, "SB", "onCLActiveChanged")
 