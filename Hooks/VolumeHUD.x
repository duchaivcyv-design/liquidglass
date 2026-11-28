#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import "../Shared/LGLiveBackdropView.h"
#import "../Shared/LGGlassKit.h"
#import "../Shared/LGSharedSupport.h"
#import "../Shared/LGCompatibility.h"

@interface MTMaterialView : UIView
@end

@interface CCUIContinuousSliderView : UIControl
@end

@interface SBElasticSliderView : CCUIContinuousSliderView
@end

@interface SBElasticVolumeSliderView : SBElasticSliderView
@end

@interface SBElasticSliderMaterialWrapperView : UIView {
    MTMaterialView *_captureOnlyMaterialView;
    MTMaterialView *_baseMaterialView;
    UIView *_shadowView;
    UIView *_sliderWrapperView;
    UIView *_maskView;
    SBElasticVolumeSliderView *_sliderView;
}
- (void)_setContinuousCornerRadius:(double)radius;
@end

@interface LGVolumeHUDVibranceView : UIView {
    UIVisualEffectView *_compatibilityBlurView;
}
@end

@implementation LGVolumeHUDVibranceView

+ (Class)layerClass {
    if (LGCompatIsIOS12OrEarlier()) return [CALayer class];
    return NSClassFromString(@"CABackdropLayer") ?: [CALayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        self.backgroundColor = [UIColor clearColor];
        self.autoresizingMask = UIViewAutoresizingNone;
        [self applyVibranceFilters];
    }
    return self;
}

- (void)applyVibranceFilters {
    if (LGCompatIsIOS12OrEarlier()) {
        if (!_compatibilityBlurView) {
            _compatibilityBlurView = [[UIVisualEffectView alloc]
                initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
            _compatibilityBlurView.userInteractionEnabled = NO;
            _compatibilityBlurView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                                       UIViewAutoresizingFlexibleHeight;
            _compatibilityBlurView.clipsToBounds = YES;
            [self insertSubview:_compatibilityBlurView atIndex:0];
        }
        _compatibilityBlurView.frame = self.bounds;
        _compatibilityBlurView.layer.cornerRadius = self.layer.cornerRadius;
        self.layer.masksToBounds = YES;
        return;
    }
    @try {
        CALayer *layer = self.layer;
        if (![layer isKindOfClass:NSClassFromString(@"CABackdropLayer")]) return;

        Class filterCls = NSClassFromString(@"CAFilter");
        if (!filterCls) return;

        NSMutableArray *filters = [NSMutableArray array];

        id satFilter = ((id (*)(Class, SEL, NSString *))objc_msgSend)(
            filterCls, NSSelectorFromString(@"filterWithType:"), @"colorSaturate");
        if (satFilter) {
            @try { [satFilter setValue:@(1.85) forKey:@"inputAmount"]; } @catch (...) {}
            [filters addObject:satFilter];
        }

        id contrastFilter = ((id (*)(Class, SEL, NSString *))objc_msgSend)(
            filterCls, NSSelectorFromString(@"filterWithType:"), @"colorContrast");
        if (contrastFilter) {
            @try { [contrastFilter setValue:@(1.06) forKey:@"inputAmount"]; } @catch (...) {}
            [filters addObject:contrastFilter];
        }

        layer.filters = filters;
    } @catch (NSException *e) {}
}

@end

static const void * const kLGVolumeHUDGlassKey = &kLGVolumeHUDGlassKey;
static const void * const kLGVolumeHUDVibranceKey = &kLGVolumeHUDVibranceKey;
static const void * const kLGVolumeHUDMaterialHiddenKey = &kLGVolumeHUDMaterialHiddenKey;
static const void * const kLGVolumeHUDProbePendingKey = &kLGVolumeHUDProbePendingKey;
static const void * const kLGLegacyVolumeHUDBackgroundKey = &kLGLegacyVolumeHUDBackgroundKey;
static const void * const kLGLegacyVolumeHUDOriginalOpaqueKey = &kLGLegacyVolumeHUDOriginalOpaqueKey;
static const void * const kLGLegacyVolumeHUDOriginalRadiusKey = &kLGLegacyVolumeHUDOriginalRadiusKey;
static const void * const kLGLegacyVolumeHUDOriginalClipsKey = &kLGLegacyVolumeHUDOriginalClipsKey;
static __weak UIView *sLGLegacyVolumeHUDView;

static BOOL LGVolumeHUDEnabled(void) {
    return lgHostEnabled(@"VolumeHUD");
}

static BOOL LGVolumeHUDNeedsLegacyMaterialWorkaround(void) {
    return NSProcessInfo.processInfo.operatingSystemVersion.majorVersion < 16;
}

static UIView *LGVolumeHUDDescendant(UIView *view, Class targetClass) {
    if ([view isKindOfClass:targetClass]) return view;
    for (UIView *subview in view.subviews) {
        UIView *found = LGVolumeHUDDescendant(subview, targetClass);
        if (found) return found;
    }
    return nil;
}

static void LGSetVolumeHUDBackgroundMaterialsHidden(UIView *view, BOOL hidden) {
    if ([view isKindOfClass:NSClassFromString(@"MTMaterialView")] &&
        [view.superview isKindOfClass:NSClassFromString(@"MTMaterialShadowView")]) {
        NSNumber *original = objc_getAssociatedObject(view, kLGVolumeHUDMaterialHiddenKey);
        if (hidden) {
            if (!original)
                objc_setAssociatedObject(view, kLGVolumeHUDMaterialHiddenKey, @(view.hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            view.hidden = YES;
        } else if (original) {
            view.hidden = original.boolValue;
            objc_setAssociatedObject(view, kLGVolumeHUDMaterialHiddenKey, nil, OBJC_ASSOCIATION_ASSIGN);
        }
    }
    for (UIView *subview in view.subviews) LGSetVolumeHUDBackgroundMaterialsHidden(subview, hidden);
}

static void LGAppendVolumeHUDMaterialRows(UIView *view, NSString *path,
                                          NSMutableArray<NSString *> *rows) {
    NSString *nextPath = [path stringByAppendingFormat:@"/%@", NSStringFromClass(view.class)];
    if ([view isKindOfClass:NSClassFromString(@"MTMaterialView")])
        [rows addObject:[NSString stringWithFormat:@"%@ frame=%@ hidden=%d alpha=%.2f radius=%.2f",
            nextPath, NSStringFromCGRect(view.frame), view.hidden, view.alpha, view.layer.cornerRadius]];
    for (UIView *subview in view.subviews) LGAppendVolumeHUDMaterialRows(subview, nextPath, rows);
}

static void LGScheduleVolumeHUDProbe(UIView *wrapper) {
    if (!LGDebugLoggingEnabled() || [objc_getAssociatedObject(wrapper, kLGVolumeHUDProbePendingKey) boolValue]) return;
    objc_setAssociatedObject(wrapper, kLGVolumeHUDProbePendingKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        objc_setAssociatedObject(wrapper, kLGVolumeHUDProbePendingKey, nil, OBJC_ASSOCIATION_ASSIGN);
        if (!wrapper.window) return;
        NSMutableArray<NSString *> *rows = [NSMutableArray array];
        LGAppendVolumeHUDMaterialRows(wrapper, @"", rows);
        LGLog(@"[VolumeHUD probe] wrapper=%@ bounds=%@ materials=[%@]",
              NSStringFromClass(wrapper.class), NSStringFromCGRect(wrapper.bounds),
              [rows componentsJoinedByString:@" | "]);
    });
}

static void LGUpdateVolumeHUDGlass(SBElasticSliderMaterialWrapperView *self) {
    if (!self) return;

    MTMaterialView *base = nil;
    MTMaterialView *cap = nil;
    UIView *shadow = nil;
    UIView *sliderWrapper = nil;
    UIView *sliderView = nil;
    @try {
        base = [self valueForKey:@"_baseMaterialView"];
        cap = [self valueForKey:@"_captureOnlyMaterialView"];
        shadow = [self valueForKey:@"_shadowView"];
        sliderWrapper = [self valueForKey:@"_sliderWrapperView"];
        sliderView = [self valueForKey:@"_sliderView"];
    } @catch (...) {}
    if (!sliderView)
        sliderView = LGVolumeHUDDescendant(self, NSClassFromString(@"SBElasticVolumeSliderView"));

    if (!LGVolumeHUDEnabled()) {
        LGLiveBackdropView *existing = objc_getAssociatedObject(self, kLGVolumeHUDGlassKey);
        if (existing) existing.hidden = YES;
        LGVolumeHUDVibranceView *existingVib = objc_getAssociatedObject(self, kLGVolumeHUDVibranceKey);
        if (existingVib) existingVib.hidden = YES;
        if (base) base.hidden = NO;
        if (cap) cap.hidden = NO;
        if (shadow) shadow.hidden = NO;
        LGSetVolumeHUDBackgroundMaterialsHidden(self, NO);
        return;
    }

    if (base) base.hidden = YES;
    if (cap) cap.hidden = YES;
    if (shadow) shadow.hidden = YES;
    LGSetVolumeHUDBackgroundMaterialsHidden(self, YES);

    LGVolumeHUDVibranceView *vibrance = objc_getAssociatedObject(self, kLGVolumeHUDVibranceKey);
    if (!vibrance) {
        vibrance = [[LGVolumeHUDVibranceView alloc] initWithFrame:self.bounds];
        if (vibrance) {
            objc_setAssociatedObject(self, kLGVolumeHUDVibranceKey, vibrance, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            if (sliderWrapper) {
                [self insertSubview:vibrance belowSubview:sliderWrapper];
            } else {
                [self addSubview:vibrance];
            }
        }
    }

    LGLiveBackdropView *glass = objc_getAssociatedObject(self, kLGVolumeHUDGlassKey);
    if (!glass) {
        glass = LGCreateRegisteredGlass(self.bounds, nil, @"VolumeHUD");
        if (!glass) return;
        objc_setAssociatedObject(self, kLGVolumeHUDGlassKey, glass, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        lgTrackGlass(glass, @"VolumeHUD", self);

        [self insertSubview:glass atIndex:0];
    }

    CGFloat radius = MIN(self.bounds.size.width, self.bounds.size.height) * 0.5f;

    glass.hidden = NO;
    glass.frame = self.bounds;
    glass.layer.cornerRadius = radius;
    LGCompatApplyCornerCurve(glass.layer, kCACornerCurveContinuous);
    glass.layer.masksToBounds = YES;
    [glass applyFilters];

    if (vibrance) {
        vibrance.hidden = NO;
        vibrance.frame = self.bounds;
        vibrance.layer.cornerRadius = radius;
        LGCompatApplyCornerCurve(vibrance.layer, kCACornerCurveContinuous);
        vibrance.layer.masksToBounds = YES;
    }

    self.layer.cornerRadius = radius;
    LGCompatApplyCornerCurve(self.layer, kCACornerCurveContinuous);

    if (sliderWrapper) {
        sliderWrapper.layer.cornerRadius = radius;
        LGCompatApplyCornerCurve(sliderWrapper.layer, kCACornerCurveContinuous);
        sliderWrapper.layer.masksToBounds = YES;
    }

    if (sliderView) {
        sliderView.layer.cornerRadius = radius;
        LGCompatApplyCornerCurve(sliderView.layer, kCACornerCurveContinuous);
        sliderView.layer.masksToBounds = YES;
        if (LGVolumeHUDNeedsLegacyMaterialWorkaround()) {
            for (UIView *subview in sliderView.subviews) {
                if (![subview isKindOfClass:NSClassFromString(@"MTMaterialView")]) continue;
                subview.layer.cornerRadius = radius;
                LGCompatApplyCornerCurve(subview.layer, kCACornerCurveContinuous);
                subview.layer.masksToBounds = YES;
            }
        }
    }
    LGScheduleVolumeHUDProbe(self);
}

static void LGUpdateLegacyVolumeHUDGlass(UIView *hud) {
    if (!hud || !LGCompatIsIOS12OrEarlier()) return;
    NSString *className = NSStringFromClass(hud.class);
    /* Do not change brightness, alert or unrelated SBHUDController surfaces. */
    if ([className rangeOfString:@"Volume" options:NSCaseInsensitiveSearch].location == NSNotFound)
        return;

    sLGLegacyVolumeHUDView = hud;
    LGLiveBackdropView *glass = objc_getAssociatedObject(hud, kLGVolumeHUDGlassKey);
    if (!LGVolumeHUDEnabled()) {
        [glass removeFromSuperview];
        objc_setAssociatedObject(hud, kLGVolumeHUDGlassKey, nil, OBJC_ASSOCIATION_ASSIGN);
        LGSetVolumeHUDBackgroundMaterialsHidden(hud, NO);
        UIColor *originalBackground = objc_getAssociatedObject(hud, kLGLegacyVolumeHUDBackgroundKey);
        hud.backgroundColor = originalBackground == (id)NSNull.null ? nil : originalBackground;
        NSNumber *opaque = objc_getAssociatedObject(hud, kLGLegacyVolumeHUDOriginalOpaqueKey);
        NSNumber *radius = objc_getAssociatedObject(hud, kLGLegacyVolumeHUDOriginalRadiusKey);
        NSNumber *clips = objc_getAssociatedObject(hud, kLGLegacyVolumeHUDOriginalClipsKey);
        if (opaque) hud.opaque = opaque.boolValue;
        if (radius) hud.layer.cornerRadius = radius.doubleValue;
        if (clips) hud.clipsToBounds = clips.boolValue;
        objc_setAssociatedObject(hud, kLGLegacyVolumeHUDBackgroundKey, nil, OBJC_ASSOCIATION_ASSIGN);
        objc_setAssociatedObject(hud, kLGLegacyVolumeHUDOriginalOpaqueKey, nil, OBJC_ASSOCIATION_ASSIGN);
        objc_setAssociatedObject(hud, kLGLegacyVolumeHUDOriginalRadiusKey, nil, OBJC_ASSOCIATION_ASSIGN);
        objc_setAssociatedObject(hud, kLGLegacyVolumeHUDOriginalClipsKey, nil, OBJC_ASSOCIATION_ASSIGN);
        return;
    }

    if (!objc_getAssociatedObject(hud, kLGLegacyVolumeHUDOriginalOpaqueKey)) {
        objc_setAssociatedObject(hud, kLGLegacyVolumeHUDBackgroundKey,
                                 hud.backgroundColor ?: (id)NSNull.null,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(hud, kLGLegacyVolumeHUDOriginalOpaqueKey, @(hud.opaque),
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(hud, kLGLegacyVolumeHUDOriginalRadiusKey, @(hud.layer.cornerRadius),
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(hud, kLGLegacyVolumeHUDOriginalClipsKey, @(hud.clipsToBounds),
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    CGFloat width = CGRectGetWidth(hud.bounds);
    CGFloat height = CGRectGetHeight(hud.bounds);
    if (width < 2.0 || height < 2.0) return;
    CGFloat radius = MIN(MIN(width, height) * 0.24, 22.0);

    hud.backgroundColor = UIColor.clearColor;
    hud.opaque = NO;
    hud.layer.cornerRadius = radius;
    hud.clipsToBounds = YES;
    LGSetVolumeHUDBackgroundMaterialsHidden(hud, YES);

    if (!glass) {
        glass = LGCreateRegisteredGlass(hud.bounds, nil, @"VolumeHUD");
        if (!glass) return;
        objc_setAssociatedObject(hud, kLGVolumeHUDGlassKey, glass,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        lgTrackGlass(glass, @"VolumeHUD", hud);
        [hud insertSubview:glass atIndex:0];
    }
    glass.hidden = NO;
    glass.frame = hud.bounds;
    glass.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    glass.layer.cornerRadius = radius;
    LGCompatApplyCornerCurve(glass.layer, kCACornerCurveContinuous);
    glass.layer.masksToBounds = YES;
    [glass applyFilters];
}

%group LGLegacyVolumeHUDHooks

%hook SBHUDController

- (void)presentHUDView:(UIView *)hud autoDismissWithDelay:(double)delay {
    %orig;
    dispatch_async(dispatch_get_main_queue(), ^{
        LGUpdateLegacyVolumeHUDGlass(hud);
    });
}

%end

%end

%group LGVolumeHUDHooks

%hook SBElasticSliderMaterialWrapperView

- (instancetype)initWithFrame:(CGRect)frame {
    self = %orig;
    if (self) {
        LGUpdateVolumeHUDGlass(self);
    }
    return self;
}

- (instancetype)initWithSliderView:(id)sliderView {
    self = %orig;
    if (self) {
        LGUpdateVolumeHUDGlass(self);
    }
    return self;
}

- (void)layoutSubviews {
    %orig;
    LGUpdateVolumeHUDGlass(self);
}

- (void)_setContinuousCornerRadius:(double)radius {
    if (LGVolumeHUDEnabled()) {
        CGFloat pillRadius = MIN(self.bounds.size.width, self.bounds.size.height) * 0.5f;
        %orig((double)pillRadius);
        LGLiveBackdropView *glass = objc_getAssociatedObject(self, kLGVolumeHUDGlassKey);
        if (glass) {
            glass.layer.cornerRadius = pillRadius;
            LGCompatApplyCornerCurve(glass.layer, kCACornerCurveContinuous);
        }
        LGVolumeHUDVibranceView *vibrance = objc_getAssociatedObject(self, kLGVolumeHUDVibranceKey);
        if (vibrance) {
            vibrance.layer.cornerRadius = pillRadius;
            LGCompatApplyCornerCurve(vibrance.layer, kCACornerCurveContinuous);
        }
    } else {
        %orig;
    }
}

%end

%end

%ctor {
    if (!LGIsSpringBoardProcess()) return;

    if (LGCompatIsIOS12OrEarlier()) {
        Class hudController = NSClassFromString(@"SBHUDController");
        SEL presentSelector = NSSelectorFromString(@"presentHUDView:autoDismissWithDelay:");
        if (hudController && class_getInstanceMethod(hudController, presentSelector))
            %init(LGLegacyVolumeHUDHooks);
    } else {
        Class modernWrapper = NSClassFromString(@"SBElasticSliderMaterialWrapperView");
        if (modernWrapper) %init(LGVolumeHUDHooks);
    }

    lgObservePreferenceReload(^{
        UIView *legacyHUD = sLGLegacyVolumeHUDView;
        if (legacyHUD && LGCompatIsIOS12OrEarlier())
            LGUpdateLegacyVolumeHUDGlass(legacyHUD);
        LGLog(@"VolumeHUD: Preferences reloaded");
    });
}
