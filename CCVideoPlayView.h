//
//  CCVideoPlayView.h
//  
//
//  Created by 郑克明 on 16/3/1.
//  Copyright © 2016年 Cocos. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CCVideoPlayViewDelegate <NSObject>
@optional
/**
 *  触摸播放器
 *
 *  @param sender 触发的手势对象
 */
-(void)CCPlayerOnTapPlayView:(_Nullable id)sender;
/**
 *  开始播放
 */
-(void)CCPlayerOnPlay;
/**
 *  播放暂停
 */
-(void)CCPlayerOnPause;
/**
 *  播放停止
 */
-(void)CCPlayerOnStop;
/**
 *  切换成横屏模式
 */
-(void)CCPlayerOnSwitchFullModel;
/**
 *  切换成竖屏模式
 */
-(void)CCPlayerOnSwitchPortraitModel;
/**
 *  工具栏显示
 */
-(void)CCPlayerOnToolViewShow;
/**
 *  工具栏隐藏
 */
-(void)CCPlayerOnToolViewHide;


/// status 变更回调
- (void)mediaPlayerStateChanged:(nonnull NSNotification *)aNotification;
- (void)mediaPlayerTimeChanged:(nonnull NSNotification *)aNotification;
@end


//工具栏显示时长(超时后自动隐藏)
extern NSInteger const CCPlayerShowToolTimeInterval;

@interface CCVideoPlayView : UIView

@property (nonatomic,strong,nonnull) NSURL *url;

@property (nonatomic,readonly) BOOL isPlaying;

@property (nonatomic,readonly) BOOL willlaying;

@property (nonatomic,strong, nullable) UIColor *indicatorColor;
//用于显示全屏的控制器
@property (nonatomic,weak,nullable) UIViewController *containerViewController;
//代理
@property (nonatomic,weak,nullable) id<CCVideoPlayViewDelegate> delegate;
/**
 *  从xib文件中创建视图
 *
 *  @return CCVideoPlayView
 */
+ (instancetype _Nonnull)videoPlayViewWithFrame:(CGRect)frame URL:(nonnull NSURL *)url delegate:(_Nullable id <CCVideoPlayViewDelegate>)delegate;

/**
 *  停止播放
 */
- (void)stopPlay;
/**
 *  开始播放
 */
- (void)startPlay;
@end
