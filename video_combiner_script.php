<?php

$output = array();

for ($i = 1; $i <= 6572; $i++) {
	$filename = $i . "";
	while (strlen($filename) < 4) { $filename = "0" . $filename; }
	$filename = "OUT2PT/" . $filename . ".BIN";
	echo $filename . "\n";
	$file_cont = substr(file_get_contents($filename), 2);
	$file_size = stat($filename)[7] - 2;
	if ($file_size >= 256) {
		$output[] = chr(255);
		echo $file_size - 255 . "\n";
		$output[] = chr($file_size - 255);
	} else {
		$output[] = chr($file_size);
		$output[] = chr(0);
	}
	$output[] = $file_cont;
}

file_put_contents("APPLE.VID", $output);