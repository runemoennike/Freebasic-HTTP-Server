''''''''''''''''''''''''
''''' FORM DATA HANDLER

	'''''
	'' GET handler
	DIM SHARED HTTPGETVARS(0 TO 0) AS STRING
	DIM SHARED HTTPGETVALUES(0 TO 0) AS STRING
	getst$ = ENVIRON$("QUERY_STRING")
	
	numVars = 0
	lstSpl = 0
	tmp$=""
	IF LEN(getst$) > 0 THEN
		'figure how many vars there are
		do
			spl=INSTR(lstSpl + 1, getst$, "&")
			if spl=0 then exit do
			numVars=numVars+1
			lstSpl=spl
		loop
		
		REDIM SHARED HTTPGETVARS(0 TO numVars) AS STRING
		REDIM SHARED HTTPGETVALUES(0 TO numVars) AS STRING
	
		'now do the splitting
		lstSpl = 0
		numVars = 0
		DO
			spl = INSTR(lstSpl + 1, getst$, "&")
			IF NOT spl > 0 THEN
				tmp$ = MID$(getst$, lstSpl + 1)
				eqpos=instr(tmp$,"=")
				HTTPGETVARS(numvars)=left$(tmp$,eqpos-1)
				HTTPGETVALUES(numvars)=mid$(tmp$,eqpos+1)
				EXIT DO
		ELSE
				tmp$ = MID$(getst$, lstSpl + 1, spl - lstSpl - 1)
				eqpos=instr(tmp$,"=")
				HTTPGETVARS(numvars)=left$(tmp$,eqpos-1)
				HTTPGETVALUES(numvars)=mid$(tmp$,eqpos+1)
				numVars = numVars + 1
				lstSpl = spl
			END IF
		LOOP
	END IF
	
	'unset used vars
	tmp$=""
	lstSpl=0
	numVars=0
	getst$=""
	eqpos=0
	'' END GET handler
	'''''
	
	''''''''''
	'' POST handler
	'' TO BE REDONE: When server sends post correctly, via stdin, this won't work anymore.
	
	if lcase$((ENVIRON$("REQUEST_TYPE")))="post" then
		DIM SHARED HTTPPOSTVARS(0 TO 0) AS STRING
		DIM SHARED HTTPPOSTVALUES(0 TO 0) AS STRING
		DIM SHARED HTTPRAWPOSTDATA as string
		
		postst$=space$(val(environ$("CONTENT_LENGTH")))
		
		fh=freefile
		open HTTPGETVALUES(ubound(HTTPGETVALUES)) for binary as #fh 'tmp_post_data_file is always the last entry
			get #fh,1,postst$
		close #fh
		
		if environ$("CONTENT_TYPE")="application/x-www-form-urlencoded" then
			'figure how many vars there are
			do
				spl=INSTR(lstSpl + 1, postst$, "&")
				if spl=0 then exit do
				numVars=numVars+1
				lstSpl=spl
			loop
			
			REDIM SHARED HTTPPOSTVARS(0 TO numVars) AS STRING
			REDIM SHARED HTTPPOSTVALUES(0 TO numVars) AS STRING
		
			'now do the splitting
			lstSpl = 0
			numVars = 0
			DO
				spl = INSTR(lstSpl + 1, postst$, "&")
				IF NOT spl > 0 THEN
					tmp$ = MID$(postst$, lstSpl + 1)
					eqpos=instr(tmp$,"=")
					HTTPPOSTVARS(numvars)=left$(tmp$,eqpos-1)
					HTTPPOSTVALUES(numvars)=mid$(tmp$,eqpos+1)
					EXIT DO
				ELSE
					tmp$ = MID$(postst$, lstSpl + 1, spl - lstSpl - 1)
					eqpos=instr(tmp$,"=")
					HTTPPOSTVARS(numvars)=left$(tmp$,eqpos-1)
					HTTPPOSTVALUES(numvars)=mid$(tmp$,eqpos+1)
					numVars = numVars + 1
					lstSpl = spl
				END IF
			LOOP
		elseif left$(environ$("CONTENT_TYPE"),len("multipart/formdata"))="multipart/formdata" then
			' |TODO: Write a handler for this.
		end if
		
		HTTPRAWPOSTDATA=postst$
		
		'unset used vars
		fh=0
		postst$=""
		numVars=0
		tmp$=""
		eqpos=0
		lstSpl=0
		spl=0
	end if
	'' END POST handler / TO BE REDONE
	''''''''
	
'''''''' END FORM DATA HANDLER
'''''''''''''''''''''''''''''''''''