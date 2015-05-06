'''''''''''''''''''''''''''''''''''''''''
'' FTP-RIX/0.1 ftp server by RAJM 2005 
'' <plantasy.darkwizard.org> <runemoennike@gmail.com>
'''''
'''


#define LINEEND chr$(13)+chr$(10)
'chr$(15)+chr$(12)

'$dynamic
'$include: "win\winsock.bi"

'$include: "src_inc\_md5.bi"

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
declare function authenticate (user as string, pass as string) as byte
declare function getRootForUser (user as string) as string
declare sub generateDirListBINLS(directory as string, sock as SOCKET)
declare function convertToVirtualDir(directory as string, root as string) as string
declare function convertToRealDir(virtualDir as string, root as string) as string
declare function checkPerm (username as string, directory as string, checkFor as uinteger) as byte

'Run level handling
declare sub setRunLvl (lvl as integer)
declare sub lockRunLvl

'Threads
declare sub thread_handleClient (byval clientId as integer)
declare sub thread_houseKeeping (byval id as integer)

'Conf and stuff
declare sub loadConf

const UP_LIST=2^0, _ 
      UP_GET=2^1, _ 
	  UP_PUT=2^2, _ 
	  UP_DELETE=2^3, _ 
	  UP_RENAME=2^4, _ 
	  UP_OVERWRITE=2^5, _ 
	  UP_CREATEDIR=2^6, _
	  UP_REMDIR=2^7, _
	  UP_ISROOT=2^15, _
	  UP_SUBDIRS=2^16

const serverId="Version 1.0"
	  
type dirPermissionType
	username as string
	dir as string
	permissions as uinteger
end type

type userType field=1
	username as string*64
	pwd as string*32
end type
	  
dim shared maxCon as uinteger
dim shared conPort as uinteger

dim shared hostType as string

dim shared client(0 to maxCon) as SOCKET
dim shared client_si(0 to maxCon) as sockaddr_in
dim shared socketInUse(0 to maxCon) as byte

dim shared as string msgDir, anoDir, logDir
dim shared anoAllowed as byte, anoPermissions as uinteger

dim shared runLevel as integer, runLvlLocked as byte
dim shared shutDownDelay as uinteger

dim shared users(0 to 0) as userType
dim shared dirConf(0 to 0) as dirPermissionType

'default values
maxCon=100
conPort=80
msgDir="msgs\"
logDir="logs\"
anoDir=""
anoAllowed=0
shutDownDelay=5 'in secs
hostType="UNIX Type: L8"



dim hSocket As SOCKET
Dim udtAddr As sockaddr_in
Dim udtData As LPWSADATA
Dim lngRet As integer

'Init
tolog "--------------------------------"
tolog "Server started."
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