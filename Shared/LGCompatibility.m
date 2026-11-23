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
    /* Use an explicit default trait collection on the iOS 12 compatibility path. */
    UITraitCollection *traits = [UITraitCollection new];
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
