#import "LGCompatibility.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <math.h>

static const void *kLGCompatCornerCurveKey = &kLGCompatCornerCurveKey;
static const void *kLGCompatLayerFiltersKey = &kLGCompatLayerFiltersKey;
static const void *kLGCompatLayerBackgroundFiltersKey = &kLGCompatLayerBackgroundFiltersKey;
static const void *kLGCompatSymbolPointSizeKey = &kLGCompatSymbolPointSizeKey;
static const void *kLGCompatSymbolWeightKey = &kLGCompatSymbolWeightKey;
static const void *kLGCompatActionHandlerKey = &kLGCompatActionHandlerKey;
static const void *kLGCompatActionTitleKey = &kLGCompatActionTitleKey;
static const void *kLGCompatActionImageKey = &kLGCompatActionImageKey;
static const void *kLGCompatActionSenderKey = &kLGCompatActionSenderKey;
static const void *kLGCompatActionStateKey = &kLGCompatActionStateKey;
static const void *kLGCompatMenuChildrenKey = &kLGCompatMenuChildrenKey;
static const void *kLGCompatMenuTitleKey = &kLGCompatMenuTitleKey;
static const void *kLGCompatButtonMenuKey = &kLGCompatButtonMenuKey;
static const void *kLGCompatButtonShowsMenuKey = &kLGCompatButtonShowsMenuKey;
static const void *kLGCompatButtonMenuTargetKey = &kLGCompatButtonMenuTargetKey;
static const void *kLGCompatControlTargetsKey = &kLGCompatControlTargetsKey;
static const void *kLGCompatOverrideStyleKey = &kLGCompatOverrideStyleKey;

BOOL LGCompatIsIOS12OrEarlier(void) {
    return NSProcessInfo.processInfo.operatingSystemVersion.majorVersion <= 12;
}

BOOL LGCompatUsesLegacyMenus(void) {
    return NSProcessInfo.processInfo.operatingSystemVersion.majorVersion <= 13;
}

BOOL LGCompatIsDarkAppearance(UITraitCollection *traits) {
    if (!traits) return NO;
    SEL selector = NSSelectorFromString(@"userInterfaceStyle");
    if (![traits respondsToSelector:selector]) return NO;
    NSInteger style = ((NSInteger (*)(id, SEL))objc_msgSend)(traits, selector);
    return style == 2;
}

static UIColor *LGCompatRGB(CGFloat r, CGFloat g, CGFloat b) {
    return [UIColor colorWithRed:r green:g blue:b alpha:1.0];
}

static UIColor *LGCompatLabelColor(id self, SEL cmd) {
    (void)self; (void)cmd; return [UIColor blackColor];
}
static UIColor *LGCompatSecondaryLabelColor(id self, SEL cmd) {
    (void)self; (void)cmd; return [[UIColor blackColor] colorWithAlphaComponent:0.60];
}
static UIColor *LGCompatTertiaryLabelColor(id self, SEL cmd) {
    (void)self; (void)cmd; return [[UIColor blackColor] colorWithAlphaComponent:0.36];
}
static UIColor *LGCompatSeparatorColor(id self, SEL cmd) {
    (void)self; (void)cmd; return [[UIColor colorWithWhite:0.55 alpha:1.0] colorWithAlphaComponent:0.32];
}
static UIColor *LGCompatSystemBlue(id self, SEL cmd) { (void)self; (void)cmd; return LGCompatRGB(0.00, 0.48, 1.00); }
static UIColor *LGCompatSystemGreen(id self, SEL cmd) { (void)self; (void)cmd; return LGCompatRGB(0.20, 0.78, 0.35); }
static UIColor *LGCompatSystemRed(id self, SEL cmd) { (void)self; (void)cmd; return LGCompatRGB(1.00, 0.23, 0.19); }
static UIColor *LGCompatSystemOrange(id self, SEL cmd) { (void)self; (void)cmd; return LGCompatRGB(1.00, 0.58, 0.00); }
static UIColor *LGCompatSystemYellow(id self, SEL cmd) { (void)self; (void)cmd; return LGCompatRGB(1.00, 0.80, 0.00); }
static UIColor *LGCompatSystemPurple(id self, SEL cmd) { (void)self; (void)cmd; return LGCompatRGB(0.69, 0.32, 0.87); }
static UIColor *LGCompatSystemIndigo(id self, SEL cmd) { (void)self; (void)cmd; return LGCompatRGB(0.35, 0.34, 0.84); }
static UIColor *LGCompatSystemTeal(id self, SEL cmd) { (void)self; (void)cmd; return LGCompatRGB(0.19, 0.69, 0.78); }
static UIColor *LGCompatSystemGray(id self, SEL cmd) { (void)self; (void)cmd; return LGCompatRGB(0.56, 0.56, 0.58); }
static UIColor *LGCompatSystemGray5(id self, SEL cmd) { (void)self; (void)cmd; return LGCompatRGB(0.90, 0.90, 0.92); }
static UIColor *LGCompatSystemGroupedBackground(id self, SEL cmd) {
    (void)self; (void)cmd; return [UIColor groupTableViewBackgroundColor];
}
static UIColor *LGCompatSecondaryGroupedBackground(id self, SEL cmd) {
    (void)self; (void)cmd; return [UIColor colorWithWhite:0.96 alpha:1.0];
}
static UIColor *LGCompatTertiarySystemFill(id self, SEL cmd) {
    (void)self; (void)cmd; return [UIColor colorWithWhite:0.78 alpha:0.22];
}
static UIColor *LGCompatDynamicColor(id self, SEL cmd, id provider) {
    (void)self; (void)cmd;
    if (!provider) return nil;
    /* UIKit's iOS 13 dynamic colour API is reduced to a static light appearance on iOS 12. */
    UIColor *(^block)(UITraitCollection *) = (UIColor * (^)(UITraitCollection *))provider;
    if (!block) return nil;
    UITraitCollection *traits = [UITraitCollection currentTraitCollection];
    if (!traits) traits = [UITraitCollection new];
    return block(traits);
}

static id LGCompatLayerCornerCurve(id self, SEL cmd) {
    (void)cmd;
    return objc_getAssociatedObject(self, kLGCompatCornerCurveKey) ?: @"circular";
}
static void LGCompatSetLayerCornerCurve(id self, SEL cmd, id value) {
    (void)cmd;
    objc_setAssociatedObject(self, kLGCompatCornerCurveKey, value,
                             OBJC_ASSOCIATION_COPY_NONATOMIC);
}
static id LGCompatLayerFilters(id self, SEL cmd) {
    (void)cmd;
    return objc_getAssociatedObject(self, kLGCompatLayerFiltersKey);
}
static void LGCompatSetLayerFilters(id self, SEL cmd, id filters) {
    (void)cmd;
    objc_setAssociatedObject(self, kLGCompatLayerFiltersKey, filters,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
static id LGCompatLayerBackgroundFilters(id self, SEL cmd) {
    (void)cmd;
    return objc_getAssociatedObject(self, kLGCompatLayerBackgroundFiltersKey);
}
static void LGCompatSetLayerBackgroundFilters(id self, SEL cmd, id filters) {
    (void)cmd;
    objc_setAssociatedObject(self, kLGCompatLayerBackgroundFiltersKey, filters,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static NSInteger LGCompatTraitUserInterfaceStyle(id self, SEL cmd) {
    (void)self; (void)cmd; return 0; // unspecified/light on iOS 12
}
static id LGCompatWindowScene(id self, SEL cmd) { (void)self; (void)cmd; return nil; }
static NSInteger LGCompatViewOverrideStyle(id self, SEL cmd) {
    (void)cmd;
    NSNumber *value = objc_getAssociatedObject(self, kLGCompatOverrideStyleKey);
    return value ? value.integerValue : 0;
}
static void LGCompatViewSetOverrideStyle(id self, SEL cmd, NSInteger style) {
    (void)cmd;
    objc_setAssociatedObject(self, kLGCompatOverrideStyleKey, @(style),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static id LGCompatSymbolConfiguration(id cls, SEL cmd, double pointSize, double weight) {
    (void)cmd;
    Class configurationClass = (Class)cls;
    id config = [configurationClass new];
    objc_setAssociatedObject(config, kLGCompatSymbolPointSizeKey,
                             @(pointSize), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(config, kLGCompatSymbolWeightKey,
                             @(weight), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return config;
}

static NSString *LGCompatGlyphForSymbol(NSString *name) {
    static NSDictionary<NSString *, NSString *> *map;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = @{
            @"chevron.left": @"‹", @"chevron.right": @"›",
            @"chevron.up": @"⌃", @"chevron.down": @"⌄",
            @"checkmark": @"✓", @"arrow.counterclockwise": @"↶",
            @"doc.on.doc": @"▢", @"info.circle": @"ⓘ",
            @"iphone": @"▯", @"lock.fill": @"●",
            @"mic.fill": @"🎙", @"mic": @"🎙",
            @"arrow.counterclockwise.circle.fill": @"↶",
            @"line.3.horizontal": @"☰", @"exclamationmark.circle.fill": @"!",
            @"exclamationmark.bubble.fill": @"!", @"chevron.backward": @"‹",
            @"chevron.forward": @"›", @"app.fill": @"▣", @"apps.iphone": @"▦",
            @"bell.badge.fill": @"♟", @"bell.fill": @"♟", @"circle": @"●",
            @"circle.grid.3x3.fill": @"▦", @"clock.fill": @"◷", @"ellipsis.circle": @"•••",
            @"ellipsis.circle.fill": @"•••", @"folder": @"▱", @"folder.fill": @"▰",
            @"keyboard.fill": @"⌨", @"magnifyingglass": @"⌕",
            @"magnifyingglass.circle.fill": @"⌕", @"microphone": @"🎙",
            @"rectangle.3.group.fill": @"▤", @"rectangle.bottomthird.inset.filled": @"▱",
            @"rectangle.topthird.inset.filled": @"▱", @"slider.horizontal.3": @"☷",
            @"speaker.wave.3.fill": @"◖", @"square.grid.2x2.fill": @"▦", @"switch.2": @"◉",
            @"flashlight.on.fill": @"✦",
            @"hand.draw.fill": @"✋", @"hand.tap.fill": @"☝",
            @"info.circle.fill": @"ⓘ", @"lg.lockscreen.stacked": @"▤"
        };
    });
    return map[name] ?: @"•";
}

static UIImage *LGCompatDrawSymbol(NSString *name, id configuration) {
    if (![name isKindOfClass:NSString.class] || !name.length) return nil;
    NSNumber *configuredSize = configuration
        ? objc_getAssociatedObject(configuration, kLGCompatSymbolPointSizeKey) : nil;
    CGFloat pointSize = configuredSize ? configuredSize.doubleValue : 18.0;
    pointSize = MIN(72.0, MAX(8.0, pointSize));
    CGSize size = CGSizeMake(ceil(pointSize * 1.6), ceil(pointSize * 1.6));
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    NSString *glyph = LGCompatGlyphForSymbol(name);
    NSNumber *configuredWeight = configuration
        ? objc_getAssociatedObject(configuration, kLGCompatSymbolWeightKey) : nil;
    CGFloat weight = configuredWeight ? configuredWeight.doubleValue : UIFontWeightRegular;
    UIFont *font = [UIFont systemFontOfSize:pointSize weight:weight];
    NSDictionary *attributes = @{ NSFontAttributeName: font,
                                  NSForegroundColorAttributeName: UIColor.blackColor };
    CGSize glyphSize = [glyph sizeWithAttributes:attributes];
    [glyph drawAtPoint:CGPointMake((size.width - glyphSize.width) * 0.5,
                                   (size.height - glyphSize.height) * 0.5)
        withAttributes:attributes];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

static UIImage *LGCompatSystemImageNamed(id cls, SEL cmd, NSString *name) {
    (void)cmd; return LGCompatDrawSymbol(name, nil);
}
static UIImage *LGCompatSystemImageNamedWithConfiguration(id cls, SEL cmd,
                                                            NSString *name, id configuration) {
    (void)cls; (void)cmd; return LGCompatDrawSymbol(name, configuration);
}
static UIFont *LGCompatMonospacedSystemFont(id cls, SEL cmd, double size, double weight) {
    (void)cls; (void)cmd; (void)weight;
    UIFont *font = [UIFont fontWithName:@"Menlo-Regular" size:size];
    return font ?: [UIFont systemFontOfSize:size];
}

static id LGCompatActionHandler(id self, SEL cmd, id handler) {
    (void)cmd;
    Class actionClass = (Class)self;
    id action = [actionClass new];
    if (action) objc_setAssociatedObject(action, kLGCompatActionHandlerKey,
                                         handler, OBJC_ASSOCIATION_COPY_NONATOMIC);
    return action;
}
static id LGCompatActionWithTitle(id self, SEL cmd, NSString *title, UIImage *image,
                                  id identifier, id handler) {
    (void)identifier;
    id action = LGCompatActionHandler(self, cmd, handler);
    if (action) {
        objc_setAssociatedObject(action, kLGCompatActionTitleKey, title ?: @"",
                                 OBJC_ASSOCIATION_COPY_NONATOMIC);
        if (image) objc_setAssociatedObject(action, kLGCompatActionImageKey, image,
                                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return action;
}
static id LGCompatActionTitle(id self, SEL cmd) { (void)cmd; return objc_getAssociatedObject(self, kLGCompatActionTitleKey); }
static id LGCompatActionImage(id self, SEL cmd) { (void)cmd; return objc_getAssociatedObject(self, kLGCompatActionImageKey); }
static id LGCompatActionSender(id self, SEL cmd) { (void)cmd; return objc_getAssociatedObject(self, kLGCompatActionSenderKey); }
static void LGCompatSetActionSender(id self, SEL cmd, id sender) {
    (void)cmd;
    objc_setAssociatedObject(self, kLGCompatActionSenderKey, sender, OBJC_ASSOCIATION_ASSIGN);
}
static NSInteger LGCompatActionState(id self, SEL cmd) {
    (void)cmd; return [objc_getAssociatedObject(self, kLGCompatActionStateKey) integerValue];
}
static void LGCompatSetActionState(id self, SEL cmd, NSInteger state) {
    (void)cmd; objc_setAssociatedObject(self, kLGCompatActionStateKey, @(state), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
static void LGCompatInvokeAction(id action, id sender) {
    if (!action) return;
    objc_setAssociatedObject(action, kLGCompatActionSenderKey, sender, OBJC_ASSOCIATION_ASSIGN);
    id handler = objc_getAssociatedObject(action, kLGCompatActionHandlerKey);
    if (handler) {
        void (^block)(id) = handler;
        block(action);
    }
}

@interface LGCompatControlActionTarget : NSObject
@property (nonatomic, strong) id action;
- (void)fire:(id)sender;
@end
@implementation LGCompatControlActionTarget
- (void)fire:(id)sender { LGCompatInvokeAction(self.action, sender); }
@end

static void LGCompatControlAddAction(id self, SEL cmd, id action, NSUInteger events) {
    (void)cmd;
    if (!self || !action) return;
    LGCompatControlActionTarget *target = [LGCompatControlActionTarget new];
    target.action = action;
    NSMutableArray *targets = objc_getAssociatedObject(self, kLGCompatControlTargetsKey);
    if (!targets) {
        targets = [NSMutableArray array];
        objc_setAssociatedObject(self, kLGCompatControlTargetsKey, targets,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [targets addObject:target];
    [self addTarget:target action:@selector(fire:) forControlEvents:(UIControlEvents)events];
}

static id LGCompatMenuWithTitle(id self, SEL cmd, NSString *title, NSArray *children) {
    (void)cmd;
    Class menuClass = (Class)self;
    id menu = [menuClass new];
    if (menu) {
        objc_setAssociatedObject(menu, kLGCompatMenuTitleKey, title ?: @"",
                                 OBJC_ASSOCIATION_COPY_NONATOMIC);
        objc_setAssociatedObject(menu, kLGCompatMenuChildrenKey, children ?: @[],
                                 OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    return menu;
}
static id LGCompatMenuChildren(id self, SEL cmd) { (void)cmd; return objc_getAssociatedObject(self, kLGCompatMenuChildrenKey) ?: @[]; }
static id LGCompatMenuTitle(id self, SEL cmd) { (void)cmd; return objc_getAssociatedObject(self, kLGCompatMenuTitleKey) ?: @""; }

@implementation LGCompatUIMenuElement
- (NSInteger)state { return LGCompatActionState(self, _cmd); }
- (void)setState:(NSInteger)state { LGCompatSetActionState(self, _cmd, state); }
@end

@implementation LGCompatUIAction
+ (instancetype)actionWithHandler:(void (^)(LGCompatUIAction *))handler {
    if (!LGCompatUsesLegacyMenus()) {
        Class nativeClass = NSClassFromString(@"UIAction");
        SEL selector = NSSelectorFromString(@"actionWithHandler:");
        if (nativeClass && [nativeClass respondsToSelector:selector])
            return ((id (*)(id, SEL, id))objc_msgSend)(nativeClass, selector, handler);
    }
    return (id)LGCompatActionHandler(self, _cmd, handler);
}
+ (instancetype)actionWithTitle:(NSString *)title image:(UIImage *)image
                     identifier:(id)identifier
                        handler:(void (^)(LGCompatUIAction *))handler {
    if (!LGCompatUsesLegacyMenus()) {
        Class nativeClass = NSClassFromString(@"UIAction");
        SEL selector = NSSelectorFromString(@"actionWithTitle:image:identifier:handler:");
        if (nativeClass && [nativeClass respondsToSelector:selector])
            return ((id (*)(id, SEL, id, id, id, id))objc_msgSend)(nativeClass, selector,
                                                                     title, image, identifier, handler);
    }
    return (id)LGCompatActionWithTitle(self, _cmd, title, image, identifier, handler);
}
- (NSString *)title { return LGCompatActionTitle(self, _cmd) ?: @""; }
- (UIImage *)image { return LGCompatActionImage(self, _cmd); }
- (id)sender { return LGCompatActionSender(self, _cmd); }
@end

@implementation LGCompatUIMenu
+ (instancetype)menuWithTitle:(NSString *)title children:(NSArray *)children {
    if (!LGCompatUsesLegacyMenus()) {
        Class nativeClass = NSClassFromString(@"UIMenu");
        SEL selector = NSSelectorFromString(@"menuWithTitle:children:");
        if (nativeClass && [nativeClass respondsToSelector:selector])
            return ((id (*)(id, SEL, id, id))objc_msgSend)(nativeClass, selector, title, children);
    }
    return (id)LGCompatMenuWithTitle(self, _cmd, title, children);
}
- (NSString *)title { return LGCompatMenuTitle(self, _cmd); }
- (NSArray *)children { return LGCompatMenuChildren(self, _cmd); }
@end

@implementation LGCompatImageSymbolConfiguration
+ (instancetype)configurationWithPointSize:(CGFloat)pointSize weight:(CGFloat)weight {
    if (!LGCompatIsIOS12OrEarlier()) {
        Class nativeClass = NSClassFromString(@"UIImageSymbolConfiguration");
        SEL selector = NSSelectorFromString(@"configurationWithPointSize:weight:");
        if (nativeClass && [nativeClass respondsToSelector:selector])
            return ((id (*)(id, SEL, CGFloat, CGFloat))objc_msgSend)(nativeClass, selector,
                                                                      pointSize, weight);
    }
    return (id)LGCompatSymbolConfiguration(self, _cmd, pointSize, weight);
}
@end

static id LGCompatButtonMenu(id self, SEL cmd) { (void)cmd; return objc_getAssociatedObject(self, kLGCompatButtonMenuKey); }
static void LGCompatButtonEnsureMenuTarget(UIButton *button) {
    if (!button || ![objc_getAssociatedObject(button, kLGCompatButtonShowsMenuKey) boolValue] ||
        !objc_getAssociatedObject(button, kLGCompatButtonMenuKey) ||
        [objc_getAssociatedObject(button, kLGCompatButtonMenuTargetKey) boolValue]) return;
    objc_setAssociatedObject(button, kLGCompatButtonMenuTargetKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [button addTarget:button action:NSSelectorFromString(@"lgCompatPresentMenu")
     forControlEvents:UIControlEventTouchUpInside];
}
static void LGCompatButtonSetMenu(id self, SEL cmd, id menu) {
    (void)cmd;
    objc_setAssociatedObject(self, kLGCompatButtonMenuKey, menu, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    LGCompatButtonEnsureMenuTarget((UIButton *)self);
}
static BOOL LGCompatButtonShowsMenu(id self, SEL cmd) { (void)cmd; return [objc_getAssociatedObject(self, kLGCompatButtonShowsMenuKey) boolValue]; }
static void LGCompatButtonSetShowsMenu(id self, SEL cmd, BOOL show) {
    (void)cmd;
    objc_setAssociatedObject(self, kLGCompatButtonShowsMenuKey, @(show), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    LGCompatButtonEnsureMenuTarget((UIButton *)self);
}

static UIViewController *LGCompatTopController(UIViewController *controller) {
    while (controller.presentedViewController && !controller.presentedViewController.isBeingDismissed)
        controller = controller.presentedViewController;
    if ([controller isKindOfClass:UINavigationController.class])
        return LGCompatTopController(((UINavigationController *)controller).visibleViewController);
    if ([controller isKindOfClass:UITabBarController.class] && ((UITabBarController *)controller).selectedViewController)
        return LGCompatTopController(((UITabBarController *)controller).selectedViewController);
    return controller;
}
static void LGCompatPresentButtonMenu(id self, SEL cmd) {
    (void)cmd;
    UIButton *button = (UIButton *)self;
    id menu = objc_getAssociatedObject(button, kLGCompatButtonMenuKey);
    NSArray *children = menu ? objc_getAssociatedObject(menu, kLGCompatMenuChildrenKey) : nil;
    if (![children isKindOfClass:NSArray.class] || !children.count) return;

    UIViewController *presenter = LGCompatTopController(button.window.rootViewController);
    if (!presenter) {
        for (UIWindow *window in UIApplication.sharedApplication.windows) {
            if (!window.hidden && window.rootViewController) {
                presenter = LGCompatTopController(window.rootViewController);
                break;
            }
        }
    }
    if (!presenter || presenter.presentedViewController) return;

    NSString *title = objc_getAssociatedObject(menu, kLGCompatMenuTitleKey);
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:title.length ? title : nil
                                                                    message:nil
                                                             preferredStyle:UIAlertControllerStyleActionSheet];
    __weak UIButton *weakButton = button;
    for (id action in children) {
        NSString *actionTitle = objc_getAssociatedObject(action, kLGCompatActionTitleKey) ?: @"";
        if (!actionTitle.length) continue;
        [sheet addAction:[UIAlertAction actionWithTitle:actionTitle
                                                  style:UIAlertActionStyleDefault
                                                handler:^(__unused UIAlertAction *alertAction) {
            UIButton *strongButton = weakButton;
            LGCompatInvokeAction(action, strongButton);
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    UIPopoverPresentationController *popover = sheet.popoverPresentationController;
    if (popover) {
        popover.sourceView = button;
        popover.sourceRect = button.bounds;
        popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
    }
    [presenter presentViewController:sheet animated:YES completion:nil];
}

static BOOL LGCompatAddMethodIfMissing(Class cls, SEL selector, IMP implementation, const char *types) {
    if (!cls || class_getInstanceMethod(cls, selector)) return NO;
    return class_addMethod(cls, selector, implementation, types);
}
static BOOL LGCompatAddClassMethodIfMissing(Class cls, SEL selector, IMP implementation, const char *types) {
    if (!cls) return NO;
    Class meta = object_getClass((id)cls);
    if (class_getInstanceMethod(meta, selector)) return NO;
    return class_addMethod(meta, selector, implementation, types);
}

void LGCompatInstallRuntimeShims(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        BOOL isIOS12OrEarlier = LGCompatIsIOS12OrEarlier();
        BOOL usesLegacyMenus = LGCompatUsesLegacyMenus();
        if (!isIOS12OrEarlier && !usesLegacyMenus) return;

        if (isIOS12OrEarlier) {
        /* CALayer's continuous/circular corner mode was added after iOS 12. */
        LGCompatAddMethodIfMissing(CALayer.class, @selector(cornerCurve), (IMP)LGCompatLayerCornerCurve, "@@:");
        LGCompatAddMethodIfMissing(CALayer.class, @selector(setCornerCurve:), (IMP)LGCompatSetLayerCornerCurve, "v@:@");
        /* Some Core Animation builds do not expose the private filter accessors. */
        LGCompatAddMethodIfMissing(CALayer.class, NSSelectorFromString(@"filters"),
                                   (IMP)LGCompatLayerFilters, "@@:");
        LGCompatAddMethodIfMissing(CALayer.class, NSSelectorFromString(@"setFilters:"),
                                   (IMP)LGCompatSetLayerFilters, "v@:@");
        LGCompatAddMethodIfMissing(CALayer.class, NSSelectorFromString(@"backgroundFilters"),
                                   (IMP)LGCompatLayerBackgroundFilters, "@@:");
        LGCompatAddMethodIfMissing(CALayer.class, NSSelectorFromString(@"setBackgroundFilters:"),
                                   (IMP)LGCompatSetLayerBackgroundFilters, "v@:@");

        /* Semantic colours and dynamic-provider colours. */
        struct LGColorShim { const char *name; IMP imp; } colors[] = {
            {"labelColor", (IMP)LGCompatLabelColor},
            {"secondaryLabelColor", (IMP)LGCompatSecondaryLabelColor},
            {"tertiaryLabelColor", (IMP)LGCompatTertiaryLabelColor},
            {"separatorColor", (IMP)LGCompatSeparatorColor},
            {"systemBlueColor", (IMP)LGCompatSystemBlue},
            {"systemGreenColor", (IMP)LGCompatSystemGreen},
            {"systemRedColor", (IMP)LGCompatSystemRed},
            {"systemOrangeColor", (IMP)LGCompatSystemOrange},
            {"systemYellowColor", (IMP)LGCompatSystemYellow},
            {"systemPurpleColor", (IMP)LGCompatSystemPurple},
            {"systemIndigoColor", (IMP)LGCompatSystemIndigo},
            {"systemTealColor", (IMP)LGCompatSystemTeal},
            {"systemGrayColor", (IMP)LGCompatSystemGray},
            {"systemGray5Color", (IMP)LGCompatSystemGray5},
            {"systemGroupedBackgroundColor", (IMP)LGCompatSystemGroupedBackground},
            {"secondarySystemGroupedBackgroundColor", (IMP)LGCompatSecondaryGroupedBackground},
            {"tertiarySystemFillColor", (IMP)LGCompatTertiarySystemFill},
            {NULL, NULL}
        };
        for (NSUInteger i = 0; colors[i].name; i++) {
            LGCompatAddClassMethodIfMissing(UIColor.class, sel_registerName(colors[i].name), colors[i].imp, "@@:");
        }
        LGCompatAddClassMethodIfMissing(UIColor.class, @selector(colorWithDynamicProvider:),
                                        (IMP)LGCompatDynamicColor, "@@:@?");

        /* New trait/window/view properties read by modern source files. */
        LGCompatAddMethodIfMissing(UITraitCollection.class, @selector(userInterfaceStyle),
                                   (IMP)LGCompatTraitUserInterfaceStyle, "q@:");
        LGCompatAddMethodIfMissing(UIWindow.class, @selector(windowScene),
                                   (IMP)LGCompatWindowScene, "@@:");
        LGCompatAddMethodIfMissing(UIView.class, @selector(overrideUserInterfaceStyle),
                                   (IMP)LGCompatViewOverrideStyle, "q@:");
        LGCompatAddMethodIfMissing(UIView.class, @selector(setOverrideUserInterfaceStyle:),
                                   (IMP)LGCompatViewSetOverrideStyle, "v@:q");

        /* SF Symbols fallback: render a Unicode glyph instead of returning nil. */
        LGCompatAddClassMethodIfMissing(UIImage.class, NSSelectorFromString(@"systemImageNamed:"),
                                        (IMP)LGCompatSystemImageNamed, "@@:@");
        LGCompatAddClassMethodIfMissing(UIImage.class,
            NSSelectorFromString(@"systemImageNamed:withConfiguration:"),
            (IMP)LGCompatSystemImageNamedWithConfiguration, "@@:@@");
        LGCompatAddClassMethodIfMissing(UIFont.class,
            NSSelectorFromString(@"monospacedSystemFontOfSize:weight:"),
            (IMP)LGCompatMonospacedSystemFont, "@@:dd");

        }

        /* iOS 13 control-action API emulation backed by retained target-action objects. */
        if (usesLegacyMenus) {
        LGCompatAddMethodIfMissing(UIControl.class,
            NSSelectorFromString(@"addAction:forControlEvents:"),
            (IMP)LGCompatControlAddAction, "v@:@Q");

        LGCompatAddMethodIfMissing(UIButton.class, @selector(menu), (IMP)LGCompatButtonMenu, "@@:");
        LGCompatAddMethodIfMissing(UIButton.class, @selector(setMenu:), (IMP)LGCompatButtonSetMenu, "v@:@");
        LGCompatAddMethodIfMissing(UIButton.class, @selector(showsMenuAsPrimaryAction), (IMP)LGCompatButtonShowsMenu, "c@:");
        LGCompatAddMethodIfMissing(UIButton.class, @selector(setShowsMenuAsPrimaryAction:), (IMP)LGCompatButtonSetShowsMenu, "v@:c");
        LGCompatAddMethodIfMissing(UIButton.class, NSSelectorFromString(@"lgCompatPresentMenu"),
                                   (IMP)LGCompatPresentButtonMenu, "v@:");
        }
    });
}

__attribute__((constructor(101))) static void LGCompatEarlyConstructor(void) {
    @autoreleasepool { LGCompatInstallRuntimeShims(); }
}
