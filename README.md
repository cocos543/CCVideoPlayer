# CC視頻播放器

## 更新日記
最後更新 2016年3月

## 前言
　　壹個iOS上使用的RTMP視頻組件,基於VLCKit開發,用於播放RTMP流,另外幾乎支持所有視頻格式.適合做iOS端直播開發,或者本地視頻播放器使用.基於老牌開源播放器VLC核心組件開發,高效可靠.

## 主要功能
1. 播放器的基本功能.
2. 支持RTMP協議視頻流.
3. 支持全屏播放.

## 使用方法
1.先使用Pod導入核心庫
Pod:

    pod 'MobileVLCKit-prod', '2.7.2'

2.在需要加載播放器的地方引入#import "CCVideoPlayView.h"
3.加載播放器
``` objectivec
// UIViewController.m
// 初始化
CCVideoPlayView *playView = [CCVideoPlayView videoPlayViewWithFrame:frame URL:playerURL delegate:self];

//設置指示器顏色
playView.indicatorColor

//設置用於載入播放器的容器
playView.containerViewController = self;

//顯示播放器
[self.view addSubview:self.ccPlayView];
```

4.其他用法參考頭文件CCVideoPlayView.h
