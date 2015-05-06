sub loadConf
	fh=freefile
	open "htt-rix.conf" for input as #fh
		numMimes=0
		numDefFiles=0
		dCount=0
		numRunDirectives=0
		numVirPath=0
		numLocalAllowDirectives=0
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
								case "serversignature"
									ServerSignature=value$
								case "serverinfo"
									ServerInfo=value$
								case "mimenomap"
									DefaultMime=value$
								case "shutdowndelay"
									shutDownDelay=val(value$)
								case "mimenoext"
									redim preserve mimeMap(0 to numMimes) as mimeMapType
									mimeMap(numMimes).ext=":"
									mimeMap(numMimes).mime=value$
									numMimes+=1
							end select
						end if
						
					case "setdir"
						spl=instr$(args$,"->")
						if spl>1 then
							var$=trim(left$(args$,spl-1))
							value$=trim(mid$(args$,spl+2))
							
							select case lcase$(var$)
								case "publichtml"
									wwwDir=value$
								case "phpexecutable"
									phpDir=value$
								case "qbexecutable"
									qbDir=value$
								case "tmpfiles"
									tmpDir=value$
								case "errorpages"
									errorDir=value$
								case "logs"
									logDir=value$
							end select
						end if
						
					case "adddeffile"
						redim preserve DefaultFile(0 to numDefFiles) as string
						DefaultFile(numDefFiles)=args$
						numDefFiles+=1
						
					case "mapext"
						spl=instr$(args$,"->")
						if spl>1 then
							var$=trim(left$(args$,spl-1))
							value$=trim(mid$(args$,spl+2))
							
							redim preserve mimeMap(0 to numMimes) as mimeMapType
							mimeMap(numMimes).ext=var$
							mimeMap(numMimes).mime=value$
							numMimes+=1
						end if
						
					case "exeallow"
						spl=instr$(args$,"->")
						if spl>1 then
							var$=trim(left$(args$,spl-1))
							value$=trim(mid$(args$,spl+2))
							
							redim preserve runControl(0 to numRunDirectives) as runControlType
							runControl(numRunDirectives).mime=var$
							runControl(numRunDirectives).where=value$
							runControl(numRunDirectives).control=1
							numRunDirectives+=1
						end if
					
					case "exedisallow"
						spl=instr$(args$,"->")
						if spl>1 then
							var$=trim(left$(args$,spl-1))
							value$=trim(mid$(args$,spl+2))
							
							redim preserve runControl(0 to numRunDirectives) as runControlType
							runControl(numRunDirectives).mime=var$
							runControl(numRunDirectives).where=value$
							runControl(numRunDirectives).control=-1
							numRunDirectives+=1
						end if
					
					case "mappath"
						spl=instr$(args$,"->")
						if spl>1 then
							var$=trim(left$(args$,spl-1))
							value$=trim(mid$(args$,spl+2))
							
							redim preserve virtualPath(0 to numVirPath) as virtualPathType
							virtualPath(numVirPath).virtual=var$
							virtualPath(numVirPath).mapsTo=value$
							numVirPath+=1
						end if
					
					case "AllowLocal"
						spl=instr$(args$,"->")
						if spl>1 then
							var$=trim(left$(args$,spl-1))
							value$=trim(mid$(args$,spl+2))
							
							redim preserve localConfPermissions(0 to numLocalAllowDirectives) as lcpType
							localConfPermissions(numLocalAllowDirectives).directory=var$
							
							select case lcase$(value$)
								case "auth"
									localConfPermissions(numLocalAllowDirectives).permissions=localConfPermissions(numLocalAllowDirectives).permissions or LCP_AUTH
								case "errorpages"
									localConfPermissions(numLocalAllowDirectives).permissions=localConfPermissions(numLocalAllowDirectives).permissions or LCP_ERRPAGES
							end select
							
							numLocalAllowDirectives+=1
						end if
				end select
			end if
		loop until eof(fh)
	close #fh
	tolog "LOAD: Interpreted "+str$(dCount)+" directives from conf file."
end sub

function findMime (filename as string) as string
	'first figure extension
	ext$=":" ' sign for no extension
	for p=len(filename) to 1 step -1
		if mid$(filename,p,1)="." then
			ext$=mid$(filename,p+1)
			exit for
		end if
	next p

	'then find
	for m=0 to ubound(mimeMap)
		if mimeMap(m).ext=ext$ then
			findMime=mimeMap(m).mime
			exit function
		end if
	next m
	
	'not found, set default
	findMime=defaultMime
end function

function mimeAllowedHere(pathAndFile as string, mime as string) as byte
	mimeAllowedHere=1
	override=0
	
	path$="/"
	for p=len(pathAndFile) to 1 step -1
		if mid$(pathAndFile,p,1)="/" then
			path$=left$(pathAndFile,p)
			path$=mid$(path$,len(wwwDir)+1)
			exit for
		end if
	next p
	
	for r=0 to ubound(runControl)
		if lcase$(trim(runControl(r).mime))=lcase$(trim(mime)) then
			if lcase$(trim$(runControl(r).where))=lcase$(trim$(path$)) then
				override=1
				if runControl(r).control=1 then
					mimeAllowedHere=1
				elseif runControl(r).control=-1 then
					mimeAllowedHere=0
				end if
			elseif trim(runControl(r).where)="*" and override=0 then
				if runControl(r).control=1 then
					mimeAllowedHere=1
				elseif runControl(r).control=-1 then
					mimeAllowedHere=0
				end if
			end if
		end if
	next r
	
end function

function mapPath(original as string) as string
	mappedTo$=original
	
	for v=0 to ubound(virtualPath)
		if virtualPath(v).virtual=left$(original,len(virtualPath(v).virtual)) then
			mappedTo$=virtualPath(v).mapsTo+mid$(original,len(virtualPath(v).virtual)+1)
			exit for
		end if
	next v
	
	mapPath=mappedTo$
end function