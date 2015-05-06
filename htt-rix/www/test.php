<?
if (isset($_GET['string']))
{
    echo "MD5 of '".$_GET['string']."' is: ";
    echo md5($_GET['string']);
}

?>

<p>
<p>
<form action="test.php" method="get">
<input name="string" size="25">
<input type="submit" value="MD5">
</form>
