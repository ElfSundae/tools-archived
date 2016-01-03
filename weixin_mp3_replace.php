<?php 
$dir = '/data/home/Desktop/wx/Downloaded';

$replace_file = rtrim($dir) . '/' . md5(time(NULL)) . '.mp3';


$files = scandir($dir);
$total = count($files);
$i = 0;

foreach ($files as $f) {
        $pathinfo = pathinfo($f);
        if (isset($pathinfo['extension']) && strtolower($pathinfo['extension']) == 'mp3') {
                $i++;
                echo "[ $i / $total ]: {$pathinfo['basename']}\n";
                $mp3_file = rtrim($dir, '/') . '/' . $f;
                // $handle = fopen($my_file, 'w') or die('Cannot open file:  '.$my_file);
//                 $data = 'This is the data';
//                 fwrite($handle, $data);
        }
}
