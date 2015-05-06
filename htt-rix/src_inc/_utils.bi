function conv_lip_to_str (IpStrct as in_addr) as string
	dim ret as string
	
	ret=str$(IpStrct.S_un_b.s_b1)
	ret+="."+str$(IpStrct.S_un_b.s_b2)
	ret+="."+str$(IpStrct.S_un_b.s_b3)
	ret+="."+str$(IpStrct.S_un_b.s_b4)
	
	conv_lip_to_str = ret
end function

sub tolog (msg as string)
	static initialTime as string, setInTimer as byte
	
	if setInTimer=0 then
		timenow$=time
		initialTime=left$(timenow$,2)+"."+mid$(timenow$,4,2)+"."+right$(timenow$,2)
		setInTimer=1
	end if
	
	fh=freefile
	open logDir+date+" "+initialTime+".log" for append as #fh
	print #fh, date+"/"+time+": "+msg
	print msg
	close #fh
end sub

function hFileExists( filename as string ) as integer
   dim f as integer

	hFileExists = 0
	
	on local error goto exitfunction
	
	f = freefile
	open filename for input as #f
	
	close #f

	hFileExists = -1

exitfunction:
    exit function
end function

function str_replace(find as string, replace as string, subject as string) as string
	do
		p=instr(subject,find)
		if p=0 then exit do
		
		lpart$=left$(subject,p-1)
		rpart$=mid$(subject,p+len(find))
		
		subject=lpart$+replace+rpart$
	loop
	
	str_replace=subject
end function