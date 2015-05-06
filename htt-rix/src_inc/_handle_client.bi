sub thread_handleClient ( byval clientId as integer )
	dim sbuf as string, bbuf as ubyte
	dim reqType as string
	dim httpVersion as string
	dim reqFor as string
	dim header(0 to 0) as string, headerLineCount as uinteger
	dim fileToSend as string, mime as string
	dim getVars as string
	dim tmpFileUsed as byte
	dim request_uri as string
	dim mostHeaderSent as byte
	dim skipRunCheck as byte
	dim post_content_type as string, post_content_length as uinteger, post_data(0 to 0) as ubyte
	
	tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Thread running, waiting for input."
	
	'now sit around and wait to get the first line
	sbuf=netGetString(client(clientId), chr$(13)+chr$(10))
	
	'split it up
	spl=instr(sbuf," ")
	reqType=trim(left$(sbuf,spl-1))
	
	spl2=instr(spl+1,sbuf," ")
	reqFor=trim(mid$(sbuf,spl+1,spl2-spl-1))
	request_uri=reqFor
	
	spl3=instr(spl2+1,sbuf,"/")
	
	if not lcase$(trim(mid$(sbuf,spl2+1,spl3-spl2-1)))="http" then
		tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Illegal request, not HTTP: " + trim(mid$(sbuf,spl2+1,spl3-spl2-1)) +". Sending 400 Bad Request."	
		netSendString client(clientId), "HTTP/1.0 400 Bad Request", LINEBREAK
		mime="{THTML}"
		fileToSend=errorDir+"400.thtml"
		skipRunCheck=1
		goto parse
	end if
	
	httpVersion=trim(mid$(sbuf,spl3+1))
	
	'filter out get part, after ?
	spl=instr(reqFor, "?")
	if spl>0 then
		getVars=mid$(reqFor,spl+1)
		reqFor=left$(reqFor,spl-1)
	end if
	
	
	tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - HTTP "+httpVersion+" "+reqType+" request recieved for "+reqFor+". Waiting for additional header."
	
	reqType=lcase$(reqType)
	if reqType<>"get" and reqType<>"post" then
		tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Method not supported. Sending 405 Method Not Allowed."	
		netSendString client(clientId), "HTTP/1.0 405 Method Not Allowed", LINEBREAK
		mime="{THTML}"
		fileToSend=errorDir+"405.thtml"
		skipRunCheck=1
		goto parse
	end if
	
	
	headerLineCount=0
	do
		redim preserve header(0 to headerLineCount) as string
		sbuf=netGetString(client(clientId), LINEBREAK)
		header(headerLineCount)=sbuf
		headerLineCount+=1
		
		'look for special header here
		if reqType="post" then 'look for content-type field
			if left$(lcase$(sbuf),len("content-type:"))="content-type:" then
				post_content_type=trim(lcase$(mid$(sbuf,len("content-type:")+1)))
				tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Content type for post data: "+post_content_type
			end if
			if left$(lcase$(sbuf),len("content-length:"))="content-length:" then
				post_content_length=val(trim(lcase$(mid$(sbuf,len("content-length:")+1))))
				tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Content length for post data: "+str$(post_content_length)
			end if
		end if
	loop until sbuf=""
	
	'check if we recieved required headers, and do extra stuff if needed
	if reqType="post" then 'look for content-type field
		if len(post_content_type)=0 then 'check if we got content-type
			post_content_type="application/x-www-form-urlencoded"
			tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Missing header: Content type for post data, defaulting to application/x-www-form-urlencoded."
		end if
		if post_content_length=0 then 'check if we got content-length
			tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Critical missing header: Content length for post data. Sending 411."	
			netSendString client(clientId), "HTTP/1.0 411 Length Required", LINEBREAK
			mime="{THTML}"
			fileToSend=errorDir+"411.thtml"
			skipRunCheck=1
			goto parse
		end if
		
		'recieve post data
		redim post_data(0 to post_content_length-1) as ubyte
		for i=0 to post_content_length-1
			post_data(i)=netGetByte(client(clientId))
		next i
		
		'''''''''''''''''''''''''''
		''' TO BE REPLACED: This should be done with pipes, to send via stdin to the script handlers
		
		'save post data to a tmp file
		'fh=freefile
		'open tmpDir+right$(str_replace(".","-",str$(timer)),8)+".tmp" for binary as #fh 'short name, qb doesnt like them longer
		'	put #fh,1,post_data()
		'close
		'
		'if len(getVars)>0 then 
		'	getVars+="&"
		'end if
		'
		'getVars+="tmp_post_data_file="+tmpDir+right$(str_replace(".","-",str$(timer)),8)+".tmp"
		
		''' END TO BE REPLACED
		''''''''''''''''''''''''''''
	end if
	
	'virtual pathing
	reqFor=mapPath(reqFor)
	tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Maps to " + reqFor
	
	'stuff	
	if right$(reqFor,1)="/" then 'default file?
		for i=0 to ubound(DefaultFile)
			if hFileExists(wwwDir+reqFor+DefaultFile(i)) then goto foundDefFile
		next i
		tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Couldn't find any default file. Sending 404.  ("+reqFor+" - "+fileToSend+")"
		netSendString client(clientId), "HTTP/1.0 404 Not Found", LINEBREAK
		mime="{THTML}"
		fileToSend=errorDir+"404.thtml"
		skipRunCheck=1
		goto parse
		foundDefFile:
		reqFor+=DefaultFile(i)
		tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Request was for /, defaulting to "+DefaultFile(i)
	end if
	
	if left$(reqFor,1)="/" then reqFor=mid$(reqFor,2)
		
	fileToSend=wwwDir+reqFor
	
	if instr(fileToSend,"../") then 'dissallow relative pathing |TODO: Do this a prettier way. Point is it shouldn't be allowed to go above www dir.
		tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - 403 when client tried to access "+reqFor+" ("+fileToSend+")"
		netSendString client(clientId), "HTTP/1.0 403 Forbidden", LINEBREAK
		mime="{THTML}"
		fileToSend=errorDir+"403.thtml"
		skipRunCheck=1
	elseif hFileExists(fileToSend)=0 then 'does it not exist? 
		for i=0 to ubound(DefaultFile) 'try to see if it was a dir and one of those has a default file in it
			if hFileExists(fileToSend+"/"+DefaultFile(i)) then 
				fileToSend=fileToSend+"/"+DefaultFile(i)
				tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - File not found, but succesfully translated into directory. Sending 200 OK and header."
				netSendString client(clientId), "HTTP/1.0 200 OK", LINEBREAK
		
				mime=findMime(fileToSend)	
				goto parse
			end if
		next i
		'otherwise we send 404
		tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - 404 occoured for "+reqFor+" ("+fileToSend+")"
		netSendString client(clientId), "HTTP/1.0 404 Not Found", LINEBREAK
		mime="{THTML}"
		fileToSend=errorDir+"404.thtml"
		skipRunCheck=1
	else
		tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Request OK this far, sending 200 OK and header."
		netSendString client(clientId), "HTTP/1.0 200 OK", LINEBREAK
		
		mime=findMime(fileToSend)
	end if
	
	parse:
	
	'check if this mime is allowed to be accessed/executed here
	if skipRunCheck <> 1 then 'but not if we're told not to (errorpages)
		if mimeAllowedHere(fileToSend, mime) = 0 then
			fileToSend=errorDir+"disallow_execution.thtml"
			mime="{THTML}"
		end if
	end if
	
	'Set some fancy environment vars for php and thtml |TODO: This way doesnt work if server is under heavy use, since those environ vars would change all the time. So, find another way.
		setenviron("REQUEST_URI="+request_uri)
		setenviron("SCRIPT_NAME="+reqFor)
		setenviron("PHP_SELF="+reqFor)
		setenviron("QUERY_STRING="+getVars)
		setenviron("REMOTE_ADDR="+conv_lip_to_str(client_si(clientId).sin_addr))
		setenviron("REQUEST_TYPE="+ucase$(reqType))
		if reqType="post" then
			setenviron("CONTENT_TYPE="+trim$(lcase$(post_content_type)))
			setenviron("CONTENT_LENGTH="+trim$(str$(post_content_length)))
		end if
		
	'special cases, like PHP
	fileToSend=parseFile(fileToSend, clientId, getVars, mime, tmpFileUsed, mostHeaderSent, @post_data(0), post_content_length)
	
	if mostHeaderSent=0 then
		'send additional header here
		netSendString client(clientId), "Content-type: "+mime, LINEBREAK
		netSendString client(clientId), "Server: "+serverInfo, LINEBREAK
		netSendString client(clientId), "", LINEBREAK
	end if
	
	tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Header sent. Attempting to send requested file."

		
	'send requested file
	fh=freefile
	open fileToSend for binary as #fh
		dim bigBuf(lof(fh)) as ubyte
		get #fh,,bigBuf()
		send client(clientId), @bigBuf(0), len(bigBuf)*lof(fh), 0
	close #fh
	
	if tmpFileUsed=1 then
		kill tmpDir+"~"+conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ").tmp"
	end if

	
	'finish off	
	finish:
	tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Done transmitting. Shutting down socket."
	
	shutdown client(clientId), SD_BOTH
	
	tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Socket shutdown. Closing socket."
	
	closesocket client(clientId)
	
	tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Socket closed. Quiting thread."
	
	
	socketInUse(clientId)=0 'we're done using the socket, flag it as available
end sub

function parseFile(filename as string, clientId as integer, getVars as string, byref mime as string, byref tmpFileUsed as byte, byref mostHeaderSent as byte, postdata as ubyte pointer, postlen as uinteger) as string
	dim sbuf as string
	dim buf1 as string*1
	
	if mime="{PHP}" then '|TODO: Should be with some extension bla thing, so it's easier to add other script stuff. Maybe dlls loaded at runtime.
		'|TODO: Figure how to send along cookies, post vars and such things. And do it.
		
		tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - PHP has been called upon. Better do it."
	
		'split the get vars if any
		if len(getVars)>0 then
			lstSpl=0
			getPassOn$=""
			do
				spl=instr(lstSpl+1,getVars,"&")
				if not spl>0 then
					getPassOn$+=mid$(getVars,lstSpl+1)
					exit do
				else
					getPassOn$+=mid$(getVars,lstSpl+1,spl-lstSpl-1)+" "
					lstSpl=spl
				end if
			loop
		end if
		
		'shell phpDir+"php.exe "+filename+" "+getPassOn$+" >"+tmpDir+"~"+conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ").tmp"
		
		if postlen>0 then
			dim postdata_a(0 to postlen-1) as ubyte
			for i=0 to postlen-1
				postdata_a(i)=postdata[i]
			next
		end if
		
		fh=freefile
		open "PIPE:"+phpDir+"php.exe "+filename+" "+getPassOn$+" >"+tmpDir+"~"+conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ").tmp" for output as #fh
			put #fh,,postdata_a()
			'do
			'	get #fh, , buf1
			'	print #fh2,buf1;
			'loop until eof(fh)
		close #fh
		
		
		parsefile=tmpDir+"~"+conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ").tmp"
				
		netSendString client(clientId), "Server: "+serverInfo, LINEBREAK
		
		tmpFileUsed=1
		mostHeaderSent=1
	elseif mime="{QB}" then 'Qbasic
		tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - Qb is asked for. Dig it up."
	
		'convert all / dir seperators to \ or qb wont understand
		filename=str_replace("/","\", filename)
	
		shell qbDir+"qb.exe /RUN "+filename+" /CMD "+chr$(34)+getVars+chr$(34)+" > "+tmpDir+"~"+conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ").tmp"
		
		parsefile=tmpDir+"~"+conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ").tmp"
				
		netSendString client(clientId), "Server: "+serverInfo, LINEBREAK
		
		tmpFileUsed=1
		mostHeaderSent=1
	elseif mime="{THTML}" then 'Trix-html
		tolog conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ") - File is Trix-HTML, parsing it."
		
		'load page to tmp buffer
		sbuf=""		
		
		fh=freefile
		open filename for input as #fh
			do
				line input #fh, tmp$
				sbuf+=tmp$+LINEBREAK
			loop until eof(fh)
		close #fh
		
		'parse it
		sbuf=thtml_parse(sbuf, clientId, getVars)
		
		'write to tmp file
		fh=freefile
		open tmpDir+"~"+conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ").tmp" for output as #fh
			print #fh, sbuf
		close
		
		parsefile=tmpDir+"~"+conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ").tmp"
		mime="text/html"
		tmpFileUsed=1
	else
		parsefile=filename
	end if
end function







 