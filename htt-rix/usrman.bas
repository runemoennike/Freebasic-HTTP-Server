''''''''''''''''''''''''
'' usrman/1.0 - User Database Management for HTT-rix by RAJM 2005
''
'' <runemoennike@gmail.com> <plantasy.darkwizard.org>
''''''''''''''''''''''''

'$dynamic
'$include: 'src_inc\_md5.bi'

declare function hFileExists( filename as string ) as integer

type userType
	username as string*64
	pwd as string*32
end type

dim shared users(0 to 0) as userType
dim shared userSaved(0 to 0) as byte

locate ,,1
print timer
print "User Database Management for HTT-rix"
print "(usrman/1.0)"
print

do
	input "Open which user database? (path and filename w/o extension) ", fn$
	fn$+=".htt-rix-usrdb"
	if hFileExists(fn$)=0 then
		while inkey$<>"": wend 
		print "Database does not exists, create? ([y]es)"; 
		print
		sleep: answer$=inkey$
		if lcase$(answer$)="y" then exit do
	else
		fh=freefile
		open fn$ for binary as #fh
			idx=0
			do
				redim preserve users(0 to idx+1) as userType
				redim preserve userSaved(0 to idx+1) as byte
				get #fh,,users(idx)
				userSaved(idx)=1
				idx+=1
			loop until eof(fh)
		close #fh
		exit do
	end if
loop


menu:
	print
	print "OPTIONS"
	print "[C]reate new user"
	print "[L]ist users in current database"
	print "[D]elete a user
	print "[S]ave changes to database"
	print "[E]xit"
	print ""
	sleep: answer$=inkey$
	
	select case lcase$(answer$)
		case "c"
			goto createUser
		case "l"
			goto listUsers
		case "d"
			goto deleteUser
		case "s"
			goto saveDB
		case "e"
			end
		case else
			goto menu
	end select
	
saveDB:
	fh=freefile
	open fn$ for binary as #fh
		for u=0 to ubound(users)
				if trim(users(u).username)<>"!Deleted!" then
					put #fh,,users(u)
				end if
				userSaved(u)=1
		next u
	close #fh
	
	print "Changes saved to disk."
goto menu

deleteUser:
	idx=0
	
	print "DELETE USER"
	input "Input user id to delete: (0 or blank to cancel) ", idx
	
	if idx=0 then goto menu
	
	users(idx-1).username="!Deleted!"
	userSaved(idx-1)=0
	
	print "User deleted."
goto menu

listUsers:
	print "USER LIST"
	
	for u=0 to ubound(users)
		if len(trim(users(u).username))>1 then
			print "("+str$(u+1)+") "+users(u).username;
			if userSaved(u)<>1 then print " *";
			print "  |  ";
		end if
	next u
	print
	print "*) Not saved to database."
goto menu

createUser:
	idx=ubound(users)
	redim preserve users(0 to idx+1) as userType
	redim preserve userSaved(0 to idx+1) as byte

	print "CREATE USER"
   createUserInpName:
	input "Username: ", users(idx).username
   	if users(idx).username="!Deleted!" then print "Illegal name for user.": goto createUserInpName
   	
   createUserInpPwd:
	input "Password: ", tmpPwd$
	input "  Repeat: ", tmpPwd2$
	
	if tmpPwd$<>tmpPwd2$ then print "Passwords do not match.": goto createUserInpPwd
	
	tmpPwdMD5$=""
	dim result as uinteger pointer
	result = MD5_crc(strptr(tmpPwd$), len(tmpPwd$))
	For i = 0 To 3 
	    tmpPwdMD5$+=String$(8 - Len(Hex$(Result[i])), "0") + (Hex$(Result[i]))
	Next i 
	
	users(idx).pwd=tmpPwdMD5$
	
	print "User created."
goto menu

'''''''''''''''''
''' Functions and subs

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


