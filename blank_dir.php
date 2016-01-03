<?php 
$dir = '/data/temp/qwq_full_mp4/';


$files = array_diff(scandir($dir), array('.','..')); 
// foreach ($files as $f) {
//         $current_path = $dir . $f;
//         if (is_dir($current_path)) {
//                 $sub_files = array_diff(scandir($current_path), array('.','..')); 
//                 $wmv_file = '';
//                 foreach ($sub_files as $sub_f) {
//                         $pathinfo = pathinfo($sub_f);
//                         if (isset($pathinfo['extension']) && strtolower($pathinfo['extension']) == 'wmv') {
//                                 $wmv_file = $current_path . '/' . $sub_f;
//                                 //echo '[+]' . $wmv_file . PHP_EOL;
//                                 
//                                 break;
//                         }
//                 }
//                 if (!empty($wmv_file)) {
//                         //echo $current_path . PHP_EOL;
//                         $new_file = $current_path . '/' . $f . '.wmv';
//                         //echo $new_file . PHP_EOL;
//                         rename($wmv_file, $new_file);
//                 } else {
//                         system('/bin/rm -rf ' . escapeshellarg($current_path));
//                 }
//         }
// }
foreach ($files as $f) {
        $current_path = $dir . $f;
        if (is_file($current_path) && !str_starts($f, 'No')) {
                $pathinfo = pathinfo($f);
                $filename = $pathinfo['filename'];
                $sub_no = substr($filename, strpos($filename, ' No'), strlen(' No.159'));
                $new_filename = str_replace($sub_no, '', $filename);
                $new_filename = trim($sub_no) . ' ' . $new_filename;
                $new_filename .= '.' . $pathinfo['extension'];
                $new_filename = $dir . $new_filename;
                rename($current_path, $new_filename);
                
        }
}


function str_starts($haystack, $needle) {
    return !strncmp($haystack, $needle, strlen($needle));
}

function str_ends($haystack, $needle) {
    $length = strlen($needle);
    if ($length == 0) {
        return true;
    }

    return (substr($haystack, -$length) === $needle);
}