sub thread_handleClient ( byval clientId as integer )
	dim sbuf as string
	dim user as string
	
	dim dcSocket As SOCKET
	Dim dcUdtAddr As sockaddr_in
	
	dim cur_Dir as string
	dim tType as string
	
	tType="A"
	
	tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Thread running, sending welcome message."
	
	fh=freefile
	open msgDir+"welcome.msg" for input as #fh
		do
			line input #fh, tmp$
			netSendString(client(clientId),"220-"+tmp$,LINEEND)
		loop while not eof(fh)
		netSendString(client(clientId),"220  ",LINEEND)
	close #fh
	
	tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Welcome msg sent, waiting for USER verb." 
	
	'wait for USER
	hcWaitForUSER:
	sbuf=netGetString(client(clientId), chr$(13)+chr$(10))
	
	if lcase$(left$(sbuf,4))="user" then
		user=mid$(sbuf,6)
		netSendString(client(clientId),"331 Supply password for user "+user,LINEEND)
	else
		netSendString(client(clientId),"503 Unacceptable at current phase",LINEEND)
		tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Client sent unexpected verb (not USER)."
		goto hcWaitForUSER
	end if
	
	tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - USER identification recieved, waiting for password."
	
	'wait for PASS
	hcWaitForPASS:
	sbuf=netGetString(client(clientId), chr$(13)+chr$(10))
	
	if lcase$(left$(sbuf,4))="pass" then
		pass$=mid$(sbuf,6,3)
		
		if authenticate(user,pass$)=1 then
			netSendString(client(clientId),"202 You are now logged in.",LINEEND)
			tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Client successfully authenticated."
			cur_Dir=getRootForUser(user)
			
			if cur_Dir="" then
				netSendString(client(clientId),"503 Root directory not configured for user. Aborting.",LINEEND)
				tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - CONF ERR: No root directory configured for " + user +"."
				goto finish
			end if
		else
			netSendString(client(clientId),"530 Authorization failed. Please proceed with USER.",LINEEND)
			tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Client failed to authenticate, waiting for USER verb."
			goto hcWaitForUSER
		end if
	else
		netSendString(client(clientId),"503 Unacceptable at current phase",LINEEND)
		tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Client sent unexpected verb (not PASS)"
		goto hcWaitForPASS
	end if
	
	do
		sbuf=netGetString(client(clientId), chr$(13)+chr$(10))
			
		'print sbuf
				
		spl=instr(sbuf," ")
		if spl>0 then
			cmd$=lcase$(left$(sbuf,spl-1))
			arg$=mid$(sbuf,spl+1)
		else
			cmd$=lcase$(sbuf)
			arg$=""
		end if
		
		select case cmd$
			case "port"
				tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Client requests data connection."
				
				dcSocket=opensocket(AF_INET, SOCK_STREAM, IPPROTO_TCP)

				spl=instr(arg$,",")
				ip1$=left(arg$,spl-1)
				
				spl2=instr(spl+1,arg$,",")
				ip2$=mid(arg$,spl+1,spl2-spl-1)
				
				spl=instr(spl2+1,arg$,",")
				ip3$=mid(arg$,spl2+1,spl-spl2-1)
				
				spl2=instr(spl+1,arg$,",")
				ip4$=mid(arg$,spl+1,spl2-spl-1)
				
				spl=instr(spl2+1,arg$,",")
				port1$=mid(arg$,spl2+1,spl-spl2-1)
				
				spl2=instr(spl+1,arg$,",")
				port2$=mid(arg$,spl+1,spl2-spl-1)
				
				'print ip1$,ip2$,ip3$,ip4$,port1$,port2$
					
				dcUdtAddr.sin_family = AF_INET
				dcUdtAddr.sin_addr.s_un_b.s_b1 = val(ip1$)
				dcUdtAddr.sin_addr.s_un_b.s_b2 = val(ip2$)
				dcUdtAddr.sin_addr.s_un_b.s_b3 = val(ip3$)
				dcUdtAddr.sin_addr.s_un_b.s_b4 = val(ip4$)
				dcUdtAddr.sin_port = htons(val(port1$)*256+val(port2$))

				if ( connect(dcSocket, @dcUdtAddr, len(dcUdtAddr)) = SOCKET_ERROR ) then
					tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Failed to create data connection."
					netSendString(client(clientId),"426 Failed to create data connection.",LINEEND)
				else
					tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Data connection created."
					netSendString(client(clientId),"200 PORT command ok.",LINEEND)
				end if
			
			case "list"
				tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Client requests directory listing."
				
				if dcSocket=0 then
					tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - No data connection opened."
					netSendString(client(clientId),"425 Must open data connection first.",LINEEND)
				else
					netSendString(client(clientId),"150 Starting directory transfer.",LINEEND)
					
					generateDirListBINLS(cur_Dir,dcSocket)
					tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Done sending directory listing. Closing data connection."	
					
					shutdown dcSocket, SD_BOTH
					closesocket dcSocket
					
					netSendString(client(clientId),"226 Data transfered.",LINEEND)
					
				end if
			
			case "cwd", "xcwd"
				if left$(aarg$,1)="/" then arg$=mid$(arg$,2)
				
				converted$=convertToRealDir(arg$,cur_dir)
				tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Client tries to change working dir to "+arg$+" ("+converted$+")"
				
				if checkPerm(user,converted$,UP_LIST)=1 then
					cur_dir=convertToRealDir(arg$,cur_dir)
					tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - WD changed."
					netSendString(client(clientId), "250 OK, "+cur_dir+chr$(34)+convertToVirtualDir(cur_dir, getRootForUser(user))+chr$(34)+" is now the current directory.", LINEEND)
				else
					tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Failed to change WD, permission denied or does not exists."
					netSendString(client(clientId), "550 Failed to change directory.", LINEEND)
				end if
			
			case "cdup"
				tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Client wants to go up one dir."
				
				directory$=convertToVirtualDir(cur_dir,getRootForUser(user))
				
				for p=len(directory$) to 1 step -1
					'if p=1 then 
					'	directory$="/"
					'	exit for
					'end if
					if mid$(directory$,p,1)<>"/" then
						directory$=left$(directory$,len(directory$)-1)
					else
						directory$=left$(directory$,len(directory$)-1)
						exit for
					end if
				next p
				
				if left$(directory$,1)="/" then directory$=mid$(directory$,2)
				
				cur_dir=convertToRealDir(directory$,getRootForUser(user))
				
				netSendString(client(clientId), "250 OK, "+cur_dir+chr$(34)+convertToVirtualDir(cur_dir, getRootForUser(user))+chr$(34)+" is now the current directory.", LINEEND)
				
			case "pwd", "xpwd"
				tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Requests current directory."
				netSendString(client(clientId), "250 "+chr$(34)+convertToVirtualDir(cur_dir, getRootForUser(user))+chr$(34)+" is current directory.", LINEEND)
				
			case "syst"
				tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Asks for host os info."
				netSendString(client(clientId),"215 "+hostType,LINEEND)
				
			case "noop"
				tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Sends 'no-operation'."
				netSendString(client(clientId),"200 Let the chit-chating continue.",LINEEND)
			
			case "quit"
				tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Client asks to quit session."
				netSendString(client(clientId),"221 Bye.",LINEEND)
				goto finish
				
			case "help"
				tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Client asks for help."
	
				fh=freefile
				open msgDir+"help.msg" for input as #fh
				do
					line input #fh, tmp$
					netSendString(client(clientId),"214-"+tmp$,LINEEND)
				loop while not eof(fh)
				netSendString(client(clientId),"214  ",LINEEND)
				close #fh
	
				tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Help message sent." 
			
			case "stat"
				tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Requests server status." 
			
				dcSt$="Yes"
				if dcSocket<>0 then dcSt$="No"
				
				typeSt$="BINARY IMAGE"
				if tType="A" then typeSt$="ASCII"
			
				'|Todo: Add "Connected to [hostname] ([IP]) string
				tosend$="211-FTP-rix ftp server status:" + LINEEND + _
						"211-"+serverId + LINEEND + LINEEND + _
						"211-Logged in as " + user + LINEEND + _
						"211-Type: " + typeSt$ + "; Structure: File; Transfer mode: Stream;" + LINEEND + _
						"211-Data connection: " + dcSt$ + LINEEND +_
						"211 End of status"
				
				netSendString(client(clientId),tosend$,LINEEND)
				
				tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Status info sent." 
			
			case else
				tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Client sent unsupported verb ("+cmd$+")."
				netSendString(client(clientId),"502 Verb not supported.",LINEEND)
			
			
		end select
	loop
	
''''''''''
''''''''''
'''''''''
''''''''''
	
	'finish off	
	finish:
	tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Done transmitting. Shutting down socket."
	
	shutdown client(clientId), SD_BOTH
	
	tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Socket shutdown. Closing socket."
	
	closesocket client(clientId)
	
	tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Socket closed. Quiting thread."
	
	
	socketInUse(clientId)=0 'we're done using the socket, flag it as available
end sub

function convertToVirtualDir(directory as string, root as string) as string
	converted$=str_replace("\","/",mid(directory,len(root)+1))
	if left$(converted$,1)="" then converted$="/"+converted$
	convertToVirtualDir=converted$
end function

function convertToRealDir(virtualDir as string, root as string) as string
	if right$(root,1)="/" then root=left$(root,len(root)-1)
	convertToRealDir=root+"\"+str_replace("/","\",virtualDir)
end function

function authenticate (user as string, pass as string) as byte
	authenticate=0
	
	'pwdMD5$=space$(32)
	'dim result as uinteger pointer
	'result = MD5_crc(strptr(pass), len(pass))
	'For i = 0 To 3 
'		pwdMD5$+=String$(8 - Len(Hex$(Result[i])), "0") + (Hex$(Result[i]))
	'Next i
	
	pwdMD5$=pass
	
	for u=0 to ubound(users)
		'print trim(pwdMD5$)+chr$(13)+chr$(10)+trim(users(u).pwd)+chr$(13)+chr$(10)
		if trim(user)=trim(users(u).username) and trim(pwdMD5$)=trim(users(u).pwd) then
			authenticate=1
			exit function
		end if
	next u
	
end function

function checkPerm (username as string, directory as string, checkFor as uinteger) as byte
	checkPerm=0
	if right$(directory,1)="\" then directory=left$(directory,len(directory)-1)
	
	'check specific
	for d=0 to ubound(dirConf)
		if lcase$(trim(dirConf(d).username))=lcase$(trim(username)) and lcase$(trim(dirConf(d).dir))=lcase$(trim(directory)) then
			if (dirConf(d).permissions and checkFor) = checkFor then
				checkPerm=1
				exit function
			end if
		end if
	next d
	
	'check for UP_SUBDIRS
	do
		for p=len(directory) to 1 step -1
			if p=1 then exit do
			if mid$(directory,p,1)<>"\" then
				directory=left$(directory,len(directory)-1)
			else
				directory=left$(directory,len(directory)-1)
				exit for
			end if
		next p
		
		for d=0 to ubound(dirConf)
			if lcase$(trim(dirConf(d).username))=lcase$(trim(username)) and lcase$(trim(dirConf(d).dir))=lcase$(trim(directory)) then
				if (dirConf(d).permissions and UP_SUBDIRS) = UP_SUBDIRS and (dirConf(d).permissions and checkFor) = checkFor then
					checkPerm=1
					exit function
				end if
			end if
		next d
	loop
end function

sub generateDirListBINLS(directory as string, sock as SOCKET)
	dim entry as string
	dim monthKey(1 to 12) as string
	monthKey(1)="Jan":monthKey(2)="Feb":monthKey(3)="Mar":monthKey(4)="Apr":monthKey(5)="May"
	monthKey(6)="Jun":monthKey(7)="Jul":monthKey(8)="Aug":monthKey(9)="Sep":monthKey(10)="Oct"
	monthKey(11)="Nov":monthKey(12)="Dec"
	
	
	if right$(directory,1)="\" then directory=left$(directory,len(directory)-1)
	
	fh=freefile
	open "PIPE:dir " + chr$(34) + directory + "\*.*" + chr$(34) + " /-C /OG /N" for input as #fh
		line input #fh,tmp$
		line input #fh,tmp$
		line input #fh,tmp$
		line input #fh,tmp$
		line input #fh,tmp$
		
		do
			line input #fh,tmp$
			
			entry=""
			
			alldate$=trim(left$(tmp$,10))
			clock$=trim(mid$(tmp$,13,5))
			sizest$=trim(mid$(tmp$,22,14))
			ename$=trim(mid$(tmp$,37))
			
			if val(alldate$)>0 then
				day$=left$(alldate$,2)
				month$=mid$(alldate$,4,2)
				year$=right$(alldate$,4)
			
				yearNow$=right$(date,4)
			
				dateToSend$=monthKey(val(month$))+" "+day$+" "
			
				if year$=yearNow$ then dateToSend$+=clock$
				if year$<>yearNow$ then dateToSend$+=" "+year$
			
				if lcase$(sizest$)="<dir>" then
					entry+="drwxr-xr-x 1 owner group "
					sizest$="0"
				else
					entry+="-rw-r--r-- 1 owner group "
				end if
				
				entry+=space$(13-len(sizest$))+sizest$
			
				entry+=" "+dateToSend$+" "+ename$
				
				'print entry
				
				netSendString sock, entry, LINEEND
			end if
			
		loop while not eof(fh)
	close #fh
end sub