#!/usr/bin/env php

<?php 

$part_length = 0x4000 - 0x2000;
if ($argc == 1) {
	echo "filename needed\n";
	exit(1);
}
$contents = file_get_contents($argv[1]);
$array = array();
for ($i = 0; $i < strlen($contents); $i += $part_length) {
	$array[] = chr(0x00) . chr(0x20) . substr($contents, $i, min(strlen($contents) - $i, $part_length));
}
$num = 1;
foreach ($array as $elem) {
	//echo strlen($elem) . "\n";
	$file_nums = $num . "";
	while (strlen($file_nums) < 4) {
		$file_nums = '0' . $file_nums;
		echo 'SOUND/' . $file_nums . ".RAW\n";
	}
	file_put_contents('SOUND/' . $file_nums . ".RAW", $elem);
	$num++;
}
echo count($array) . " file(s) saved\n";