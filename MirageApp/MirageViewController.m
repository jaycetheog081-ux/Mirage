#import "MirageViewController.h"
#import "MirageCore.h"

@interface MirageViewController () <UITextFieldDelegate>
@property (nonatomic, strong) UITextView *outputView;
@property (nonatomic, strong) UITextField *commandField;
@property (nonatomic, copy) NSString *guestRoot;
@end

@implementation MirageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.055 green:0.065 blue:0.085 alpha:1.0];
    self.guestRoot = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject
                      stringByAppendingPathComponent:@"MirageRoot"];

    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:self.guestRoot
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];
    if (error) {
        NSLog(@"Mirage root creation error: %@", error);
    }
    MirageCoreInitialize(self.guestRoot.UTF8String);

    UILabel *title = [[UILabel alloc] init];
    title.text = @"MIRAGE";
    title.font = [UIFont systemFontOfSize:26 weight:UIFontWeightBold];
    title.textColor = [UIColor colorWithRed:0.55 green:0.82 blue:1.0 alpha:1.0];
    title.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *subtitle = [[UILabel alloc] init];
    subtitle.text = @"iOS 18.5 userspace research • v0.1";
    subtitle.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    subtitle.textColor = [UIColor secondaryLabelColor];
    subtitle.translatesAutoresizingMaskIntoConstraints = NO;

    self.outputView = [[UITextView alloc] init];
    self.outputView.translatesAutoresizingMaskIntoConstraints = NO;
    self.outputView.editable = NO;
    self.outputView.selectable = YES;
    self.outputView.backgroundColor = [UIColor colorWithRed:0.025 green:0.03 blue:0.04 alpha:1.0];
    self.outputView.textColor = [UIColor colorWithRed:0.78 green:0.9 blue:0.78 alpha:1.0];
    self.outputView.font = [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightRegular];
    self.outputView.layer.cornerRadius = 12;
    self.outputView.textContainerInset = UIEdgeInsetsMake(12, 10, 12, 10);

    self.commandField = [[UITextField alloc] init];
    self.commandField.translatesAutoresizingMaskIntoConstraints = NO;
    self.commandField.placeholder = @"Enter a Mirage command…";
    self.commandField.textColor = UIColor.labelColor;
    self.commandField.tintColor = [UIColor colorWithRed:0.55 green:0.82 blue:1.0 alpha:1.0];
    self.commandField.backgroundColor = [UIColor secondarySystemBackgroundColor];
    self.commandField.borderStyle = UITextBorderStyleRoundedRect;
    self.commandField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.commandField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.commandField.returnKeyType = UIReturnKeySend;
    self.commandField.delegate = self;

    UIButton *runButton = [UIButton buttonWithType:UIButtonTypeSystem];
    runButton.translatesAutoresizingMaskIntoConstraints = NO;
    [runButton setTitle:@"Run" forState:UIControlStateNormal];
    runButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [runButton addTarget:self action:@selector(runCommand) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *inputRow = [[UIStackView alloc] initWithArrangedSubviews:@[self.commandField, runButton]];
    inputRow.translatesAutoresizingMaskIntoConstraints = NO;
    inputRow.axis = UILayoutConstraintAxisHorizontal;
    inputRow.spacing = 8;
    [self.commandField setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [runButton setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    [self.view addSubview:title];
    [self.view addSubview:subtitle];
    [self.view addSubview:self.outputView];
    [self.view addSubview:inputRow];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [title.topAnchor constraintEqualToAnchor:safe.topAnchor constant:14],
        [title.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:18],
        [subtitle.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:2],
        [subtitle.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [self.outputView.topAnchor constraintEqualToAnchor:subtitle.bottomAnchor constant:16],
        [self.outputView.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:14],
        [self.outputView.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-14],
        [self.outputView.bottomAnchor constraintEqualToAnchor:inputRow.topAnchor constant:-12],
        [inputRow.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:14],
        [inputRow.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-14],
        [inputRow.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-14],
        [inputRow.heightAnchor constraintEqualToConstant:46]
    ]];

    [self appendOutput:@"Mirage Core v0.1 initialized.\n"];
    [self appendOutput:[NSString stringWithFormat:@"Guest root: %@\n", self.guestRoot]];
    [self appendOutput:@"This is a command-layer prototype, not a full iOS VM.\n"];
    [self appendOutput:@"Type 'help' to list built-in commands.\n\n"];
    [self runGuestCommand:@"help"];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self runCommand];
    return YES;
}

- (void)runCommand {
    NSString *command = [self.commandField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (command.length == 0) return;
    [self appendOutput:[NSString stringWithFormat:@"mirage$ %@\n", command]];
    self.commandField.text = @"";
    [self runGuestCommand:command];
    [self.commandField resignFirstResponder];
}

- (void)runGuestCommand:(NSString *)command {
    char output[16384] = {0};
    int result = MirageCoreExecute(command.UTF8String, output, sizeof(output));
    NSString *text = [NSString stringWithUTF8String:output] ?: @"[Output decoding error]\n";
    [self appendOutput:text];
    if (result != 0 && text.length == 0) [self appendOutput:@"Command failed.\n"];
}

- (void)appendOutput:(NSString *)text {
    self.outputView.text = [self.outputView.text stringByAppendingString:text];
    if (self.outputView.text.length > 24000) {
        self.outputView.text = [self.outputView.text substringFromIndex:self.outputView.text.length - 18000];
    }
    NSRange end = NSMakeRange(self.outputView.text.length, 0);
    [self.outputView scrollRangeToVisible:end];
}

@end
