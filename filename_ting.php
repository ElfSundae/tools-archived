<?php 

$dir = '/data/temp/test';

$files = scandir($dir);
foreach ($files as $f) {
        $pathinfo = pathinfo($f);
        $pos = strpos($pathinfo['basename'], '_');
        $sub = substr($pathinfo['basename'], 0, $pos);
        echo $sub . PHP_EOL;
        echo $pathinfo['basename']. PHP_EOL . PHP_EOL;
}