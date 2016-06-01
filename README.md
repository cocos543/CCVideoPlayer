# CC视频播放器

## 更新日记
最后更新 2016年3月

## 前言
　　一个iOS上使用的RTMP视频组件,基于VLCKit开发,用于播放RTMP流,另外几乎支持所有视频格式.适合做iOS端直播开发,或者本地视频播放器使用.
　　
　　基于老牌开源播放器VLC核心组件开发,高效可靠.

## 主要功能
1. 播放器的基本功能.
2. 支持RTMP协议视频流.
3. 支持全屏播放.

## 使用方法
1.先使用Pod导入核心库
Pod:

    pod 'MobileVLCKit-prod', '2.7.2'

2.在需要加载播放器的地方引入#import "CCVideoPlayView.h"
3.加载播放器
``` objectivec
// UIViewController.m
// 初始化
CCVideoPlayView *playView = [CCVideoPlayView videoPlayViewWithFrame:frame URL:playerURL delegate:self];

//设置指示器颜色
playView.indicatorColor

//设置用于载入播放器的容器
playView.containerViewController = self;

//显示播放器
[self.view addSubview:self.ccPlayView];
```

4.其他用法参考头文件CCVideoPlayView.h
