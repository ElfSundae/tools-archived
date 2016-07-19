<?php
/**
* VideoInfo: Get the information of a video file.
*
* Elf Sundae  http://www.0x123.com
*/


$ffmpeg_probe_path = '/usr/local/bin/ffprobe';

if (count($argv) == 3 && $argv[1] == 'show' ) {
        $file = $argv[2];
        if (!file_exists($file)) {
                die("$file is not exists.\n");
        }
        if (!is_file($file)) {
                die("$file is not a file.\n");
        }

        $info = VideoInfo::get_info($file);
        var_dump($info);
        die(PHP_EOL);
}


/**
 * Get Video/Audio Informations using ffprobe.
 * If getting failed, `VideoInfo::get_info($file);` will return FALSE, otherwise it will return a VideoInfo object.
 */
class VideoInfo {
        
        // streams
        public $video_info = array(
                'codec_type'            => 'video',
                'codec_name'            => FALSE,
                'codec_long_name'       => FALSE,
                'width'                 => FALSE,
                'height'                => FALSE,
                'level'                 => FALSE,
                'start_time'            => FALSE,
                'duration_ts'           => FALSE,
                'duration'              => FALSE,
                'bit_rate'              => FALSE,
        );
        public $audio_info = array(
                'codec_type'            => 'audio',                
                'codec_name'            => FALSE,
                'codec_long_name'       => FALSE,
                'start_time'            => FALSE,
                'duration_ts'           => FALSE,
                'duration'              => FALSE,
                'bit_rate'              => FALSE,
                'sample_rate'           => FALSE,
                'channels'              => FALSE,
        );
        // format
        public $format_info = array(
                'filename'              => FALSE,
                'format_name'           => FALSE,
                'format_long_name'      => FALSE,
                'start_time'            => FALSE,
                'duration'              => FALSE,
                'size'                  => FALSE,
                'bit_rate'              => FALSE,
        );
        
        static function get_info($file) {
                global $ffmpeg_probe_path;
                
                if (file_exists($file) && is_file($file)) {
                        $video_info_temp = array();
                        $info_cmd = escapeshellcmd("{$ffmpeg_probe_path} -v quiet -print_format json -show_format -show_streams '{$file}'");
                        exec($info_cmd, $video_info_temp);
                        $video_info_str = '';
                        foreach ($video_info_temp as $line) {
                                $video_info_str .= $line . "\n";
                        }
                        $video_info = json_decode($video_info_str);
                        
                        if ($video_info && isset($video_info->streams) && $video_info->streams && is_array($video_info->streams)) {
                                $result = new VideoInfo();
                                
                                $video_info_streams = $video_info->streams;
                                foreach ($video_info_streams as $info) {
                                        if (isset($info->codec_type) && $info->codec_type == 'audio') {
                                                $allKeys = array_keys($result->audio_info);
                                                foreach ($allKeys as $key) {
                                                        if ( isset($info->$key) ) $result->audio_info[$key] = $info->$key;
                                                }
                                        } else if (isset($info->codec_type) && $info->codec_type == 'video') {
                                                $allKeys = array_keys($result->video_info);
                                                foreach ($allKeys as $key) {
                                                        if ( isset($info->$key) ) $result->video_info[$key] = $info->$key;
                                                }
                                        }
                                }
                                
                                if (isset($video_info->format) && is_object($video_info->format)) {
                                        $info = $video_info->format;
                                        $allKeys = array_keys($result->format_info);
                                        foreach ($allKeys as $key) {
                                                if ( isset($info->$key) )  $result->format_info[$key] = $info->$key;
                                        }
                                }
                                
                                return $result;
                        }
                     
                }
                
                return FALSE;
        }
}