sub thread_houseKeeping (byval id as integer)
	'just loop around, have some breaks, and see if any interesting keys are pressed
	do
		sleep 500 'no hurries, so give other threads the most time
		k$=inkey$
		
		if k$=chr$(27) then
			tolog "HOUSEKEEPING: Server shutdown in "+str$(shutDownDelay)+" secs on local request. Unlocking run-level."
			runLvlLocked=0
			setRunLvl 0 'set run lvl 0 so no new clients are accepted
			endApp shutDownDelay 'but give threads some seconds to finish
			exit sub 'no reason to keep hanging around 
		end if
		
		checkForMessages
	loop
end sub

sub checkForMessages
	on error goto quitSub
	fh=freefile
	open "msg.dat" for input as #fh
		line input #fh, msg$
		
		cmd$=trim(mid$(msg$,12))
		
		stamp=val(left$(msg$,10))
		nowstamp=val(Left$(Date$, 2) + Mid$(Date$, 4, 2) + Left$(Time$, 2) + Mid$(Time$, 4, 2) + Right$(Time$, 2))
		
		if nowstamp<stamp+3 then 'we only care about the msg if its no older than 3 seconds.
			select case cmd$
				case "ACE shd" 'ace-rix tells us to shutdown
					tolog "HOUSEKEEPING: Server shutdown in "+str$(shutDownDelay)+" secs requested by ACE-rix. Unlocking run-level."
					runLvlLocked=0
					setRunLvl 0 'set run lvl 0 so no new clients are accepted
					endApp shutDownDelay 'but give threads some seconds to finish
			end select
		end if
		
	quitSub:
	
	on error goto 0
	close #fh
end sub

sub cleanUp
	'...
	'do various final clean up here
	'...
end sub

sub endApp (delay as uinteger)
	
	cleanUp
	
	dim totalD as uinteger
	do
		if totalD>=delay then end
		sleep 1000
		totalD+=1
		tolog "HOUSEKEEPING: Shutdown in "+str$(delay-totalD)
		
		if inkey$<>"" then
			tolog "HOUSEKEEPING: Forced imidiate shutdown during shutdown fase by local user. Quiting."
			end
		end if
	loop
end sub