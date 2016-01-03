<?php 
$rootDir = dirname(__FILE__);
$oldDir = $rootDir . '/Downloaded-mp3';
$newDir = $rootDir . '/Downloaded';

if (!file_exists($newDir)) @mkdir($newDir);
$list = scandir($oldDir);
if ($list) {
        $i = 0;
        $count = count($list) - 3; // .DS_Store . ..
        foreach ($list as $file) {
                $pathinfo = pathinfo($file);
                if (strtolower($pathinfo['extension']) == 'mp3') {
                        $i++;
                        $newFile = $newDir . '/' . $pathinfo['basename'];
                        echo "[ $i / $count ]";
                        if(file_put_contents($newFile, 'a')) {
                                echo ' OK ';
                        } else {
                                echo ' Error ';
                        }
                        echo "\t$newFile\n";
                }
        }   
        echo "Done.\n";
} else {
        die("Dir Error.\n");
}

