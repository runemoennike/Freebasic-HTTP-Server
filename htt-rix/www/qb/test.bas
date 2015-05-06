PRINT "Content-type: text/html"
PRINT ""

'$DYNAMIC

'Parse the formdata: (Get, Post)
'$INCLUDE: 'www/qb/formdata.bi'


PRINT "Test of dynamicly qbasic generated html pages:<br>"

FOR a = 1 TO 5
PRINT "<font size='+" + LTRIM$(STR$(a)) + "'>font size" + STR$(a) + "</font>"
NEXT a

PRINT "<p>COMMAND$ string: " + COMMAND$
PRINT "<br>Query-string: " + ENVIRON$("QUERY_STRING")
print "<br>Raw post data: " + HTTPRAWPOSTDATA


print "<p><p>GET vars after GET-handler:"
for i=0 to ubound(HTTPGETVARS)
	print "<li>"+HTTPGETVARS(i)+" = "+HTTPGETVALUES(i)
next i

print "<p><p>POST vars after POST-handler:"
for i=0 to ubound(HTTPPOSTVARS)
	print "<li>"+HTTPPOSTVARS(i)+" = "+HTTPPOSTVALUES(i)
next i


PRINT "<p><form action='test.bas' method='get'>Type something here: <input name='test'> <input name='secondtest'> <input name='finaltest'> <input type='submit' value='Gogogo!'> </form>"


SYSTEM '<--- REMEMBER THAT! or the server will hang... '|TODO: Implement max. execution time on server

