<?php

/* FontAwesome ver 4.4.0 */

$contents = file_get_contents('4.4.html');
$tmp = explode("\n", $contents);
$array = [];

foreach ($tmp as $string) {
    $arr = explode(" ", $string);
    $arr = array_map('trim', $arr);
    $arr = array_values(array_filter($arr));

    if (count($arr) == 2) {
        $array[] = [$arr[0] => $arr[1]];
    }
}

usort($array, function($a, $b){
    $aKey = array_keys($a)[0];
    $bKey = array_keys($b)[0];
    return $aKey > $bKey;
});

$enum = "\n\ntypedef NS_ENUM(NSUInteger, FAIcon) {\n";
$dict = "\n\n@{\n";
foreach ($array as $arr) {
    $hex = array_keys($arr)[0];
    $str = $arr[$hex];
    $enumName = getEnumName($str);

    $enum .= "    $enumName";
    $countOfBlank = 32 - strlen($enumName);
    $countOfBlank = $countOfBlank > 0 ? $countOfBlank : 1;
    for ($i = 0; $i < $countOfBlank; ++$i) {
        $enum .= " ";
    }
    $enum .= "= {$hex},\n";

    $tmpKey = "@\"{$str}\"";
    $dict .= "          $tmpKey";
    $countOfBlank = 32 - strlen($tmpKey);
    $countOfBlank = $countOfBlank > 0 ? $countOfBlank : 1;
    for ($i = 0; $i < $countOfBlank; ++$i) {
        $dict .= " ";
    }
    $dict .= ": @($enumName),\n";
}
$enum .= "};\n\n";
$dict .= "};\n\n";

// echo $enum;
echo $dict;


// 'fa-moon-o' to 'FAMoonO'
function getEnumName($string)
{
    $result = preg_replace('#^fa#', 'FA', $string);
    $result = preg_replace_callback('#-[a-z0-9]#', function($matches) {
        return strtoupper(str_replace('-', '', $matches[0]));
    }, $result);
    return $result;
}
