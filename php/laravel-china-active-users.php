<?php

/*!
 * 获取早于某用户注册 laravel-china.org 的活跃用户。
 */

date_default_timezone_set('Asia/Shanghai');

$id = 252;
$activeHour = 24 * 7;

while ($id > 0) {
    if (preg_match('#活跃于[^>]+>([\d-: ]+)<#', file_get_contents('https://laravel-china.org/users/'.$id), $matches)) {
        if (($activeHour * 3600) > (time() - strtotime($matches[1]))) {
            printf("ID: %-5d  Last active: %s\n", $id, $matches[1]);
        }
    }

    usleep(200000);
    --$id;
}
