#import <Cocoa/Cocoa.h>

@interface DesktopSkinSessionObserver : NSObject
@property(nonatomic, copy) NSString *dispatcherPath;
@property(nonatomic, strong) NSMutableSet<NSString *> *pendingBundleIds;
@end

@implementation DesktopSkinSessionObserver

- (instancetype)initWithDispatcher:(NSString *)dispatcher {
  self = [super init];
  if (self) {
    _dispatcherPath = [dispatcher copy];
    _pendingBundleIds = [NSMutableSet set];
  }
  return self;
}

- (BOOL)isSupportedBundleId:(NSString *)bundleId {
  return [bundleId isEqualToString:@"com.workbuddy.workbuddy"] ||
    [bundleId isEqualToString:@"com.trae.solo.app"] ||
    [bundleId isEqualToString:@"com.trae.work.app"] ||
    [bundleId isEqualToString:@"cn.trae.solo.app"];
}

- (void)applicationDidLaunch:(NSNotification *)notification {
  NSRunningApplication *application = notification.userInfo[NSWorkspaceApplicationKey];
  NSString *bundleId = application.bundleIdentifier;
  if (![self isSupportedBundleId:bundleId]) return;

  @synchronized (self.pendingBundleIds) {
    if ([self.pendingBundleIds containsObject:bundleId]) return;
    [self.pendingBundleIds addObject:bundleId];
  }

  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.4 * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
    NSTask *task = [[NSTask alloc] init];
    task.executableURL = [NSURL fileURLWithPath:self.dispatcherPath];
    task.arguments = @[bundleId];
    task.standardOutput = [NSFileHandle fileHandleWithNullDevice];
    task.standardError = [NSFileHandle fileHandleWithNullDevice];
    task.terminationHandler = ^(NSTask *finishedTask) {
      @synchronized (self.pendingBundleIds) {
        [self.pendingBundleIds removeObject:bundleId];
      }
    };
    NSError *error = nil;
    if (![task launchAndReturnError:&error]) {
      @synchronized (self.pendingBundleIds) {
        [self.pendingBundleIds removeObject:bundleId];
      }
    }
  });
}

@end

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    if (argc != 2) return 2;
    NSString *dispatcher = [NSString stringWithUTF8String:argv[1]];
    if (![[NSFileManager defaultManager] isExecutableFileAtPath:dispatcher]) return 2;

    DesktopSkinSessionObserver *observer =
      [[DesktopSkinSessionObserver alloc] initWithDispatcher:dispatcher];
    NSNotificationCenter *center = NSWorkspace.sharedWorkspace.notificationCenter;
    [center addObserver:observer
               selector:@selector(applicationDidLaunch:)
                   name:NSWorkspaceDidLaunchApplicationNotification
                 object:nil];
    [[NSRunLoop currentRunLoop] run];
  }
  return 0;
}
