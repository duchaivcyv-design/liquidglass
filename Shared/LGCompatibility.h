#pragma once

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

/*
 * Runtime compatibility layer for LiquidAss.
 * The public UI surface below is deliberately implemented with runtime shims
 * instead of assuming iOS 13/14 UIKit symbols exist on iOS 12.
 */

#ifdef kCACornerCurveContinuous
#undef kCACornerCurveContinuous
#endif
#ifdef kCACornerCurveCircular
#undef kCACornerCurveCircular
#endif
#define kCACornerCurveContinuous ((CALayerCornerCurve)@"continuous")
#define kCACornerCurveCircular   ((CALayerCornerCurve)@"circular")

/* SF Symbol weight constants are not exported by UIKit on iOS 12. */
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 130000
#ifdef UIImageSymbolWeightRegular
#undef UIImageSymbolWeightRegular
#endif
#ifdef UIImageSymbolWeightSemibold
#undef UIImageSymbolWeightSemibold
#endif
#ifdef UIImageSymbolWeightBold
#undef UIImageSymbolWeightBold
#endif
#define UIImageSymbolWeightRegular   ((CGFloat)0.0)
#define UIImageSymbolWeightSemibold  ((CGFloat)0.30)
#define UIImageSymbolWeightBold      ((CGFloat)0.40)
#endif

NS_ASSUME_NONNULL_BEGIN

#if __IPHONE_OS_VERSION_MIN_REQUIRED < 130000
/*
 * Avoid weak class references to UIKit classes that do not exist on iOS 12.
 * The project uses only the small subset below; these local classes provide
 * equivalent storage/callback semantics and are presented by our shim.
 */
@interface LGCompatUIMenuElement : NSObject
@property (nonatomic) NSInteger state;
@end

@interface LGCompatUIAction : LGCompatUIMenuElement
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, strong, readonly) UIImage *image;
@property (nonatomic, weak, readonly) id sender;
+ (instancetype)actionWithHandler:(void (^)(LGCompatUIAction *action))handler;
+ (instancetype)actionWithTitle:(NSString *)title
                          image:(UIImage *)image
                     identifier:(id _Nullable)identifier
                        handler:(void (^)(LGCompatUIAction *action))handler;
@end

@interface LGCompatUIMenu : LGCompatUIMenuElement
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSArray<LGCompatUIMenuElement *> *children;
+ (instancetype)menuWithTitle:(NSString *)title children:(NSArray<LGCompatUIMenuElement *> *)children;
@end

@interface LGCompatImageSymbolConfiguration : NSObject
+ (instancetype)configurationWithPointSize:(CGFloat)pointSize weight:(CGFloat)weight;
@end

#define UIAction LGCompatUIAction
#define UIMenu LGCompatUIMenu
#define UIMenuElement LGCompatUIMenuElement
#define UIImageSymbolConfiguration LGCompatImageSymbolConfiguration
#endif

FOUNDATION_EXPORT BOOL LGCompatIsIOS12OrEarlier(void);
FOUNDATION_EXPORT BOOL LGCompatUsesLegacyMenus(void);
FOUNDATION_EXPORT BOOL LGCompatIsDarkAppearance(UITraitCollection * _Nullable traits);
FOUNDATION_EXPORT void LGCompatInstallRuntimeShims(void);

/*
 * CALayer.cornerCurve was introduced in iOS 13. Direct property access
 * trips -Wunguarded-availability-new against an iOS 12 deployment target.
 * Route through these helpers instead: they call native selectors on 13+
 * and hit the runtime shims installed by LGCompatInstallRuntimeShims on 12.
 */
FOUNDATION_EXPORT void LGCompatApplyCornerCurve(CALayer *layer, NSString *curve);
FOUNDATION_EXPORT NSString *_Nullable LGCompatReadCornerCurve(CALayer *layer);

/*
 * Call-site helpers for iOS 13/14 UIKit APIs that are otherwise gated by
 * -Wunguarded-availability-new (or by type-mismatch after the #define
 * remaps above). Each helper probes the selector at runtime, so it works
 * on iOS 12 via shims and on 13+/14+ via the native implementation.
 */
FOUNDATION_EXPORT UIColor *LGCompatSeparatorColorValue(void);
FOUNDATION_EXPORT UIColor *LGCompatLabelColorValue(void);
FOUNDATION_EXPORT UIColor *_Nullable LGCompatCreateDynamicColor(
    UIColor * _Nonnull (^provider)(UITraitCollection *));
FOUNDATION_EXPORT UIImage *_Nullable LGCompatSystemImageNamedConfigured(
    NSString *name, id _Nullable configuration);
FOUNDATION_EXPORT void LGCompatSetButtonMenu(UIButton *button, id _Nullable menu);
FOUNDATION_EXPORT void LGCompatSetButtonShowsMenu(UIButton *button, BOOL show);

/*
 * UIColor.resolvedColorWithTraitCollection: is iOS 13+. On iOS 12 the
 * colour is already static, so the helper just returns the input colour.
 */
FOUNDATION_EXPORT UIColor *_Nullable LGCompatResolvedColor(
    UIColor * _Nonnull color, UITraitCollection * _Nullable traits);

/*
 * UIHoverGestureRecognizer is iOS 13+. Callers use this lookup instead of
 * naming the class directly, so the symbol is never resolved on iOS 12
 * (returns nil there and the caller skips hover setup).
 */
FOUNDATION_EXPORT Class _Nullable LGCompatHoverGestureRecognizerClass(void);

NS_ASSUME_NONNULL_END
