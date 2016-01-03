<?php

$code = [
"kf3y9g",
"xsbcyo",
"xd83aq",
"uddsld",
"qiihhq",
"wqmzmq",
"wpx99w",
"d9i7ez",
"h5qqme",
"xryyyw",
"wfyxft",
"df8uoi",
"htspbt",
"fiwc4h",
"g5m05x",
"mg3agw",
"n2n0ce",
"dgly2w",
"f5a36h",
"nd9ab2",
"wma3qk",
"u9zzor",
"qn4xrr",
"gxc9mj",
"wrl403",
"tu1eg9",
"h6pquf",
"ck59de",
"yp0wpd",
"e9tlcl",
"rwcy7c",
"jp1gy6",
"wrbnas",
"z03st0",
"dbwepe",
"y0335g",
"h0yhlk",
"li3z66",
"nmh0os",
"sg2h0y",
"a7s48e",
"mf5zll",
"zc0n1n",
"m9blbs",
"judxww",
"jtfnkm",
"p9duhs",
"ayqd49",
"om1w0w",
"y4yp4p",
];

foreach ($code as $key) {
    $url = 'http://www.521xunlei.com/forum.php?mod=ajax&inajax=yes&infloat=register&handlekey=register&ajaxmenu=1&action=checkinvitecode&invitecode=' . $key;
    $simple = file_get_contents($url);
    $simple = iconv('gbk', 'utf-8', $simple);

    echo "$key $simple \n";

    if (strpos($simple, '邀请码错误') === false) {
        echo 'Found:' . $key . PHP_EOL;
        exit;
    }

    sleep(2);
}
