//
//  QvodPlayerCallbacks.cpp
//  QVOD
//
//  Created by bigbug on 11-11-21.
//  Copyright (c) 2011年 qvod. All rights reserved.
//


#include "QvodPlayerInterface.h"
#import "QVFFmpegPlayer.h"
#import "UIImageAdditions.h"
#import "UIDevice-Hardware.h"
#import "QVNotificationName.h"

#ifndef next_powerof2
#define next_powerof2(x) \
x--;\
x |= x >> 1;\
x |= x >> 2;\
x |= x >> 4;\
x |= x >> 8;\
x |= x >> 16;\
x++;
#endif // !next_powerof2

int CreateAudioService(void* pUserData, void* pReserved)
{
    QVFFmpegPlayer* pFFmpegPlayer = (QVFFmpegPlayer*)pUserData;
    
    [pFFmpegPlayer createAudioService];
    
    return 1;
}

int CreateVideoService(void* pUserData, void* pReserved)
{
    return 1;
}

int OpenFinished(void* pUserData, void* pReserved)
{
    QVFFmpegPlayer* pFFmpegPlayer = (QVFFmpegPlayer*)pUserData;
    
    printf("int LoadFinished(void* pUserData, void* pReserved)\n");
    [pFFmpegPlayer.delegate loadFinished:NULL];
    printf("int LoadFinished(void* pUserData, void* pReserved) end\n");
    
    return 1;
}

int CloseFinished(void* pUserData, void* pReserved)
{
    QVFFmpegPlayer* pFFmpegPlayer = (QVFFmpegPlayer*)pUserData;
    
    [pFFmpegPlayer destroyAudioService];
    printf("int UnLoadFinished(void* pUserData, void* pReserved)\n");
    [pFFmpegPlayer.delegate closeFinished:NULL];
    printf("int UnLoadFinished(void* pUserData, void* pReserved) end\n");
    
    return 1;
}

int PreviewStarted(void* pUserData, void* pReserved)
{
    QVFFmpegPlayer* pFFmpegPlayer = (QVFFmpegPlayer*)pUserData;
    
    printf("int PreviewStarted(void* pUserData, void* pReserved)\n");
    [pFFmpegPlayer.delegate previewStarted:NULL];
    printf("int PreviewStarted(void* pUserData, void* pReserved) end\n");
    
    return 1;
}

int PreviewStopped(void* pUserData, void* pReserved)
{
    QVFFmpegPlayer* pFFmpegPlayer = (QVFFmpegPlayer*)pUserData;
    
    printf("int PreviewStopped(void* pUserData, void* pReserved)\n");
    [pFFmpegPlayer.delegate previewStopped:NULL];
    printf("int PreviewStopped(void* pUserData, void* pReserved) end\n");
    
    return 1;
}

int PreviewCaptured(void* pUserData, void* pReserved)
{
    QVFFmpegPlayer* pFFmpegPlayer = (QVFFmpegPlayer*)pUserData;
    PREVIEWINFO* pPreview = (PREVIEWINFO*)pReserved;
    
    printf("int PreviewCaptured(void* pUserData, void* pReserved)\n");
    [pFFmpegPlayer.delegate previewCaptured:pPreview];
    printf("int PreviewCaptured(void* pUserData, void* pReserved) end\n");
    
    return 1;
}

int FrameCaptured(void* pUserData, void* pReserved)
{
    QVFFmpegPlayer* pFFmpegPlayer = (QVFFmpegPlayer*)pUserData;
    FRAMEINFO* pFrame = (FRAMEINFO*)pReserved;
    
    printf("int FrameCaptured(void* pUserData, void* pReserved)\n");
    [pFFmpegPlayer.delegate frameCaptured:pFrame];
    printf("int FrameCaptured(void* pUserData, void* pReserved) end\n");
    
    return 1;
}

int UpdatePictureSize(void* pUserData, void* pReserved)
{
    QVFFmpegPlayer* pFFmpegPlayer = (QVFFmpegPlayer*)pUserData;
    
    // 根据流中parse出的图像高度和宽度来初始化opengl的显示
    unsigned int uSize = *(unsigned int*)pReserved;
    int mWidth  = uSize & 0xFFFF;
    int mHeight = uSize >> 16;
    int texW = mWidth;
    int texH = mHeight;
    
    next_powerof2(texW);
    next_powerof2(texH);
    
    if (texW >= 512 && texW < 1024) {
        texW = 1024;
    }

    if (texH >= 512 && texH < 1024) {
        texH = 1024;
    }
    
    [[pFFmpegPlayer delegate] setPrepareTexture:texW textureHeight:texH frameWidth:mWidth frameHeight:mHeight];
    
    return 1;
}

int DeliverFrame(void* pUserData, void* pReserved)
{
    QVFFmpegPlayer* pFFmpegPlayer = (QVFFmpegPlayer*)pUserData;
    uint8_t* pBufferRGB = (uint8_t*)pReserved;
    
    if (pBufferRGB) {
        [pFFmpegPlayer render:pBufferRGB];
    }
    
    return 1;
}

int PlaybackFinished(void* pUserData, void* pReserved)
{
    QVFFmpegPlayer* pFFmpegPlayer = (QVFFmpegPlayer*)pUserData;
    
    [pFFmpegPlayer performSelectorOnMainThread:@selector(notifyFinish:) withObject:nil waitUntilDone:NO];
    
    return 0;
}

int CheckDevice(void* pUserData, void* pReserved)
{
    char szFormatName[32]; // more than enough
    int* pSupport = (int*)pReserved;
    NSUInteger deviceType = [UIDevice currentDevice].platformType;
    
//    GetParameter(PLAYER_GET_MEDIA_FORMAT_NAME, szFormatName);
    
//    //modify by ljg qmv is not support now
//    //if (UIDevice1GiPad == deviceType) {
//    if(1){
//    //
//        *pSupport = !!strcmp(szFormatName, "qmv");
//    }
    
    return 0;
}

int ErrorHandler(void* pUserData, void* pReserved)
{
    QVFFmpegPlayer* pFFmpegPlayer = (QVFFmpegPlayer*)pUserData;
    EMSG emsg = { (int)pReserved, NULL, NULL };

    [pFFmpegPlayer.delegate encounterError:&emsg];
    
    return 0;
}

int BeginBuffering(void* pUserData, void* pReserved)
{
    QVFFmpegPlayer* pFFmpegPlayer = (QVFFmpegPlayer*)pUserData;
    
    //printf("Wait network!\n");
    [pFFmpegPlayer.delegate waitNetworkData:NULL];
    
    return 0;
}

int OnBuffering(void* pUserData, void* pReserved)
{
    QVFFmpegPlayer* pFFmpegPlayer = (QVFFmpegPlayer*)pUserData;
    
    int nProgress = *(double*)pReserved * 100;
    
    [pFFmpegPlayer.delegate updateBufferingProgress:&nProgress];
    
    return 0;
}

int EndBuffering(void* pUserData, void* pReserved)
{
    QVFFmpegPlayer* pFFmpegPlayer = (QVFFmpegPlayer*)pUserData;
    
    //printf("Resume from waiting network!\n");
    [pFFmpegPlayer.delegate resumeFromWaitNetworkData:NULL];
    
    return 0;
}

int NotifyReadIndex(void* pUserData, void* pReserved)
{
    QVFFmpegPlayer* pFFmpegPlayer = (QVFFmpegPlayer*)pUserData;
    int64_t* pIndexPos = (int64_t*)pReserved;
    
    //printf("Notify read index!\n");
    [pFFmpegPlayer.delegate notifyReadIndex:*pIndexPos];
    //printf("Notify read index end!\n");
    
    return 0;
}

int NotifySeekPosition(void* pUserData, void* pReserved)
{
    QVFFmpegPlayer* pFFmpegPlayer = (QVFFmpegPlayer*)pUserData;
    int64_t* pSeekPos = (int64_t*)pReserved;
    
    //printf("Notify seek position!\n");
    [pFFmpegPlayer.delegate notifySeekPos:*pSeekPos];
    //printf("Notify seek position end!\n");
    
    return 0;
}

int GetDownloadSpeed(void* pUserData, void* pReserved)
{
    QVFFmpegPlayer* pFFmpegPlayer = (QVFFmpegPlayer*)pUserData;
    int* pSpeed = (int*)pReserved;
    
    [pFFmpegPlayer.delegate getDownloadSpeed:pSpeed];

    return 0;
}
