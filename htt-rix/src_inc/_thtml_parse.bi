function thtml_parse (subject as string, clientId as integer, getVars as string) as string
	dim tmpFileUsed as byte
	
	'simple replacements
	subject=str_replace("<!--:SERVER_SIGNATURE-->",serverSignature,subject)
	
	'unparsed includes |TODO: Allow for parsed includes
	pend=1
	do
		p=instr(pend,subject,"<!--:INCLUDE(")
		if p=0 then exit do
		pend=instr(p,subject,")-->")
		
		fn$=mid$(subject,p+len("<!--:INCLUDE("),pend-p-len("<!--:INCLUDE("))
		
		lpart$=left$(subject,p-1)
		rpart$=mid$(subject,pend+len(")-->"))
		
		sbuf$=""
		
		if hFileExists(wwwDir+fn$)<>0 then
			mime$=findMime(fn$)
			fn$=parseFile(wwwDir+fn$, clientId, getVars, mime$, tmpFileUsed, 0, 0, 0)
			
			fh=freefile
			open fn$ for input as #fh
				if mime$="{PHP}" then '''Skip header stuff that php adds
					do
						line input #fh, tmp$
					loop until tmp$=""
				end if
				do
					line input #fh, tmp$
					sbuf$+=tmp$+LINEBREAK
				loop until eof(fh)
			close #fh
			
			if tmpFileUsed then
				kill tmpDir+"~"+conv_lip_to_str(client_si(clientId).sin_addr) + "(" + str$(clientId) + ").tmp"
			end if
		else
			sbuf$="<br /><b>Internal Server Error: Could not include file, not found: "+wwwDir+fn$+"</b><br />"
		end if
		subject=lpart$+sbuf$+rpart$
	loop
	
	'enviroment vars replacements
	pend=1
	do
		p=instr(pend,subject,"<!--:ENV(")
		if p=0 then exit do
		pend=instr(p,subject,")-->")
		
		env$=mid$(subject,p+len("<!--:ENV("),pend-p-len("<!--:ENV("))
		
		lpart$=left$(subject,p-1)
		rpart$=mid$(subject,pend+len(")-->"))
		
		subject=lpart$+environ(env$)+rpart$
	loop
	
	thtml_parse=subject
end function