
/*
 *  FFmpegPlayer.h/.m - Handles movie playback state.
 *  jamesghurley<at>gmail.com
 */

#import "QVFFmpegPlayer.h"
#import "QvodPlayerCallbacks.h"
#import "../Audio/QVCoreAudio.h"

@interface QVFFmpegPlayer(Private)
- (void) render:(uint8_t*) pRGBBuffer;//(DecodedFrameData *) pData;
- (void) notifyFinish:(void*) pData;
@end

@implementation QVFFmpegPlayer

@synthesize delegate = _showDelegate;
@synthesize m_nTexWidth;
@synthesize m_nTexHeight;

- (void) render:(uint8_t*) pBufRGB//(DecodedFrameData *) pData
{   
	if ([_showDelegate respondsToSelector:@selector(refreshWithVideoFrameBufferData:)]) {
        [_showDelegate refreshWithVideoFrameBufferData:pBufRGB];
    }
}

- (void) notifyFinish:(void*) pData
{
    [self.delegate playbackDidFinish];
}

- (id) init 
{
	self = [super init];

    m_pAudioService = nil;

    NSString *str = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    char* szPath = [str cStringUsingEncoding:NSUTF8StringEncoding];

    if (CreatePlayer(szPath) == E_FAIL) {
        return nil;
    }
    
    SetCallback(CALLBACK_CREATE_AUDIO_SERVICE, CreateAudioService, self, NULL);
    SetCallback(CALLBACK_CREATE_VIDEO_SERVICE, CreateVideoService, self, NULL);
    SetCallback(CALLBACK_OPEN_FINISHED, OpenFinished, self, NULL);
    SetCallback(CALLBACK_CLOSE_FINISHED, CloseFinished, self, NULL);
    SetCallback(CALLBACK_PREVIEW_STARTED, PreviewStarted, self, NULL);
    SetCallback(CALLBACK_PREVIEW_STOPPED, PreviewStopped, self, NULL);
    SetCallback(CALLBACK_PREVIEW_CAPTURED, PreviewCaptured, self, NULL);
    SetCallback(CALLBACK_UPDATE_PICTURE_SIZE, UpdatePictureSize, self, NULL);
    SetCallback(CALLBACK_DELIVER_FRAME, DeliverFrame, self, NULL);
    SetCallback(CALLBACK_FRAME_CAPTURED, FrameCaptured, self, NULL);
    SetCallback(CALLBACK_PLAYBACK_FINISHED, PlaybackFinished, self, NULL);
    SetCallback(CALLBACK_ERROR, ErrorHandler, self, NULL);
    SetCallback(CALLBACK_BEGIN_BUFFERING, BeginBuffering, self, NULL);
    SetCallback(CALLBACK_ON_BUFFERING, OnBuffering, self, NULL);
    SetCallback(CALLBACK_END_BUFFERING, EndBuffering, self, NULL);
    SetCallback(CALLBACK_SEEK_POSITION, NotifySeekPosition, self, NULL);
    SetCallback(CALLBACK_READ_INDEX, NotifyReadIndex, self, NULL);
    SetCallback(CALLBACK_CHECK_DEVICE, CheckDevice, self, NULL);
    SetCallback(CALLBACK_GET_DOWNLOAD_SPEED, GetDownloadSpeed, self, NULL);
    
    return self;
}

- (void) dealloc
{
    DBG_TRACE(DM_PLAYER, "self:%@\n", self);

    [self close];
    DestroyPlayer();
    
    [super dealloc];
    
}

- (int) createAudioService
{
    if (!m_pAudioService) {
        SendRequest(REQUEST_INTERRUPT_AUDIO, FALSE, 0, NULL, NULL);
        m_pAudioService = [[QVCoreAudio alloc] init];
        [m_pAudioService start];
        return 1;
    }
    
    return 0;
}

- (int) destroyAudioService
{
    if (m_pAudioService) {
        SendRequest(REQUEST_INTERRUPT_AUDIO, TRUE, 0, NULL, NULL);
        [m_pAudioService stop];
        [m_pAudioService release];
        m_pAudioService = nil;
    }
    
    return 0;
}

- (int) load:(const char *)filePath initialPos:(double)lfInitialPos isRemoteFile:(BOOL)bRemote
{	
    self.m_nTexWidth  = 0;
    self.m_nTexHeight = 0;
    
    if (Open(filePath, lfInitialPos, bRemote) != S_OK) {
        return NO;
    }

    if (_showDelegate) {
        if ([_showDelegate respondsToSelector:@selector(setTotalTime:)]) {
            [_showDelegate setTotalTime:[self getMediaDuration]];
        }
    }       
    
	return YES;
}

- (int) play
{
    Play();
	  
	return YES;	
}

- (int) seek: (double) time
{
    if ([self isPlayed] || [self isPaused]) {
        Seek(time);
        return YES;
    }
	
	return NO;
}

- (int) pause 
{
    Pause();
    
    return YES;
}

- (int) close
{		
    Close();

    return YES;
}

- (int) startPreview:(const char *)filePath initialPos:(double) lfInitialPos frameCount:(int) nCount
{
    return StartPreview(filePath, lfInitialPos, nCount);
}

- (int) stopPreview
{
    return StopPreview();
}

- (BOOL) isLoaded
{
    int nState = STATE_NONE;
    
    GetParameter(PLAYER_GET_STATE, &nState);
    
    return nState & STATE_LOADED;
}

- (BOOL) isPlayed
{
    int nState = STATE_NONE;
    
    GetParameter(PLAYER_GET_STATE, &nState);
    
    return nState & STATE_EXECUTE;
}

- (BOOL) isPaused
{
    int nState = STATE_NONE;
    
    GetParameter(PLAYER_GET_STATE, &nState);
    
    return nState & STATE_PAUSE;
}

- (BOOL) isClosed
{
    int nState = STATE_NONE;
    
    GetParameter(PLAYER_GET_STATE, &nState); 
    
    return nState & STATE_UNLOADED;
}

- (double) getMediaCurTime
{
    double lfTime = 0;
    
    GetParameter(PLAYER_GET_MEDIA_CURRENT_TIME, &lfTime);

	return lfTime;
}

- (double) getMediaDuration
{
    double lfDuration;
    
    GetParameter(PLAYER_GET_MEDIA_DURATION, &lfDuration);

	return lfDuration;
}

- (int) getMediaBitrate
{
    int nBitrate;
    
    GetParameter(PLAYER_GET_MEDIA_BITRATE, &nBitrate);
    
    return nBitrate;
}

- (void) enableLoopFilter:(BOOL) bEnable
{
    SetParameter(PLAYER_SET_VIDEO_LOOP_FILTER, &bEnable);
}

@end
