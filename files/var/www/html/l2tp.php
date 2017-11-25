<?php
   $publicip=htmlspecialchars($_SERVER['REMOTE_ADDR']);
   $localip="192.251.226.19";
   $mac=htmlspecialchars(strtolower($_GET["primarymac"]));
   $port=htmlspecialchars(strtolower($_GET["port"]));
   $sessionid=sprintf("%d", hexdec(substr($mac, 8)));

   if(strlen($publicip) > 1 && strlen($mac) == 12 && $port > 9999) {
      $line=sprintf("/usr/local/bin/refresh-l2tp.sh %s %s %s", $mac, $publicip, $port);
      $retline=system($line, $rc);
      /*printf("%s %s %s %s\n", $filenameup, $sessionid, $publicip, $mac);*/
      /*printf("%s %s 10000\n", $sessionid, $publicip);*/
   }
?>
