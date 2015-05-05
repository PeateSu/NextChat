//
//  Created by Jesse Squires
//  http://www.jessesquires.com
//
//
//  Documentation
//  http://cocoadocs.org/docsets/JSQMessagesViewController
//
//
//  GitHub
//  https://github.com/jessesquires/JSQMessagesViewController
//
//
//  License
//  Copyright (c) 2014 Jesse Squires
//  Released under an MIT license: http://opensource.org/licenses/MIT
//


// Import all the things
#import "JSQMessages.h"

#import "NSUserDefaults+DemoSettings.h"
#import "LeanMessageManager.h"


@class DemoMessagesViewController;

@interface DemoMessagesViewController : JSQMessagesViewController <UIActionSheetDelegate>

@property (nonatomic,strong) AVIMConversation *conversation;

@end
