<?php
/* Credits: http://blog.derakkilgo.com/2009/06/07/send-a-file-via-post-with-curl-and-php/ */
$uploaddir = realpath('/var/local/rrd-traffic/') . '/';
$uploadfile = $uploaddir . basename($_FILES['file_contents']['name']);
echo '<pre>';
    if (move_uploaded_file($_FILES['file_contents']['tmp_name'], $uploadfile)) {
	chmod($uploadfile, 0664);
	echo "File is valid, and was successfully uploaded.\n";
    } else {
        echo "Possible file upload attack!\n";
    }
    echo 'Here is some more debugging info:';
    print_r($_FILES);
    echo "\n<hr />\n";
    print_r($_POST);
    print "</pre>\n";
?>
