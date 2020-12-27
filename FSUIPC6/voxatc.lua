-- Send 'I' key when ident button is pressed in the cockpit (for VoxATC to process)
function onIdentPressed(name, value)
  if value == 1 then
	ipc.keypress(73) -- 'I' key
	--ipc.display("Sent ident key")
  end
end

event.Lvar("XpdrIdentSwitch", 30, "onIdentPressed") 