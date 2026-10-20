#import "MirageViewController.h"
#import "MirageCore.h"
#import <QuartzCore/QuartzCore.h>

@interface MirageViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UITextView *outputView;
@property (nonatomic, strong) UITextField *commandField;
@property (nonatomic, strong) UIButton *runButton;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIView *inputContainer;
@property (nonatomic, strong) NSString *guestRoot;
@property (nonatomic, strong) NSLayoutConstraint *inputBottomConstraint;

@end

@implementation MirageViewController

#pragma mark - Full Screen

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationFade;
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return YES;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithRed:0.025
                                                green:0.03
                                                 blue:0.045
                                                alpha:1.0];

    self.guestRoot = [[NSSearchPathForDirectoriesInDomains(
        NSDocumentDirectory,
        NSUserDomainMask,
        YES
    ) firstObject] stringByAppendingPathComponent:@"MirageRoot"];

    NSError *error = nil;

    [[NSFileManager defaultManager]
        createDirectoryAtPath:self.guestRoot
        withIntermediateDirectories:YES
        attributes:nil
        error:&error];

    if (error) {
        NSLog(@"Mirage root creation error: %@", error);
    }

    MirageCoreInitialize(self.guestRoot.UTF8String);

    [self buildInterface];
    [self configureKeyboardHandling];
    [self initializeTerminal];
}

#pragma mark - Interface

- (void)buildInterface {
    UIColor *backgroundColor =
        [UIColor colorWithRed:0.035
                        green:0.045
                         blue:0.065
                        alpha:1.0];

    UIColor *terminalColor =
        [UIColor colorWithRed:0.008
                        green:0.012
                         blue:0.018
                        alpha:1.0];

    UIColor *accentColor =
        [UIColor colorWithRed:0.35
                        green:0.72
                         blue:1.0
                        alpha:1.0];

    UIColor *terminalTextColor =
        [UIColor colorWithRed:0.76
                        green:0.91
                         blue:0.78
                        alpha:1.0];

    /*
     Full-screen root view.

     All primary layout constraints attach to self.view rather than
     safeAreaLayoutGuide so the interface can extend to the screen edges.
     */

    self.view.backgroundColor = backgroundColor;

    // MARK: Header

    self.headerView = [[UIView alloc] init];
    self.headerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.headerView.backgroundColor = UIColor.clearColor;

    [self.view addSubview:self.headerView];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.text = @"MIRAGE";
    self.titleLabel.font =
        [UIFont systemFontOfSize:32 weight:UIFontWeightHeavy];
    self.titleLabel.textColor = accentColor;
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleLabel.minimumScaleFactor = 0.75;

    [self.headerView addSubview:self.titleLabel];

    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.subtitleLabel.text = @"iOS 18.5 USERSPACE RESEARCH  •  v0.2";
    self.subtitleLabel.font =
        [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    self.subtitleLabel.textColor =
        [UIColor colorWithWhite:0.58 alpha:1.0];
    self.subtitleLabel.numberOfLines = 1;
    self.subtitleLabel.adjustsFontSizeToFitWidth = YES;
    self.subtitleLabel.minimumScaleFactor = 0.7;

    [self.headerView addSubview:self.subtitleLabel];

    // MARK: Terminal

    self.outputView = [[UITextView alloc] init];
    self.outputView.translatesAutoresizingMaskIntoConstraints = NO;

    self.outputView.editable = NO;
    self.outputView.selectable = YES;
    self.outputView.scrollEnabled = YES;
    self.outputView.alwaysBounceVertical = YES;
    self.outputView.showsVerticalScrollIndicator = YES;
    self.outputView.showsHorizontalScrollIndicator = NO;

    self.outputView.backgroundColor = terminalColor;
    self.outputView.textColor = terminalTextColor;

    self.outputView.font =
        [UIFont monospacedSystemFontOfSize:13
                                    weight:UIFontWeightRegular];

    self.outputView.textContainerInset = UIEdgeInsetsMake(16, 12, 18, 12);
    self.outputView.textContainer.lineFragmentPadding = 0;
    self.outputView.textContainer.widthTracksTextView = YES;

    self.outputView.layer.cornerRadius = 14;
    self.outputView.layer.cornerCurve = kCACornerCurveContinuous;
    self.outputView.layer.borderWidth = 1.0 / UIScreen.mainScreen.scale;
    self.outputView.layer.borderColor =
        [UIColor colorWithWhite:1.0 alpha:0.07].CGColor;

    self.outputView.clipsToBounds = YES;

    [self.view addSubview:self.outputView];

    // MARK: Command Input

    self.inputContainer = [[UIView alloc] init];
    self.inputContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.inputContainer.backgroundColor = UIColor.clearColor;

    [self.view addSubview:self.inputContainer];

    self.commandField = [[UITextField alloc] init];
    self.commandField.translatesAutoresizingMaskIntoConstraints = NO;

    self.commandField.placeholder = @"Enter a Mirage command...";
    self.commandField.textColor = UIColor.labelColor;
    self.commandField.tintColor = accentColor;
    self.commandField.backgroundColor =
        [UIColor colorWithRed:0.09
                        green:0.10
                         blue:0.13
                        alpha:1.0];

    self.commandField.borderStyle = UITextBorderStyleNone;
    self.commandField.layer.cornerRadius = 12;
    self.commandField.layer.cornerCurve = kCACornerCurveContinuous;
    self.commandField.clipsToBounds = YES;

    self.commandField.font =
        [UIFont monospacedSystemFontOfSize:14
                                    weight:UIFontWeightRegular];

    self.commandField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.commandField.autocapitalizationType =
        UITextAutocapitalizationTypeNone;
    self.commandField.spellCheckingType = UITextSpellCheckingTypeNo;
    self.commandField.smartQuotesType = UITextSmartQuotesTypeNo;
    self.commandField.smartDashesType = UITextSmartDashesTypeNo;
    self.commandField.smartInsertDeleteType =
        UITextSmartInsertDeleteTypeNo;

    self.commandField.returnKeyType = UIReturnKeySend;
    self.commandField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.commandField.delegate = self;

    // Give the text some breathing room inside the rounded input.
    UIView *leftPadding = [[UIView alloc] initWithFrame:
                           CGRectMake(0, 0, 14, 1)];

    self.commandField.leftView = leftPadding;
    self.commandField.leftViewMode = UITextFieldViewModeAlways;

    [self.inputContainer addSubview:self.commandField];

    self.runButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.runButton.translatesAutoresizingMaskIntoConstraints = NO;

    [self.runButton setTitle:@"Run" forState:UIControlStateNormal];
    [self.runButton setTitleColor:accentColor
                         forState:UIControlStateNormal];

    self.runButton.titleLabel.font =
        [UIFont systemFontOfSize:17 weight:UIFontWeightBold];

    self.runButton.accessibilityLabel = @"Run Mirage command";

    [self.runButton addTarget:self
                       action:@selector(runCommand)
             forControlEvents:UIControlEventTouchUpInside];

    [self.inputContainer addSubview:self.runButton];

    // MARK: Constraints

    UILayoutGuide *keyboardGuide = self.view.keyboardLayoutGuide;

    self.inputBottomConstraint =
        [self.inputContainer.bottomAnchor
            constraintEqualToAnchor:keyboardGuide.topAnchor
            constant:-12];

    [NSLayoutConstraint activateConstraints:@[
        // Header spans the available width.
        [self.headerView.topAnchor
            constraintEqualToAnchor:self.view.topAnchor
            constant:24],

        [self.headerView.leadingAnchor
            constraintEqualToAnchor:self.view.leadingAnchor
            constant:20],

        [self.headerView.trailingAnchor
            constraintEqualToAnchor:self.view.trailingAnchor
            constant:-20],

        [self.headerView.heightAnchor
            constraintGreaterThanOrEqualToConstant:65],

        // Title.
        [self.titleLabel.topAnchor
            constraintEqualToAnchor:self.headerView.topAnchor],

        [self.titleLabel.leadingAnchor
            constraintEqualToAnchor:self.headerView.leadingAnchor],

        [self.titleLabel.trailingAnchor
            constraintLessThanOrEqualToAnchor:self.headerView.trailingAnchor],

        // Subtitle.
        [self.subtitleLabel.topAnchor
            constraintEqualToAnchor:self.titleLabel.bottomAnchor
            constant:2],

        [self.subtitleLabel.leadingAnchor
            constraintEqualToAnchor:self.headerView.leadingAnchor],

        [self.subtitleLabel.trailingAnchor
            constraintEqualToAnchor:self.headerView.trailingAnchor],

        [self.subtitleLabel.bottomAnchor
            constraintEqualToAnchor:self.headerView.bottomAnchor],

        // Terminal fills the space between header and input.
        [self.outputView.topAnchor
            constraintEqualToAnchor:self.headerView.bottomAnchor
            constant:16],

        [self.outputView.leadingAnchor
            constraintEqualToAnchor:self.view.leadingAnchor
            constant:14],

        [self.outputView.trailingAnchor
            constraintEqualToAnchor:self.view.trailingAnchor
            constant:-14],

        [self.outputView.bottomAnchor
            constraintEqualToAnchor:self.inputContainer.topAnchor
            constant:-12],

        // Input row.
        [self.inputContainer.leadingAnchor
            constraintEqualToAnchor:self.view.leadingAnchor
            constant:14],

        [self.inputContainer.trailingAnchor
            constraintEqualToAnchor:self.view.trailingAnchor
            constant:-14],

        [self.inputContainer.heightAnchor
            constraintEqualToConstant:54],

        [self.commandField.leadingAnchor
            constraintEqualToAnchor:self.inputContainer.leadingAnchor],

        [self.commandField.topAnchor
            constraintEqualToAnchor:self.inputContainer.topAnchor],

        [self.commandField.bottomAnchor
            constraintEqualToAnchor:self.inputContainer.bottomAnchor],

        [self.runButton.leadingAnchor
            constraintEqualToAnchor:self.commandField.trailingAnchor
            constant:10],

        [self.runButton.trailingAnchor
            constraintEqualToAnchor:self.inputContainer.trailingAnchor],

        [self.runButton.centerYAnchor
            constraintEqualToAnchor:self.commandField.centerYAnchor],

        [self.runButton.widthAnchor
            constraintGreaterThanOrEqualToConstant:48],

        [self.runButton.heightAnchor
            constraintGreaterThanOrEqualToConstant:44],

        [self.commandField.widthAnchor
            constraintGreaterThanOrEqualToConstant:100],

        self.inputBottomConstraint
    ]];

    /*
     Keep the header and input compact in landscape orientation.
     The terminal automatically expands or contracts between them.
     */
    [self.view setNeedsLayout];
}

#pragma mark - Keyboard

- (void)configureKeyboardHandling {
    /*
     The input container is constrained to keyboardLayoutGuide.topAnchor.
     UIKit moves it above the software keyboard automatically.
     */
    self.view.keyboardLayoutGuide.followsUndockedKeyboard = NO;
}

#pragma mark - Terminal Initialization

- (void)initializeTerminal {
    [self appendOutput:@"MIRAGE USERSpace ENVIRONMENT\n"];
    [self appendOutput:@"--------------------------------\n\n"];

    [self appendOutput:@"Mirage Core v0.2 initialized.\n"];
    [self appendOutput:
        [NSString stringWithFormat:@"Guest root: %@\n", self.guestRoot]];

    [self appendOutput:
        @"Environment: iOS application sandbox\n"];

    [self appendOutput:
        @"Execution mode: built-in command interpreter\n"];

    [self appendOutput:
        @"Note: Mirage is a userspace prototype, not a full iOS VM.\n\n"];

    [self runGuestCommand:@"help"];
}

#pragma mark - Command Execution

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self runCommand];
    return YES;
}

- (void)runCommand {
    NSString *command =
        [self.commandField.text
            stringByTrimmingCharactersInSet:
                [NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (command.length == 0) {
        return;
    }

    [self appendOutput:
        [NSString stringWithFormat:@"\nmirage$ %@\n", command]];

    self.commandField.text = @"";

    [self runGuestCommand:command];

    [self.commandField resignFirstResponder];
}

- (void)runGuestCommand:(NSString *)command {
    char output[16384] = {0};

    int result = MirageCoreExecute(
        command.UTF8String,
        output,
        sizeof(output)
    );

    NSString *text =
        [NSString stringWithUTF8String:output];

    if (text == nil) {
        text = @"[Output decoding error]\n";
    }

    if (text.length > 0) {
        [self appendOutput:text];

        if (![text hasSuffix:@"\n"]) {
            [self appendOutput:@"\n"];
        }
    } else if (result != 0) {
        [self appendOutput:@"Command failed.\n"];
    }
}

#pragma mark - Terminal Output

- (void)appendOutput:(NSString *)text {
    if (text.length == 0) {
        return;
    }

    NSString *currentText = self.outputView.text ?: @"";

    NSString *updatedText =
        [currentText stringByAppendingString:text];

    // Keep the output buffer bounded during long sessions.
    const NSUInteger maximumLength = 30000;
    const NSUInteger retainedLength = 22000;

    if (updatedText.length > maximumLength) {
        NSUInteger startIndex = updatedText.length - retainedLength;

        // Avoid starting the retained output in the middle of a line.
        NSRange searchRange =
            NSMakeRange(startIndex,
                        updatedText.length - startIndex);

        NSRange newlineRange =
            [updatedText rangeOfString:@"\n"
                               options:0
                                 range:searchRange];

        if (newlineRange.location != NSNotFound) {
            startIndex = NSMaxRange(newlineRange);
        }

        updatedText =
            [updatedText substringFromIndex:startIndex];
    }

    self.outputView.text = updatedText;

    // Scroll to the most recent output.
    if (updatedText.length > 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.outputView.text.length == 0) {
                return;
            }

            NSRange end =
                NSMakeRange(self.outputView.text.length - 1, 1);

            [self.outputView scrollRangeToVisible:end];
        });
    }
}

@end
