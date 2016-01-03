<?php

require_once __DIR__.'/vendor/autoload.php';

use Goutte\Client;
use Symfony\Component\DomCrawler\Crawler;
use Symfony\Component\CssSelector\CssSelector;


$client = new \Goutte\Client([
    'headers' => [
        'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.85 Safari/537.36',
        'Content-Type' => 'text/plain; charset=utf-8',
        'Accept' => '*/*',
        'Accept-Language' => 'zh-CN,zh;q=0.8,en-US;q=0.6,en;q=0.4,zh-TW;q=0.2',
        'Accept-Encoding' => 'gzip, deflate, sdch',
    ],
    ]);

for ($i = 1; $i <= 6; ++$i) {
    $url = 'http://www.verycd.gdajie.com/find.htm?keyword=20%E4%B8%96%E7%BA%AA%20%E4%B8%AD%E5%8D%8E%E6%AD%8C%E5%9D%9B%20%E5%90%8D%E4%BA%BA%E7%99%BE%E9%9B%86%20ape&page=' . $i;
    $crawler = $client->request('GET', $url, []);
    var_dump($crawler);exit;
    $crawler->filter('.list_info > .elite > a')->each(function(Crawler $node, $i) {
        var_dump($node);
    });
    exit;
}



