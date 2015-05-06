print "Content-type: text/html"
print ""

print "Test of dynamicly qbasic generated html pages:<br>"

for a=1 to 5
	print "<font size='+" + ltrim$(str$(a)) + "'>font size" + str$(a) + "</font>"
next a

print "<p>GET string: " + command$
print "<p>Query-string: " + environ$("QUERY_STRING")

print "<p><form action='test.bas' method='get'>Type something here: <input name='text'> <input type='submit' value='Gogogo!'> </form>"


system