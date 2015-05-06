sub setRunLvl (lvl as integer)
	if runLvlLocked<>1 then
		runLevel=lvl
		tolog "HOUSEKEEPING: Setting run level "+str$(runLevel)
	else
		tolog "HOUSEKEEPING: Failed to change run level, due to lock."
		do: sleep 300: loop
	end if
end sub	

sub lockRunLvl 
	tolog "HOUSEKEEPING: Locking run level, at level "+str$(runLevel)
	runLvlLocked=1
end sub	