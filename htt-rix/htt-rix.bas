'''''''''''''''''''''''''''''''''''''''''
'' HTT-RIX/0.5 http server by RAJM 2005 
'' <plantasy.darkwizard.org> <runemoennike@gmail.com>
'' 
'' * Limited php support (no post vars or cookies, yet)
''
'' * Medium-leveled qbasic implementation (get vars, post vars. Post vars in a cheaty way (via files), but works.)
''
'' * Trix-HTML simple server-passed html-enhancement
''
'' Known bugs ( I'd really appreciate help with these ones):
''
'' - |TODO: Fix threading problems, with mutexes.
'' (lotsa others todos throughout the source)
''
'' Version history:
'' 0.1: Works, can send html pages
'' 0.2: Php added. Everything worked great. I shouldnt have gone further.
'' 0.3: Thtml, conf files, and more. Various crappy bugs entered.
'' 0.4: Primitive qb implementation
'' 0.5: Execution control, POST (faked) to qbasic scripts, virtual pathing
'''''
'''


#define LINEBREAK chr$(13)+chr$(10)

'$dynamic
'$include: "win\winsock.bi"

'winsock-routines interfaces
declare function netSendByte(hSocket as integer, byteSend as ubyte) as integer
declare function netGetByte(hSocket as integer) as ubyte
declare function netSendString(hSocket as integer, stringSend as string, terminateSignal as string) as integer
declare function netGetString(hSocket as integer, terminateSignal as string) as string

'misc
declare function conv_lip_to_str (IpStrct as in_addr) as string
declare sub tolog (msg as string)
declare function hFileExists( filename as string ) as integer
declare sub endApp (delay as uinteger)
declare function str_replace(find as string, replace as string, subject as string) as string
declare sub cleanUp

'Run level handling
declare sub setRunLvl (lvl as integer)
declare sub lockRunLvl
declare sub checkForMessages

'Threads
declare sub thread_handleClient (byval clientId as integer)
declare sub thread_houseKeeping (byval id as integer)

'parsing
declare function parseFile(filename as string, clientId as integer, getVars as string, byref mime as string, byref tmpFileUsed as byte, byref mostHeaderSent as byte, postdata as ubyte pointer, postlen as uinteger) as string
declare function thtml_parse (subject as string, clientId as integer, getVars as string) as string

'Conf and stuff
declare sub loadConf
declare function findMime (filename as string) as string
declare function mimeAllowedHere(pathAndFile as string, mime as string) as byte
declare function mapPath(original as string) as string

const LCP_AUTH = 2^0
const LCP_ERRPAGES = 2^1


type lcpType
	directory as string
	permissions as uinteger 'see LCP_* constants
end type

type virtualPathType
	virtual as string
	mapsTo as string
end type

type runControlType
	mime as string
	where as string
	control as byte '-1=Disallow, 1=Allow
end type

type mimeMapType
	ext as string
	mime as string
end type

dim shared maxCon as uinteger
dim shared conPort as uinteger

dim shared client(0 to maxCon) as SOCKET
dim shared client_si(0 to maxCon) as sockaddr_in
dim shared socketInUse(0 to maxCon) as byte

dim shared as string wwwDir, phpDir, tmpDir, errorDir, logDir, qbDir
dim shared DefaultFile(0 to 0) as string
dim shared serverSignature as string, serverInfo as string
dim shared mimeMap(0 to 0) as mimeMapType, defaultMime as string
dim shared runControl(0 to 0) as runControlType
dim shared virtualPath(0 to 0) as virtualPathType
dim shared localConfPermissions(0 to 0) as lcpType

dim shared runLevel as integer, runLvlLocked as byte
dim shared shutDownDelay as uinteger

'default values
maxCon=100
conPort=80
wwwDir="www\" 'public dir
phpDir="php\" 'php executable path
qbDir="qb\"
tmpDir="tmp\" 'temporary dir
errorDir="errorpages\" 'dir containing error pages
logDir="logs\" 'dir to place log files in
DefaultFile(0)="index.html" 'default file if none given
serverSignature="<i>HTT-rix; server signature not set</i>"
serverInfo="HTT-rix; server info not set"
defaultMime="application/octet-stream"
shutDownDelay=5 'in secs




dim hSocket As SOCKET
Dim udtAddr As sockaddr_in
Dim udtData As LPWSADATA
Dim lngRet As integer

'Init
tolog "--------------------------------"
tolog "Server started."
'print str_replace("ASD","---","ASD12345ASD12345ASD12345ASD")
setRunLvl 0
loadConf

'WS Startup
lngRet = WSAStartup(MAKEWORD(2,2), @udtData)
if (lngRet <> INVALID_SOCKET) then
	tolog "MAIN: WS inited"
else
	tolog "MAIN: Couldn't init WS: " + str$(lngRet)
	setRunLvl 0
	lockRunLvl
end if

'Create listen socket
hSocket = opensocket(AF_INET, SOCK_STREAM, IPPROTO_TCP)
If (hSocket <> INVALID_SOCKET) Then
	tolog "MAIN: Socket created"	
else
	tolog "MAIN: Couldn't create socket: "+ str$( hSocket)
	setRunLvl 0
	lockRunLvl
end if


'Bind port
udtAddr.sin_family = AF_INET
udtAddr.sin_port = htons (conPort)
udtAddr.sin_addr.s_addr = htonl (INADDR_ANY)
lngRet=bind(hSocket, @udtAddr, len(udtAddr))
if (lngRet <> SOCKET_ERROR) then
	tolog "MAIN: Port bound"
else
	tolog "MAIN: Couldn't bind port: "+ str$( lngRet) + " and " + + str$(WSAGetLastError())
	setRunLvl 0
	lockRunLvl
end if

'Start listen
lngRet=listen(hSocket,2)
if (lngRet<>SOCKET_ERROR) then
	tolog "MAIN: Now listening"
else
	tolog "MAIN: Couldn't listen: "+ str$( lngRet) + " and " + + str$(WSAGetLastError())
	setRunLvl 0
	lockRunLvl
end if

'Housekeeping thread. has to be a thread, since we're using blocking socket stuff
threadcreate( @thread_houseKeeping, 0 )

'Wait for clients to connect
setRunLvl 1
freeSocket=0
do
	strcLen=len(client_si(freeSocket))
	client(freeSocket)=accept(hSocket, @client_si(freeSocket), @strcLen)
	
	if runLevel<1 then 
		tolog "MAIN: Could not accept client, run level too low. Waiting for higher run-level..."
		while runLevel<1: sleep 300: wend 'dont accept clients unless we're at least on runlevel 1
	end if
		
	if client(freeSocket)<>INVALID_SOCKET then
		'|TODO: figure out how to kill a thread and add a maximum execution time for files (especially now when qb files are usable).
		tolog conv_lip_to_str(client_si(freeSocket).sin_addr) + "(" + str$(freeSocket) + ") - Client connected."
		tolog conv_lip_to_str(client_si(freeSocket).sin_addr) + "(" + str$(freeSocket) + ") - Starting tread to take over handling of client."
		
		threadcreate( @thread_handleClient, freeSocket )
		
		socketInUse(freeSocket)=1
	end if
	
	do
		for freeSocket=0 to maxCon 'find a free socket for the next connection
			if socketInUse(freeSocket)<>1 then exit do '|TODO: This should work just by testing if =0, but for some weird reason, the var takes on strange values. This started when I added the conf loader part, or maybe the thtml parser...
		next
		sleep 100 'wait a lil, give the cpu a break
	loop 'keep trying if all are taken, one will free eventually
	
loop 


'$include: "src_inc\_handle_client.bi"
'$include: "src_inc\_housekeeping.bi"
'$include: "src_inc\_nethelper.bi"
'$include: "src_inc\_conf+misc.bi"
'$include: "src_inc\_runlvl.bi"
'$include: "src_inc\_utils.bi"
'$include: "src_inc\_thtml_parse.bi"