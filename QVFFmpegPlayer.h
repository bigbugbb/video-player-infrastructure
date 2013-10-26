/*
 *  FFmpegPlayer.h/.m - Handles movie playback state.
 *  jamesghurley<at>gmail.com
 */
#import <Foundation/Foundation.h>
#import "../Audio/QVCoreAudio.h"

#include "QvodPlayerInterface.h"

@protocol QVFFmpegPlayerDelegate <NSObject>

-(void)setPrepareTexture:(uint)textW textureHeight:(uint)textH frameWidth: (uint)mWid frameHeight: (uint)mHeigh;
-(void)refreshWithVideoFrameBufferData:(uint8_t*)buffer;
-(void)refreshSubtitleWithImage:(UIImage*)aImage;
-(void)playbackDidFinish;
-(void)notifySeekPos:(int64_t)llPos;
-(void)notifyReadIndex:(int64_t)llPos;
-(void)encounterError:(EMSG*)pMsg;      // 传入的pMsg为stack pointer
-(void)prepareBuffering:(void*)pData;          // 目前忽略pData
-(void)waitNetworkData:(void*)pData;           // 目前忽略pData
-(void)updateBufferingProgress:(void*)pData;   // pData表示int类型stack pointer，通过它取得buffer进度
-(void)resumeFromWaitNetworkData:(void*)pData; // 目前忽略pData
-(void)loadFinished:(void*)pData;      // ignore pData now
-(void)closeFinished:(void*)pData;     // ignore pData now
-(void)previewStarted:(void*)pData;
-(void)previewStopped:(void*)pData;
-(void)previewCaptured:(PREVIEWINFO*)pPreview;
-(void)frameCaptured:(FRAMEINFO*)pFrame;
-(void)getDownloadSpeed:(int*)pSpeed;  // kb/s

@end


@interface QVFFmpegPlayer : NSObject
{
    int     m_nTexWidth;
    int     m_nTexHeight;

    QVCoreAudio*               m_pAudioService;
    id<QVFFmpegPlayerDelegate> _showDelegate;
}

@property (readwrite) int m_nTexWidth;
@property (readwrite) int m_nTexHeight;

@property(assign)id<QVFFmpegPlayerDelegate> delegate;

- (int) load:(const char *)filePath initialPos:(double) lfInitialPos isRemoteFile:(BOOL) bRemote;
- (int) play;
- (int) pause;
- (int) seek:(double) time;
- (int) close;

- (int) startPreview:(const char *)filePath initialPos:(double) lfInitialPos frameCount:(int) nCount;
- (int) stopPreview;

- (int) createAudioService;
- (int) destroyAudioService;

- (void) render:(uint8_t *) pBufRGB;
- (void) notifyFinish:(void*) pData;

- (double) getMediaCurTime;
- (double) getMediaDuration;
- (int) getMediaBitrate;
- (void) enableLoopFilter:(BOOL) bEnable;

- (BOOL) isLoaded;
- (BOOL) isPlayed;
- (BOOL) isPaused;
- (BOOL) isClosed;

@end
