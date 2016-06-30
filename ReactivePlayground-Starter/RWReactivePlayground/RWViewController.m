//
//  RWViewController.m
//  RWReactivePlayground
//
//  Created by Colin Eberhardt on 18/12/2013.
//  Copyright (c) 2013 Colin Eberhardt. All rights reserved.
//

#import "RWViewController.h"
#import "RWDummySignInService.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface RWViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UILabel *signInFailureText;

@property (strong, nonatomic) RWDummySignInService *signInService;
    
@end

@implementation RWViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    self.signInService = [RWDummySignInService new];
    
    RACSignal *validUserNameSignal = [self.usernameTextField.rac_textSignal map:^id(id value) {
        return @([self isValidUsername:value]);
    }];
    
    RACSignal *validPasswordSignal = [self.passwordTextField.rac_textSignal map:^id(id value) {
        return @([self isValidPassword:value]);
    }];
    
    id (^validColorBlock)(NSNumber *boolValid) = ^id(NSNumber *boolValid) {
        return [boolValid boolValue] ? [UIColor clearColor] : [ UIColor yellowColor];
    };
    RAC(self.usernameTextField, backgroundColor) = [validUserNameSignal map:validColorBlock];
    RAC(self.passwordTextField, backgroundColor) = [validPasswordSignal map:validColorBlock];

    
    RACSignal *signInActiveSignal = [RACSignal combineLatest:@[validUserNameSignal, validPasswordSignal] reduce:^id(NSNumber *usernameValid, NSNumber *passwordValid) {
        return @([usernameValid boolValue] && [passwordValid boolValue]);
    }];
    
    [signInActiveSignal subscribeNext:^(NSNumber *active) {
        self.signInButton.enabled = [active boolValue];
    }];
    
    // initially hide the failure message
    self.signInFailureText.hidden = YES;
    
    [[[[self.signInButton rac_signalForControlEvents:UIControlEventTouchUpInside] doNext:^(id x) {
        
        self.signInButton.enabled = NO;
        self.signInFailureText.hidden = YES;
        
    }] flattenMap:^id(id value) {
        return [self signInSignal];
    }] subscribeNext:^(NSNumber *successValue) {
        BOOL success = [successValue boolValue];
        self.signInButton.enabled = YES;
        self.signInFailureText.hidden = success;
        if (success)
        {
            [self performSegueWithIdentifier:@"signInSuccess" sender:self];
        }
    }];
}

- (BOOL)isValidUsername:(NSString *)username {
    return username.length > 3;
}

- (BOOL)isValidPassword:(NSString *)password {
    return password.length > 3;
}

- (RACSignal *)signInSignal
{
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [self.signInService signInWithUsername:self.usernameTextField.text
                                      password:self.passwordTextField.text
                                      complete:^(BOOL success) {
                                          [subscriber sendNext:@(success)];
                                          [subscriber sendCompleted];
                                      }];
        return nil;
    }];
}

@end
