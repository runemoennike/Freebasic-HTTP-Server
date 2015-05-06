sub loadConf
	fh=freefile
	open "ftp-rix.conf" for input as #fh
		numUsers=0
		numDirConfs=0
		dCount=0
		
		do
			line input #fh, tmp$
			if instr(tmp$,"#") then	tmp$=left$(tmp$,instr(tmp$,"#")-1)
			tmp$=trim(tmp$)
			
			spl=instr(tmp$,":")
			if spl>1 then
				dCount+=1
								
				action$=trim(left$(tmp$,spl-1))
				args$=trim(mid$(tmp$,spl+1))
				
				select case lcase$(action$)
					case "setvar"
						spl=instr$(args$,"->")
						if spl>1 then
							var$=trim(left$(args$,spl-1))
							value$=trim(mid$(args$,spl+2))
							
							select case lcase$(var$)
								case "inport"
									conPort=val(value$)
								case "maxcons"
									maxCon=val(value$)
								case "shutdowndelay"
									shutDownDelay=val(value$)
								case "allowanonymous"
									anoAllowed=val(value$)
							end select
						end if
						
					case "setdir"
						spl=instr$(args$,"->")
						if spl>1 then
							var$=trim(left$(args$,spl-1))
							value$=trim(mid$(args$,spl+2))
							
							select case lcase$(var$)
								case "messages"
									msgDir=value$
								case "anonymous"
									anoDir=value$
								case "logs"
									logDir=value$
							end select
						end if
					
					case "adduserfile"
						on error goto cfaufIgnoreErr
						fh2=freefile
						open args$ for binary as #fh2
							do
								redim preserve users(0 to numUsers+1) as userType
								get #fh2,,users(numUsers)
								'print numUsers,trim(users(numUsers).username),trim(users(numUsers).pwd)
								numUsers+=1
							loop until eof(fh2)
						close #fh2
						
						cfaufIgnoreErr:
						on error goto 0
						
					case "setuserroot"
						spl=instr$(args$,"->")
						if spl>1 then
							var$=trim(left$(args$,spl-1))
							value$=trim(mid$(args$,spl+2))
							
							spl=instr$(value$," ")
							if spl>1 then
								perm$=lcase$(trim(left$(value$,spl-1)))
								fordir$=trim(mid$(value$,spl+1))
								if right$(fordir$,1)="\" then fordir$=left$(fordir$,len(fordir$)-1)
								
								' [L]ist, [G]et, [P]ut, [D]elete, [R]ename, [O]verwrite, [C]reate dir, [E]rase dir [S]ubdirs
								
								if instr(perm$,"l") then permInt=permInt or UP_LIST
								if instr(perm$,"g") then permInt=permInt or UP_GET
								if instr(perm$,"p") then permInt=permInt or UP_PUT
								if instr(perm$,"d") then permInt=permInt or UP_DELETE
								if instr(perm$,"r") then permInt=permInt or UP_RENAME
								if instr(perm$,"o") then permInt=permInt or UP_OVERWRITE
								if instr(perm$,"c") then permInt=permInt or UP_CREATEDIR
								if instr(perm$,"e") then permInt=permInt or UP_REMDIR
								if instr(perm$,"s") then permInt=permInt or UP_SUBDIRS
								
								permInt=permInt or UP_ISROOT
																
								redim preserve dirConf(0 to numDirConfs) as dirPermissionType
								dirConf(numDirConfs).username=var$
								dirConf(numDirConfs).dir=fordir$
								dirConf(numDirConfs).permissions=permInt
								numDirConfs+=1
							end if
						end if
				end select
			end if
		loop until eof(fh)
	close #fh
	tolog "LOAD: Interpreted "+str$(dCount)+" directives from conf file."
end sub

function getRootForUser (user as string) as string
	for d=0 to ubound(dirConf)
		if trim(dirConf(d).username)=trim(user) then
			if (dirConf(d).permissions and UP_ISROOT) = UP_ISROOT then
				getRootForUser=dirConf(d).dir
				exit function
			end if
		end if
	next d
	getRootForUser=""
end function