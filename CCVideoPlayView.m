//
//  CCVideoPlayView.m
//  
//
//  Created by Cocos on 16/3/1.
//  Copyright © 2016年 Cocos. All rights reserved.
//
#import <MobileVLCKit/MobileVLCKit.h>
#import "CCVideoPlayView.h"
#import "CCFullViewController.h"

#define kVLCSettingNetworkCaching @"network-caching"
#define kVLCSettingNetworkCachingDefaultValue @(999)
NSInteger const CCPlayerShowToolTimeInterval = 3;
static NSString *status[] = {
    @"VLCMediaPlayerStateStopped",        //< Player has stopped
    @"VLCMediaPlayerStateOpening",        //< Stream is opening
    @"VLCMediaPlayerStateBuffering",      //< Stream is buffering
    @"VLCMediaPlayerStateEnded",          //< Stream has ended
    @"VLCMediaPlayerStateError",          //< Player has generated an error
    @"VLCMediaPlayerStatePlaying",        //< Stream is playing
    @"VLCMediaPlayerStatePaused"
};
@interface CCVideoPlayView() <VLCMediaPlayerDelegate>
//用户展示视频,默认展示播放器背景图
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *toolView;
/**
 *  playOrPauseBtn 被选中,表示播放状态,未选中,表示暂停状态
 */
@property (weak, nonatomic) IBOutlet UIButton *playOrPauseBtn;
@property (weak, nonatomic) IBOutlet UIButton *switchOrientation;
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;

//播放器驱动
@property (nonatomic,strong) VLCMediaPlayer *player;
//播放器绘制层
@property (nonatomic,strong) UIView *playerView;
//工具栏定时器
@property (nonatomic,strong) NSTimer *toolViewTimer;
//工具栏动画是否正在执行
@property (nonatomic) BOOL isToolViewShowAnimating;
@property (nonatomic) BOOL isToolViewHideAnimating;

//全屏控制器(暂无)
@property (nonatomic,weak) CCFullViewController *fullVC;
//CCVideoPlayView最初被指定的原始位置
@property (nonatomic) CGRect originalViewFrame;
@property (nonatomic) BOOL isFullModel;
@end

@implementation CCVideoPlayView

+ (instancetype)videoPlayViewWithFrame:(CGRect)frame URL:(NSURL *)url delegate:(id<CCVideoPlayViewDelegate>)delegate{
    CCVideoPlayView *view = (CCVideoPlayView *)[[[NSBundle mainBundle] loadNibNamed:@"CCVideoPlayView" owner:nil options:nil] firstObject];
    if (view) {
        view.imageView.translatesAutoresizingMaskIntoConstraints = NO;
        view.playerView = [[UIView alloc] initWithFrame:CGRectZero];
        view.url = url;
        
        //播放器驱动设置
        view.player = [[VLCMediaPlayer alloc] initWithOptions:@[[NSString stringWithFormat:@"--extraintf"], [NSString stringWithFormat:@"--%@=%@", kVLCSettingNetworkCaching,@(1000)]]];
        
        view.player.media = [VLCMedia mediaWithURL:url];
        view.player.drawable = view.playerView;
        view.player.delegate = view;
        view.delegate = delegate;
        view.originalViewFrame = frame;
        view.frame = frame;
        [view playOrPause:nil];
        [view addObservers];
    }
    return view;
}

-(instancetype)init{
    @throw [NSException exceptionWithName:@"Not supported init" reason:@"Use +[CCVideoPlayView videoPlayView]" userInfo:nil];
}

-(void)awakeFromNib{
    [super awakeFromNib];
//    [self.volumeSlider setMinimumTrackImage:[UIImage imageNamed:@"MinimumTrackImage"] forState:UIControlStateNormal];
//    [self.volumeSlider setMaximumTrackImage:[UIImage imageNamed:@"MaximumTrackImage"] forState:UIControlStateNormal];
    [self.volumeSlider setThumbImage:[UIImage imageNamed:@"thumbImage"] forState:UIControlStateNormal];
    
    //添加所有手势操作
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
    tapRecognizer.numberOfTapsRequired = 1;
    [self addGestureRecognizer:tapRecognizer];
}

-(void)willMoveToSuperview:(UIView *)newSuperview{
    [super willMoveToSuperview:newSuperview];
    
    if (!newSuperview) {
        [self removeObservers];
        if (self.player.isPlaying) {
            [self.player stop];
        }
        self.player.drawable = nil;
        self.player = nil;
        [self removeToolViewTimer];
    }
}

-(void)dealloc{
    NSLog(@"ccview dealloc~");
}

#pragma mark - 布局调试
- (void)layoutSubviews
{
    [super layoutSubviews];
    for (UIView *subView in self.subviews) {
        if ([subView hasAmbiguousLayout]) {
            NSLog(@"AMBIGUOUS: %@", subView);
        }
    }
    
    //防止有时候旋转屏幕时出现偏差
    if (!self.isFullModel) {
        self.frame = self.originalViewFrame;
        self.playerView.frame = self.imageView.frame;
    }
}

#pragma mark - 界面调整

-(void)imageViewFrameDidChange:(NSDictionary *)change{
    NSLog(@"imageView frame did change %@",NSStringFromCGRect(self.imageView.frame));
//    self.playerView.frame = self.imageView.frame;
}

#pragma mark - KVO监听
- (void)addObservers
{
    [self addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
}

- (void)removeObservers
{
    [self removeObserver:self forKeyPath:@"frame"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"frame"]) {
        [self imageViewFrameDidChange:change];
    }
}

#pragma mark - 播放器工具栏操作
/**
 *  播放与暂停播放
 *
 *  @param sender 播放(暂停)按钮
 */
- (IBAction)playOrPause:(UIButton *)sender {
    //按钮未选中:准备播放.如果是播放,则开启定时器,定时隐藏工具栏,更改按钮为暂停图标
    //按钮被选中:准备暂停.如果是暂停,则显示工具栏,移除定时器,更改按钮为播放图标
    if (!sender) {
        //首次播放,系统自动触发点击事件,sender为nil
        //这里没有设置palyerView的frame,需要在imageView自动根据约束更新frame时候调整palyerView的frame
        UIView *playerView = self.playerView;
        [self.imageView addSubview:playerView];
        [self.player play];
        self.playOrPauseBtn.selected = YES;
    }else if (sender.selected) {
        [self.player stop];
    }else{
        [self.player play];
    }
    sender.selected = !sender.selected;
}
/**
 *  全屏切换
 *  由CCVideoPlayView父视图所在的控制器负责显示全屏
 *  @param sender 全屏切换按钮
 */
- (IBAction)switchOrientation:(UIButton *)sender {
    if (sender.selected) {
        //切换正常
        [self.fullVC dismissViewControllerAnimated:NO completion:^{
            [self.containerViewController.view addSubview:self];
            //视频驱动层的大小和imageView一样大,而imageView自适应self.frame
            [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionLayoutSubviews animations:^{
                self.frame = self.originalViewFrame;
                self.playerView.frame = self.imageView.frame;
            } completion:^(BOOL finished){
                if (finished) {
                    //防止在动画执行的时候触发layoutSubviews方法中关于frame的代码
                    self.isFullModel = NO;
                }
            }];
        }];
        sender.selected = NO;
        if ([self.delegate respondsToSelector:@selector(CCPlayerOnSwitchPortraitModel)]) {
            [self.delegate CCPlayerOnSwitchPortraitModel];
        }
    }else{
        //切换全屏
        self.isFullModel = YES;
        CCFullViewController *fullVC = [[CCFullViewController alloc] init];
        [self.containerViewController presentViewController:fullVC animated:NO completion:^{
            //注意此时高<宽,所以视频高等于屏幕高,视频宽为视频高的3/4
            [fullVC.view addSubview:self];
            self.playerView.frame = CGRectMake(0, 0, fullVC.view.frame.size.height * 4 / 3, fullVC.view.frame.size.height);
            self.center = fullVC.view.center;
            self.playerView.center = self.center;
            [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionLayoutSubviews animations:^{
                self.frame = fullVC.view.bounds;
            } completion:nil];
        }];
        self.fullVC = fullVC;
        sender.selected = YES;
        if ([self.delegate respondsToSelector:@selector(CCPlayerOnSwitchFullModel)]) {
            [self.delegate CCPlayerOnSwitchFullModel];
        }
    }
    
    [self removeToolViewTimer];
    [self addToolViewTimer];
}

/**
 *  切换工具视图显示或隐藏
 *
 *  @param isShowView 显示或者隐藏视图
 */
- (void)setToolViewShowState:(BOOL)isShowView{
    if (isShowView) {
        [self removeToolViewTimer];
        [self showToolView];
        //重新添加定时器
        [self addToolViewTimer];
    }else{
        [self removeToolViewTimer];
        if (self.player.state != VLCMediaPlayerStateStopped) {
            [self hideToolView];
        }
    }
}

/**
 *  隐藏工具栏
 */
- (void)hideToolView{
    self.isToolViewHideAnimating = YES;
    [UIView animateWithDuration:1 animations:^{
        self.toolView.alpha = 0;
    } completion:^(BOOL finished){
        if (finished) {
            self.isToolViewHideAnimating = NO;
        }
    }];
    if ([self.delegate respondsToSelector:@selector(CCPlayerOnToolViewHide)]) {
        [self.delegate CCPlayerOnToolViewHide];
    }
}

/**
 *  显示工具栏
 */
- (void)showToolView{
    self.isToolViewShowAnimating = YES;
    [UIView animateWithDuration:0.5 animations:^{
        self.toolView.alpha = 1;
    } completion:^(BOOL finished){
        if (finished) {
            self.isToolViewShowAnimating = NO;
        }
    }];
    if ([self.delegate respondsToSelector:@selector(CCPlayerOnToolViewShow)]) {
        [self.delegate CCPlayerOnToolViewShow];
    }
}

#pragma  mark - 定时器操作
/**
 *  定时隐藏工具栏
 */
- (void)addToolViewTimer{
    self.toolViewTimer = [[NSTimer alloc] initWithFireDate: [NSDate dateWithTimeIntervalSinceNow:CCPlayerShowToolTimeInterval] interval:0 target:self selector:@selector(hideToolView) userInfo:nil repeats:NO];
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop addTimer:self.toolViewTimer forMode:NSDefaultRunLoopMode];
    NSLog(@"addToolViewTimer");
}

/**
 *  移除工具栏隐藏定时器
 */
- (void)removeToolViewTimer{
    //移除定时器
    if (self.toolViewTimer) {
        [self.toolViewTimer invalidate];
        self.toolViewTimer = nil;
    }
    NSLog(@"removeToolViewTimer");
}


/**
 *  某些操作需要定时器重新计时
 */
- (void)updateToolViewTimer{
    
}

#pragma mark - 手势操作
-(void)singleTap:(id)sender{
    if (self.toolView.alpha > 0.001) {
        [self setToolViewShowState:NO];
    }else{
        [self setToolViewShowState:YES];
    }
    if ([self.delegate respondsToSelector:@selector(CCPlayerOnTapPlayView:)]) {
        [self.delegate CCPlayerOnTapPlayView:sender];
    }
}

#pragma mark - 实现VLCMediaPlayer部分协议

/// status 变更回调
- (void)mediaPlayerStateChanged:(NSNotification *)aNotification{
    NSLog(@"State: %@", status[self.player.state]);
    //可能是VLC的bug,没有VLCMediaPlayerStatePlaying状态,只有buffing状态
    if (self.player.isPlaying) {
        [self addToolViewTimer];
        [self stopLoadingIndicator];
    }else if (VLCMediaPlayerStateStopped == self.player.state) {
        [self removeToolViewTimer];
        [self showToolView];
        [self stopLoadingIndicator];
        [self stopPlay];
    }else if (VLCMediaPlayerStateBuffering == self.player.state){
        [self startLoadingIndicator];
    }
    
    if ([self.delegate respondsToSelector:@selector(mediaPlayerStateChanged:)]) {
        [self.delegate mediaPlayerStateChanged:aNotification];
    }
}

- (void)mediaPlayerTimeChanged:(NSNotification *)aNotification{
//    NSLog(@"State: %@", aNotification);
}

#pragma mark - 其他相关操作

- (void)stopPlay {
    if (self.playOrPauseBtn.selected == YES) {
        [self playOrPause:self.playOrPauseBtn];
    }
}

- (void)startPlay {
    if (self.playOrPauseBtn.selected == NO) {
        [self playOrPause:self.playOrPauseBtn];
    }
}

//添加加载指示器
- (void)startLoadingIndicator{
    
    if ([self.imageView viewWithTag:1008]) {
        return;
    }
    UIColor *color = self.indicatorColor == nil ? [UIColor redColor] : self.indicatorColor;
    UIActivityIndicatorView *activityIndicator= [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicator.center = self.imageView.center;
    [activityIndicator setColor:color];
    activityIndicator.tag=1008;
    [self.imageView addSubview:activityIndicator];
    [activityIndicator startAnimating];
}

//移除加载指示器
- (void)stopLoadingIndicator{
    UIActivityIndicatorView *activityIndicator=[self.imageView viewWithTag:1008];
    [activityIndicator stopAnimating];
    [activityIndicator removeFromSuperview];
}

@end

