#import "SettingsUI.h"

@interface SettingsUI ()
@property (nonatomic, strong) UISwitch *enabledSwitch;
@property (nonatomic, strong) UISlider *eloSlider;
@property (nonatomic, strong) UILabel *eloLabel;
@property (nonatomic, strong) UISlider *arrowSlider;
@property (nonatomic, strong) UILabel *arrowLabel;
@property (nonatomic, strong) UISwitch *autoPlaySwitch;
@property (nonatomic, strong) UISlider *delaySlider;
@property (nonatomic, strong) UILabel *delayLabel;
@property (nonatomic, strong) UISwitch *maiaSwitch;
@end

@implementation SettingsUI

+ (instancetype)shared {
    static SettingsUI *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [SettingsUI new]; [s load]; });
    return s;
}

- (void)load {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    _enabled = [d objectForKey:@"LA_Enabled"] ? [d boolForKey:@"LA_Enabled"] : YES;
    _elo = [d objectForKey:@"LA_Elo"] ? [d integerForKey:@"LA_Elo"] : 1200;
    _arrowCount = [d objectForKey:@"LA_Arrows"] ? [d integerForKey:@"LA_Arrows"] : 1;
    _autoPlay = [d boolForKey:@"LA_AutoPlay"];
    _autoPlayDelay = [d objectForKey:@"LA_Delay"] ? [d doubleForKey:@"LA_Delay"] : 0.5;
    _useMaia = [d boolForKey:@"LA_Maia"];
    _lastMoves = @[];
    _lastEval = 0;
}

- (void)save {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d setBool:_enabled forKey:@"LA_Enabled"];
    [d setInteger:_elo forKey:@"LA_Elo"];
    [d setInteger:_arrowCount forKey:@"LA_Arrows"];
    [d setBool:_autoPlay forKey:@"LA_AutoPlay"];
    [d setDouble:_autoPlayDelay forKey:@"LA_Delay"];
    [d setBool:_useMaia forKey:@"LA_Maia"];
    [d synchronize];
    if (self.onSettingsChanged) self.onSettingsChanged();
}

- (void)presentFrom:(UIViewController *)vc {
    UIViewController *sheet = [UIViewController new];
    sheet.view.backgroundColor = [UIColor systemBackgroundColor];
    sheet.modalPresentationStyle = UIModalPresentationPageSheet;

    UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:sheet.view.bounds];
    scroll.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [sheet.view addSubview:scroll];

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 16;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:scroll.topAnchor constant:20],
        [stack.leadingAnchor constraintEqualToAnchor:scroll.leadingAnchor constant:20],
        [stack.trailingAnchor constraintEqualToAnchor:scroll.trailingAnchor constant:-20],
        [stack.widthAnchor constraintEqualToAnchor:scroll.widthAnchor constant:-40],
    ]];

    UILabel *title = [UILabel new];
    title.text = @"Chess Assistant";
    title.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    [stack addArrangedSubview:title];

    // Enabled
    UIView *enRow = [self rowWithLabel:@"Enabled" control:self.enabledSwitch = [self makeSwitch:_enabled action:@selector(enabledChanged:)]];
    [stack addArrangedSubview:enRow];

    // ELO
    self.eloLabel = [UILabel new];
    self.eloLabel.text = [NSString stringWithFormat:@"Strength: %ld", (long)_elo];
    [stack addArrangedSubview:self.eloLabel];
    self.eloSlider = [self makeSlider:400 max:3500 value:_elo action:@selector(eloChanged:)];
    [stack addArrangedSubview:self.eloSlider];

    // Arrows
    self.arrowLabel = [UILabel new];
    self.arrowLabel.text = [NSString stringWithFormat:@"Arrows: %ld", (long)_arrowCount];
    [stack addArrangedSubview:self.arrowLabel];
    self.arrowSlider = [self makeSlider:1 max:3 value:_arrowCount action:@selector(arrowChanged:)];
    [stack addArrangedSubview:self.arrowSlider];

    // Auto-play
    UIView *apRow = [self rowWithLabel:@"Auto-play" control:self.autoPlaySwitch = [self makeSwitch:_autoPlay action:@selector(autoPlayChanged:)]];
    [stack addArrangedSubview:apRow];

    self.delayLabel = [UILabel new];
    self.delayLabel.text = [NSString stringWithFormat:@"Delay: %.1fs", _autoPlayDelay];
    [stack addArrangedSubview:self.delayLabel];
    self.delaySlider = [self makeSlider:0 max:5 value:_autoPlayDelay action:@selector(delayChanged:)];
    [stack addArrangedSubview:self.delaySlider];

    // Maia
    UIView *maiaRow = [self rowWithLabel:@"Use Maia (Lc0)" control:self.maiaSwitch = [self makeSwitch:_useMaia action:@selector(maiaChanged:)]];
    [stack addArrangedSubview:maiaRow];

    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    [close setTitle:@"Done" forState:UIControlStateNormal];
    close.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    [close addTarget:self action:@selector(close:) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:close];

    [vc presentViewController:sheet animated:YES completion:nil];
}

- (UISwitch *)makeSwitch:(BOOL)on action:(SEL)sel {
    UISwitch *s = [UISwitch new];
    s.on = on;
    [s addTarget:self action:sel forControlEvents:UIControlEventValueChanged];
    return s;
}

- (UISlider *)makeSlider:(float)min max:(float)max value:(float)v action:(SEL)sel {
    UISlider *s = [UISlider new];
    s.minimumValue = min;
    s.maximumValue = max;
    s.value = v;
    [s addTarget:self action:sel forControlEvents:UIControlEventValueChanged];
    return s;
}

- (UIView *)rowWithLabel:(NSString *)text control:(UIView *)ctrl {
    UILabel *l = [UILabel new];
    l.text = text;
    l.font = [UIFont systemFontOfSize:16];
    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[l, ctrl]];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.distribution = UIStackViewDistributionEqualSpacing;
    return row;
}

- (void)enabledChanged:(UISwitch *)s { _enabled = s.on; [self save]; }
- (void)eloChanged:(UISlider *)s { _elo = (NSInteger)s.value; self.eloLabel.text = [NSString stringWithFormat:@"Strength: %ld", (long)_elo]; [self save]; }
- (void)arrowChanged:(UISlider *)s { _arrowCount = (NSInteger)s.value; self.arrowLabel.text = [NSString stringWithFormat:@"Arrows: %ld", (long)_arrowCount]; [self save]; }
- (void)autoPlayChanged:(UISwitch *)s { _autoPlay = s.on; [self save]; }
- (void)delayChanged:(UISlider *)s { _autoPlayDelay = s.value; self.delayLabel.text = [NSString stringWithFormat:@"Delay: %.1fs", _autoPlayDelay]; [self save]; }
- (void)maiaChanged:(UISwitch *)s { _useMaia = s.on; [self save]; }
- (void)close:(id)sender { [[self topVC] dismissViewControllerAnimated:YES completion:nil]; }

- (UIViewController *)topVC {
    UIWindow *w = [UIApplication sharedApplication].windows.firstObject;
    UIViewController *vc = w.rootViewController;
    while (vc.presentedViewController) vc = vc.presentedViewController;
    return vc;
}

@end
