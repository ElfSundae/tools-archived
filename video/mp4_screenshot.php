<?php
/**
 * Get screenshot for mp4 files.
 *
 * by Elf Sundae. http://www.0x123.com
 */

require_once "VideoInfo.php";

$ffmpeg_path = '/usr/local/bin/ffmpeg';

fun_main($argv);

function fun_main($argv) {
        if (count($argv) < 3 ) {
                echo "Usage:\n\t-i \"path/to/mp4/file/OR/dir\"\n\t-s screenshot_size  (e.g. 100x200)\n\t-t screenshot_time\n";
                echo "screenshot_time: -1 (use half of the duration, -1 is by default.) -2 (will generate 5 pictures)\n";
                die(PHP_EOL);
                
        }
        $file = '';
        $size = '140x100';
        $time = -1;
        for ($i = 1; $i < count($argv); $i += 2) {
                if (($i+1) >= count($argv)) {
                        break;
                }
                $param = $argv[$i];
                $value = trim($argv[$i+1]);
                if ($param == '-i') {
                        $file = $value;
                } else if ($param == '-s') {
                        $size = $value;
                } else if ($param == '-t'){
                        $time = $value;
                }
        }
        get_screenshot($file, $size, $time);
}

function get_screenshot($path, $size = '140x100', $time = -1) {
        global $ffmpeg_path;
        if (!file_exists($path)) {
                die ("Error: $path is not exists.\n");
        }        
        if (is_file($path)) {
                get_screenshot_for_file($path, $size, $time);
        } else if (is_dir($path)) {
                $files = get_mp4_files_in_dir($path);
                foreach ($files as $file) {
                        get_screenshot_for_file($file, $size, $time);
                }   
        } else {
                die ("Error: $path is not file nor directory.");
        }
}

function get_mp4_files_in_dir($dir) {
        $arr = scandir($dir);
        $result = array();
        foreach ($arr as $file) {
                $pathinfo = pathinfo($file);
                if (isset($pathinfo['extension']) && 'mp4' == strtolower($pathinfo['extension'])) {
                        $file = rtrim($dir, '/') . '/' . $file;
                        array_push($result, $file);
                }
        }
        return $result;
}

function get_video_duration($file) 
{
        $duration = 0.0;
        $video_info = VideoInfo::get_info($file);
        if ($video_info) {
                $duration = $video_info->video_info['duration'];
                if (!$duration  || $duration <= 0.0) {
                        $duration = $video_info->format_info['duration'];
                        if (!$duration || $duration <= 0.0) {
                                $duration = 0.0;
                        } else {
                                $duration = floatval(intval($duration));
                        }
                }
        }
        return $duration;
}
        

function get_screenshot_for_file($file, $size = '140x100', $time = -1) {
        global $ffmpeg_path;
        if (!file_exists($file) || !is_file($file)) {
                echo "$file  <Error>\n";
        } else {
                static $_shared_file_number = 0;
                $_shared_file_number++;
                echo "[ $_shared_file_number ] $file ...... ($size)\n";
                $times = array();
                $video_duration = get_video_duration($file);
                $video_duration_half = $video_duration / 2.0;
                if ($time > 0 ) {
                        if ($time > $video_duration) {
                                echo "<Warning>: The screenshot time specified ($time) is out of the video duration ($video_duration), will use ($video_duration_half) as screenshot time.\n";    
                                $times[] = $video_duration_half;
                        } else {
                                $times[] = $time;
                        }
                } else if ($time == -1) {
                        $times[] = $video_duration_half;
                } else {
                        $step_lenght = (($video_duration - 6 - 6) / 5);
                        for ($i = 0; $i < 5; $i++) {
                                $times[] = ($i * $step_lenght) + 6.0;
                        }  
                }
                
                $pathinfo = pathinfo($file);
                for ($i = 0; $i < count($times); $i++) {
                        $extent = ($i ? "-{$i}" : "");
                        $shotfile = $pathinfo['dirname'] . '/' . $pathinfo['filename'] . $extent . '.png';
                        $shottime = $times[$i];
                        echo sprintf("( %f ) %s\n", $shottime, $shotfile);
                        $cmd = escapeshellcmd("{$ffmpeg_path}  -loglevel panic -ss {$shottime} -i '{$file}' -vcodec mjpeg -vframes 1 -an -f rawvideo -s {$size} -y '$shotfile'");
                        exec($cmd);
                }
                echo "Done.\n";
        }
}