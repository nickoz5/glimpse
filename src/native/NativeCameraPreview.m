#import <AppKit/AppKit.h>
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#include <stdbool.h>
#include <math.h>
#include <stddef.h>
#include <string.h>

static NSPanel *glimpsePanel = nil;
static NSView *glimpsePreviewView = nil;
static NSTextField *glimpseMessageTitle = nil;
static NSTextField *glimpseMessageDetail = nil;
static AVCaptureSession *glimpseSession = nil;
static AVCaptureVideoPreviewLayer *glimpsePreviewLayer = nil;
static dispatch_queue_t glimpseCameraQueue = nil;
static NSString *glimpseSelectedDeviceId = nil;
static double glimpseDefaultWidth = 360.0;
static double glimpseDefaultHeight = 240.0;
static NSRect glimpseSavedFrame;
static BOOL glimpseHasSavedFrame = NO;
static id glimpseOutsideClickMonitor = nil;

void glimpse_native_hide(void);
void glimpse_native_frame_changed(double x, double y, double width, double height);

static void rememberFrame(NSRect frame) {
  glimpseSavedFrame = frame;
  glimpseHasSavedFrame = YES;
  glimpse_native_frame_changed(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
}

static void installOutsideClickMonitor(void) {
  if (glimpseOutsideClickMonitor != nil) {
    return;
  }

  glimpseOutsideClickMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:
      NSEventMaskLeftMouseDown | NSEventMaskRightMouseDown
      handler:^(NSEvent *event) {
        (void)event;
        if (glimpsePanel == nil || !glimpsePanel.isVisible) {
          return;
        }

        if (!NSPointInRect(NSEvent.mouseLocation, glimpsePanel.frame)) {
          glimpse_native_hide();
        }
      }];
}

static void removeOutsideClickMonitor(void) {
  if (glimpseOutsideClickMonitor == nil) {
    return;
  }

  [NSEvent removeMonitor:glimpseOutsideClickMonitor];
  glimpseOutsideClickMonitor = nil;
}

void glimpse_native_configure_app(void) {
  dispatch_async(dispatch_get_main_queue(), ^{
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
  });
}

@interface GlimpseWindowDelegate : NSObject <NSWindowDelegate>
@end

@implementation GlimpseWindowDelegate
- (BOOL)windowShouldClose:(id)sender {
  glimpse_native_hide();
  return NO;
}

- (void)windowDidMove:(NSNotification *)notification {
  if (glimpsePanel != nil) {
    rememberFrame(glimpsePanel.frame);
  }
}

- (void)windowDidResize:(NSNotification *)notification {
  if (glimpsePanel != nil) {
    rememberFrame(glimpsePanel.frame);
  }
}
@end

static GlimpseWindowDelegate *glimpseWindowDelegate = nil;

static NSRect frameFromTopLeft(double x, double y, double width, double height) {
  NSScreen *screen = NSScreen.mainScreen;
  if (screen == nil) {
    return NSMakeRect(x, y, width, height);
  }

  NSPoint topLeft = NSMakePoint(x, y);
  for (NSScreen *candidate in NSScreen.screens) {
    NSRect frame = candidate.frame;
    NSRect topLeftFrame = NSMakeRect(frame.origin.x,
                                     NSMaxY(frame) - frame.size.height,
                                     frame.size.width,
                                     frame.size.height);

    if (NSPointInRect(topLeft, topLeftFrame)) {
      screen = candidate;
      break;
    }
  }

  NSRect screenFrame = screen.frame;
  CGFloat clampedX = fmin(fmax(x, NSMinX(screenFrame)), NSMaxX(screenFrame) - width);
  CGFloat clampedTopY = fmin(fmax(y, 0.0), screenFrame.size.height - height);
  CGFloat appKitY = NSMaxY(screenFrame) - clampedTopY - height;

  return NSMakeRect(clampedX, appKitY, width, height);
}

static NSString *stringFromCString(const char *value) {
  if (value == NULL || strlen(value) == 0) {
    return nil;
  }

  return [NSString stringWithUTF8String:value];
}

static void copyNSString(NSString *source, char *buffer, size_t bufferLength) {
  if (buffer == NULL || bufferLength == 0) {
    return;
  }

  if (source == nil) {
    buffer[0] = '\0';
    return;
  }

  const char *utf8 = [source UTF8String];
  if (utf8 == NULL) {
    buffer[0] = '\0';
    return;
  }

  strlcpy(buffer, utf8, bufferLength);
}

static NSArray<AVCaptureDevice *> *videoDevices(void) {
  AVCaptureDeviceDiscoverySession *discovery = [AVCaptureDeviceDiscoverySession
      discoverySessionWithDeviceTypes:@[
        AVCaptureDeviceTypeBuiltInWideAngleCamera,
        AVCaptureDeviceTypeExternal
      ]
                            mediaType:AVMediaTypeVideo
                             position:AVCaptureDevicePositionUnspecified];
  return discovery.devices ?: @[];
}

static AVCaptureDevice *selectedVideoDevice(void) {
  if (glimpseSelectedDeviceId != nil) {
    for (AVCaptureDevice *device in videoDevices()) {
      if ([device.uniqueID isEqualToString:glimpseSelectedDeviceId]) {
        return device;
      }
    }
  }

  AVCaptureDevice *defaultDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
  if (defaultDevice != nil) {
    return defaultDevice;
  }

  return videoDevices().firstObject;
}

static void showMessage(NSString *title, NSString *detail) {
  dispatch_async(dispatch_get_main_queue(), ^{
    glimpseMessageTitle.stringValue = title ?: @"Camera could not start";
    glimpseMessageDetail.stringValue = detail ?: @"";
    glimpseMessageTitle.hidden = NO;
    glimpseMessageDetail.hidden = NO;
    glimpsePreviewLayer.hidden = YES;
  });
}

static void hideMessage(void) {
  dispatch_async(dispatch_get_main_queue(), ^{
    glimpseMessageTitle.hidden = YES;
    glimpseMessageDetail.hidden = YES;
    glimpsePreviewLayer.hidden = NO;
  });
}

static void stopSession(void) {
  AVCaptureSession *session = glimpseSession;
  glimpseSession = nil;

  if (session == nil) {
    return;
  }

  dispatch_async(glimpseCameraQueue, ^{
    if (session.isRunning) {
      [session stopRunning];
    }
  });
}

static void startSession(void) {
  stopSession();
  hideMessage();

  AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
  if (status == AVAuthorizationStatusDenied || status == AVAuthorizationStatusRestricted) {
    showMessage(@"Camera permission is blocked",
                @"Allow camera access for Glimpse in System Settings, then reopen the preview.");
    return;
  }

  if (status == AVAuthorizationStatusNotDetermined) {
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
                             completionHandler:^(BOOL granted) {
                               dispatch_async(dispatch_get_main_queue(), ^{
                                 if (granted) {
                                   startSession();
                                 } else {
                                   showMessage(@"Camera permission is blocked",
                                               @"Allow camera access for Glimpse in System Settings, then reopen the preview.");
                                 }
                               });
                             }];
    return;
  }

  AVCaptureDevice *device = selectedVideoDevice();
  if (device == nil) {
    showMessage(@"No camera found", @"No video input device was detected.");
    return;
  }

  NSError *inputError = nil;
  AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&inputError];
  if (input == nil || inputError != nil) {
    showMessage(@"Camera could not start", inputError.localizedDescription ?: @"Unable to create camera input.");
    return;
  }

  AVCaptureSession *session = [[AVCaptureSession alloc] init];
  session.sessionPreset = AVCaptureSessionPresetHigh;

  if ([session canAddInput:input]) {
    [session addInput:input];
  } else {
    showMessage(@"Camera could not start", @"The selected camera could not be added to the capture session.");
    return;
  }

  glimpseSession = session;
  glimpsePreviewLayer.session = session;

  AVCaptureConnection *connection = glimpsePreviewLayer.connection;
  if (connection.supportsVideoMirroring) {
    connection.automaticallyAdjustsVideoMirroring = NO;
    connection.videoMirrored = YES;
  }

  dispatch_async(glimpseCameraQueue, ^{
    [session startRunning];
  });
}

static void ensurePanel(void) {
  if (glimpseCameraQueue == nil) {
    glimpseCameraQueue = dispatch_queue_create("com.glimpse.camera", DISPATCH_QUEUE_SERIAL);
  }

  if (glimpsePanel != nil) {
    return;
  }

  NSRect frame = NSMakeRect(200.0, 200.0, glimpseDefaultWidth, glimpseDefaultHeight);
  NSWindowStyleMask style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                            NSWindowStyleMaskResizable | NSWindowStyleMaskFullSizeContentView;

  glimpsePanel = [[NSPanel alloc] initWithContentRect:frame
                                           styleMask:style
                                             backing:NSBackingStoreBuffered
                                               defer:NO];
  glimpsePanel.title = @"Glimpse";
  glimpsePanel.titleVisibility = NSWindowTitleHidden;
  glimpsePanel.titlebarAppearsTransparent = YES;
  glimpsePanel.releasedWhenClosed = NO;
  glimpsePanel.movableByWindowBackground = YES;
  glimpsePanel.level = NSFloatingWindowLevel;
  glimpsePanel.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces |
                                    NSWindowCollectionBehaviorFullScreenAuxiliary;
  glimpsePanel.backgroundColor = NSColor.blackColor;

  glimpseWindowDelegate = [[GlimpseWindowDelegate alloc] init];
  glimpsePanel.delegate = glimpseWindowDelegate;

  glimpsePreviewView = [[NSView alloc] initWithFrame:NSMakeRect(0.0, 0.0, glimpseDefaultWidth, glimpseDefaultHeight)];
  glimpsePreviewView.wantsLayer = YES;
  glimpsePreviewView.layer.backgroundColor = NSColor.blackColor.CGColor;
  glimpsePreviewView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  glimpsePanel.contentView = glimpsePreviewView;

  glimpsePreviewLayer = [AVCaptureVideoPreviewLayer layer];
  glimpsePreviewLayer.frame = glimpsePreviewView.bounds;
  glimpsePreviewLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
  glimpsePreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
  [glimpsePreviewView.layer addSublayer:glimpsePreviewLayer];

  glimpseMessageTitle = [NSTextField labelWithString:@"Starting camera..."];
  glimpseMessageTitle.translatesAutoresizingMaskIntoConstraints = NO;
  glimpseMessageTitle.textColor = NSColor.whiteColor;
  glimpseMessageTitle.font = [NSFont systemFontOfSize:18.0 weight:NSFontWeightSemibold];
  glimpseMessageTitle.alignment = NSTextAlignmentCenter;
  glimpseMessageTitle.hidden = YES;

  glimpseMessageDetail = [NSTextField labelWithString:@""];
  glimpseMessageDetail.translatesAutoresizingMaskIntoConstraints = NO;
  glimpseMessageDetail.textColor = [NSColor colorWithWhite:0.76 alpha:1.0];
  glimpseMessageDetail.font = [NSFont systemFontOfSize:13.0];
  glimpseMessageDetail.alignment = NSTextAlignmentCenter;
  glimpseMessageDetail.lineBreakMode = NSLineBreakByWordWrapping;
  glimpseMessageDetail.maximumNumberOfLines = 4;
  glimpseMessageDetail.hidden = YES;

  [glimpsePreviewView addSubview:glimpseMessageTitle];
  [glimpsePreviewView addSubview:glimpseMessageDetail];

  [NSLayoutConstraint activateConstraints:@[
    [glimpseMessageTitle.centerXAnchor constraintEqualToAnchor:glimpsePreviewView.centerXAnchor],
    [glimpseMessageTitle.centerYAnchor constraintEqualToAnchor:glimpsePreviewView.centerYAnchor constant:-12.0],
    [glimpseMessageTitle.leadingAnchor constraintGreaterThanOrEqualToAnchor:glimpsePreviewView.leadingAnchor constant:24.0],
    [glimpseMessageTitle.trailingAnchor constraintLessThanOrEqualToAnchor:glimpsePreviewView.trailingAnchor constant:-24.0],
    [glimpseMessageDetail.topAnchor constraintEqualToAnchor:glimpseMessageTitle.bottomAnchor constant:10.0],
    [glimpseMessageDetail.leadingAnchor constraintEqualToAnchor:glimpsePreviewView.leadingAnchor constant:24.0],
    [glimpseMessageDetail.trailingAnchor constraintEqualToAnchor:glimpsePreviewView.trailingAnchor constant:-24.0],
  ]];
}

size_t glimpse_native_camera_count(void) {
  if (NSThread.isMainThread) {
    return videoDevices().count;
  }

  __block NSUInteger count = 0;
  dispatch_sync(dispatch_get_main_queue(), ^{
    count = videoDevices().count;
  });
  return count;
}

void glimpse_native_camera_info(size_t index, char *idBuffer, size_t idBufferLength,
                                char *nameBuffer, size_t nameBufferLength) {
  if (NSThread.isMainThread) {
    NSArray<AVCaptureDevice *> *devices = videoDevices();
    if (index >= devices.count) {
      copyNSString(nil, idBuffer, idBufferLength);
      copyNSString(nil, nameBuffer, nameBufferLength);
      return;
    }

    AVCaptureDevice *device = devices[index];
    copyNSString(device.uniqueID, idBuffer, idBufferLength);
    copyNSString(device.localizedName, nameBuffer, nameBufferLength);
    return;
  }

  dispatch_sync(dispatch_get_main_queue(), ^{
    NSArray<AVCaptureDevice *> *devices = videoDevices();
    if (index >= devices.count) {
      copyNSString(nil, idBuffer, idBufferLength);
      copyNSString(nil, nameBuffer, nameBufferLength);
      return;
    }

    AVCaptureDevice *device = devices[index];
    copyNSString(device.uniqueID, idBuffer, idBufferLength);
    copyNSString(device.localizedName, nameBuffer, nameBufferLength);
  });
}

bool glimpse_native_is_visible(void) {
  if (NSThread.isMainThread) {
    return glimpsePanel != nil && glimpsePanel.isVisible;
  }

  __block BOOL visible = NO;
  dispatch_sync(dispatch_get_main_queue(), ^{
    visible = glimpsePanel != nil && glimpsePanel.isVisible;
  });
  return visible;
}

void glimpse_native_show(double x, double y, double width, double height, const char *deviceId) {
  NSString *selectedDeviceId = stringFromCString(deviceId);

  dispatch_async(dispatch_get_main_queue(), ^{
    glimpseDefaultWidth = width;
    glimpseDefaultHeight = height;
    glimpseSelectedDeviceId = selectedDeviceId;

    ensurePanel();

    NSRect frame = glimpseHasSavedFrame ? glimpseSavedFrame : frameFromTopLeft(x, y, width, height);
    [glimpsePanel setFrame:frame display:YES];
    rememberFrame(glimpsePanel.frame);
    [glimpsePanel makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    installOutsideClickMonitor();
    startSession();
  });
}

void glimpse_native_hide(void) {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (glimpsePanel != nil) {
      rememberFrame(glimpsePanel.frame);
    }
    stopSession();
    removeOutsideClickMonitor();
    [glimpsePanel orderOut:nil];
  });
}

void glimpse_native_reset(double x, double y, double width, double height, const char *deviceId) {
  NSString *selectedDeviceId = stringFromCString(deviceId);

  dispatch_async(dispatch_get_main_queue(), ^{
    glimpseDefaultWidth = width;
    glimpseDefaultHeight = height;
    glimpseSelectedDeviceId = selectedDeviceId;

    ensurePanel();

    NSRect frame = frameFromTopLeft(x, y, width, height);
    [glimpsePanel setFrame:frame display:YES];
    rememberFrame(glimpsePanel.frame);
    [glimpsePanel makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    installOutsideClickMonitor();
    startSession();
  });
}

void glimpse_native_set_camera(const char *deviceId) {
  NSString *selectedDeviceId = stringFromCString(deviceId);

  dispatch_async(dispatch_get_main_queue(), ^{
    glimpseSelectedDeviceId = selectedDeviceId;
    if (glimpsePanel != nil && glimpsePanel.isVisible) {
      startSession();
    }
  });
}

void glimpse_native_restore_frame(double x, double y, double width, double height) {
  dispatch_async(dispatch_get_main_queue(), ^{
    glimpseSavedFrame = NSMakeRect(x, y, width, height);
    glimpseHasSavedFrame = YES;

    if (glimpsePanel != nil) {
      [glimpsePanel setFrame:glimpseSavedFrame display:YES];
    }
  });
}
