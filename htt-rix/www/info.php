<?
echo "blbalbal";
$stdin = fopen('php://stdin', 'r');
echo "STDIN:".fgets($stdin,$_SERVER['CONTENT_LENGTH']);
fclose($stdin);

echo phpinfo();
?>
