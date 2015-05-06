

function netSendByte(hSocket as integer, byteSend as ubyte)
	r=send(hSocket, @byteSend, len(byteSend), 0)
			
	if r<0 then 
		netSendByte=r
		exit function
	end if
end function

function netGetByte(hSocket as integer) as ubyte
	dim buf as ubyte
	recv(hSocket,@buf,1,0)
	netGetByte=buf
end function

function netSendString(hSocket as integer, stringSend as string, terminateSignal as string)
	dim buf as ubyte
		
	stringSend=stringSend+terminateSignal
		
	for i=1 to len(stringSend)
		buf=asc(mid$(stringSend,i,1))
		r=send(hSocket, @buf, len(buf), 0)
		
		if r<0 then 
			netSendString=r
			exit function
		end if
	next i
end function

function netGetString(hSocket as integer, terminateSignal as string) as string
	dim buf as ubyte
	dim rec as string
	do 
		buf=netGetByte(hSocket)
		rec=rec+chr$(buf)
	loop until right$(rec,len(terminateSignal))=terminateSignal
	netGetString=left$(rec,len(rec)-len(terminateSignal))
end function
