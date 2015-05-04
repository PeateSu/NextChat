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

#import "TableViewController.h"
#import "LeanMessageManager.h"

@implementation TableViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"JSQMessagesViewController";
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 2) {
        return 1;
    }
    
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"Jobs 发起和 Cook 的聊天";
                break;
            case 1:
                cell.textLabel.text = @"Cook 发起和 Jobs 的聊天";
                break;
        }
    }
    else if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"Jobs 发起和 Cook、Woz 的聊天";
                break;
            case 1:
                cell.textLabel.text = @"Cook 发起和 Woz、Jobs 的聊天";
        }
    }
    else if (indexPath.section == 2) {
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"设置";
                break;
        }
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return @"单聊";
        case 2:
            return @"群聊";
        default:
            return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return (section == [tableView numberOfSections] - 1) ? @"Copyright © 2014\nJesse Squires\nMIT License" : nil;
}

#pragma mark - Table view delegate

- (void)openSessionByClientId:(NSString*)clientId navigationToIMWithTargetClientIDs:(NSArray *)clientIDs {
    WEAKSELF
    [[LeanMessageManager manager] openSessionWithClientID:clientId completion:^(BOOL succeeded, NSError *error) {
        if(!error){
            ConversationType type;
            if(clientIDs.count>1){
                type=ConversationTypeGroup;
            }else{
                type=ConversationTypeOneToOne;
            }
            [[LeanMessageManager manager] createConversationsWithClientIDs:clientIDs conversationType:type completion:^(AVIMConversation *conversation, NSError *error) {
                if(error){
                    NSLog(@"error=%@",error);
                }else{
                    DemoMessagesViewController *vc = [DemoMessagesViewController messagesViewController];
                    vc.conversation=conversation;
                    [self.navigationController pushViewController:vc animated:YES];
                }
            }];
        }else{
            NSLog(@"error=%@",error);
        }
    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:
                [self openSessionByClientId:kJobsClientID navigationToIMWithTargetClientIDs:@[kCookClientID]];
                break;
            case 1:
                [self openSessionByClientId:kCookClientID navigationToIMWithTargetClientIDs:@[kJobsClientID]];
                break;
        }
    }
    else if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0:
                [self openSessionByClientId:kJobsClientID navigationToIMWithTargetClientIDs:@[kCookClientID,kWozClientID]];
                break;
            case 1:
                [self openSessionByClientId:kCookClientID navigationToIMWithTargetClientIDs:@[kJobsClientID,kWozClientID]];
                break;
        }
    }
    else if (indexPath.section == 2) {
        switch (indexPath.row) {
            case 0:
                [self performSegueWithIdentifier:@"SegueToSettings" sender:self];
                break;
        }
    }
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
}

- (IBAction)unwindSegue:(UIStoryboardSegue *)sender { }


@end
