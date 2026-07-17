#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property(nonatomic, strong) NSStatusItem *statusItem;
@property(nonatomic, assign) BOOL sessionRestoreScheduled;
@end

@implementation AppDelegate

- (NSString *)home {
    return NSHomeDirectory();
}

- (NSString *)skillRoot {
    NSString *override = NSProcessInfo.processInfo.environment[@"CODEX_THEME_PACK_SKILL"];
    return override.length ? override : [[self home] stringByAppendingPathComponent:@".codex/skills/codex-theme-pet-studio"];
}

- (NSDictionary *)run:(NSString *)executable arguments:(NSArray<NSString *> *)arguments {
    NSTask *task = [[NSTask alloc] init];
    task.executableURL = [NSURL fileURLWithPath:executable];
    task.arguments = arguments;
    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;
    NSError *error = nil;
    if (![task launchAndReturnError:&error]) {
        return @{@"status": @1, @"output": error.localizedDescription ?: @"Launch failed"};
    }
    [task waitUntilExit];
    NSData *data = [pipe.fileHandleForReading readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"";
    return @{@"status": @(task.terminationStatus), @"output": output};
}

- (NSString *)currentPackID {
    NSString *path = [[self home] stringByAppendingPathComponent:@"Library/Application Support/CodexDreamSkinStudio/current-pack.json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!data) return nil;
    NSDictionary *value = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    return [value isKindOfClass:NSDictionary.class] ? value[@"id"] : nil;
}

- (NSArray<NSArray<NSString *> *> *)packs {
    NSString *python = @"/Users/kangkang/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3";
    NSDictionary *result = [self run:python arguments:@[
        [[self skillRoot] stringByAppendingPathComponent:@"scripts/list_packs.py"],
        @"--format", @"lines"
    ]];
    if ([result[@"status"] intValue] != 0) return @[];
    NSMutableArray *packs = [NSMutableArray array];
    for (NSString *line in [result[@"output"] componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet]) {
        NSArray *fields = [line componentsSeparatedByString:@"\t"];
        if (fields.count == 2) [packs addObject:fields];
    }
    return packs;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    self.statusItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.button.title = @"🤖 主题";
    self.statusItem.button.toolTip = @"Codex 主题套装";
    [self rebuildMenu];
    [NSWorkspace.sharedWorkspace.notificationCenter addObserver:self
                                                       selector:@selector(workspaceApplicationLaunched:)
                                                           name:NSWorkspaceDidLaunchApplicationNotification
                                                         object:nil];
    for (NSRunningApplication *application in NSWorkspace.sharedWorkspace.runningApplications) {
        if ([application.bundleIdentifier isEqualToString:@"com.openai.codex"]) {
            [self scheduleSessionRestore];
            break;
        }
    }
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    [NSWorkspace.sharedWorkspace.notificationCenter removeObserver:self];
}

- (void)application:(NSApplication *)application openURLs:(NSArray<NSURL *> *)urls {
    [self openChooser:nil];
}

- (void)workspaceApplicationLaunched:(NSNotification *)notification {
    NSRunningApplication *application = notification.userInfo[NSWorkspaceApplicationKey];
    if ([application.bundleIdentifier isEqualToString:@"com.openai.codex"]) {
        [self scheduleSessionRestore];
    }
}

- (void)scheduleSessionRestore {
    if (self.sessionRestoreScheduled) return;
    self.sessionRestoreScheduled = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)),
                   dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        [self run:@"/bin/bash" arguments:@[
            [[self skillRoot] stringByAppendingPathComponent:@"scripts/ensure_pack_session_macos.sh"]
        ]];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.sessionRestoreScheduled = NO;
            [self rebuildMenu];
        });
    });
}

- (void)rebuildMenu {
    NSMenu *menu = [[NSMenu alloc] init];
    NSMenuItem *heading = [[NSMenuItem alloc] initWithTitle:@"Codex 界面 + 宠物" action:nil keyEquivalent:@""];
    heading.enabled = NO;
    [menu addItem:heading];
    [menu addItem:NSMenuItem.separatorItem];

    NSString *current = [self currentPackID];
    NSArray *packs = [self packs];
    if (!packs.count) {
        NSMenuItem *empty = [[NSMenuItem alloc] initWithTitle:@"还没有主题套装" action:nil keyEquivalent:@""];
        empty.enabled = NO;
        [menu addItem:empty];
    } else {
        for (NSArray<NSString *> *pack in packs) {
            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:pack[1] action:@selector(switchPack:) keyEquivalent:@""];
            item.target = self;
            item.representedObject = pack[0];
            item.state = [pack[0] isEqualToString:current] ? NSControlStateValueOn : NSControlStateValueOff;
            [menu addItem:item];
        }
    }
    [menu addItem:NSMenuItem.separatorItem];
    NSMenuItem *refresh = [[NSMenuItem alloc] initWithTitle:@"刷新套装列表" action:@selector(refreshMenu:) keyEquivalent:@"r"];
    refresh.target = self;
    [menu addItem:refresh];
    NSMenuItem *chooser = [[NSMenuItem alloc] initWithTitle:@"打开选择器" action:@selector(openChooser:) keyEquivalent:@""];
    chooser.target = self;
    [menu addItem:chooser];
    [menu addItem:NSMenuItem.separatorItem];
    NSMenuItem *quit = [[NSMenuItem alloc] initWithTitle:@"退出菜单栏工具" action:@selector(quit:) keyEquivalent:@"q"];
    quit.target = self;
    [menu addItem:quit];
    self.statusItem.menu = menu;
}

- (void)refreshMenu:(id)sender {
    [self rebuildMenu];
}

- (void)openChooser:(id)sender {
    NSTask *task = [[NSTask alloc] init];
    task.executableURL = [NSURL fileURLWithPath:@"/bin/bash"];
    task.arguments = @[[[self skillRoot] stringByAppendingPathComponent:@"scripts/choose_pack_macos.sh"]];
    [task launchAndReturnError:nil];
}

- (void)switchPack:(NSMenuItem *)sender {
    NSString *packID = sender.representedObject;
    self.statusItem.button.title = @"⏳ 主题";
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSDictionary *result = [self run:@"/bin/bash" arguments:@[
            [[self skillRoot] stringByAppendingPathComponent:@"scripts/switch_pack_macos.sh"],
            @"--id", packID
        ]];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.statusItem.button.title = [result[@"status"] intValue] == 0 ? @"🤖 主题" : @"⚠️ 主题";
            [self rebuildMenu];
            if ([result[@"status"] intValue] != 0) {
                NSAlert *alert = [[NSAlert alloc] init];
                alert.messageText = @"主题套装切换失败";
                NSString *output = result[@"output"];
                alert.informativeText = output.length > 600 ? [output substringFromIndex:output.length - 600] : output;
                [alert runModal];
            }
        });
    });
}

- (void)quit:(id)sender {
    [NSApp terminate:nil];
}

@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSApplication *app = NSApplication.sharedApplication;
        AppDelegate *delegate = [[AppDelegate alloc] init];
        app.delegate = delegate;
        [app setActivationPolicy:NSApplicationActivationPolicyAccessory];
        [app run];
    }
    return 0;
}
