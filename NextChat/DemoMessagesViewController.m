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

#import "DemoMessagesViewController.h"
#import "XHPhotographyHelper.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "XHDisplayMediaViewController.h"

@interface DemoMessagesViewController ()

@property (nonatomic,strong) XHPhotographyHelper *photographyHelper;

@property (nonatomic, strong) NSMutableArray *displayMessages;

@property (strong, nonatomic) JSQMessagesBubbleImage *outgoingBubbleImageData;

@property (strong, nonatomic) JSQMessagesBubbleImage *incomingBubbleImageData;

@end

@implementation DemoMessagesViewController

#pragma mark - user info
/**
 * 配置头像
 */
- (JSQMessagesAvatarImage*)avatarByClientId:(NSString*)clientId{
    
//    JSQMessagesAvatarImage *jsqImage = [JSQMessagesAvatarImageFactory avatarImageWithUserInitials:@"JSQ" backgroundColor:[UIColor colorWithWhite:0.85f alpha:1.0f] textColor:[UIColor colorWithWhite:0.60f alpha:1.0f] font:[UIFont systemFontOfSize:14.0f] diameter:kJSQMessagesCollectionViewAvatarSizeDefault];
    
    NSDictionary *imageNames=@{kCookClientID:@"demo_avatar_cook",
                               kJobsClientID:@"demo_avatar_jobs",
                               kWozClientID:@"demo_avatar_woz"};
    NSString *imageName=imageNames[clientId];
    JSQMessagesAvatarImage *avatar = [JSQMessagesAvatarImageFactory avatarImageWithImage:[UIImage imageNamed:imageName] diameter:kJSQMessagesCollectionViewAvatarSizeDefault];
    return avatar;
}

/**
 * 配置用户名
 */
- (NSString*)displayNameByClientId:(NSString*)clientId{
    return clientId;
}

#pragma mark - View lifecycle
/**
 *  Override point for customization.
 *
 *  Customize your view.
 *  Look at the properties on `JSQMessagesViewController` and `JSQMessagesCollectionView` to see what is possible.
 *
 *  Customize your layout.
 *  Look at the properties on `JSQMessagesCollectionViewFlowLayout` to see what is possible.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Chat";
    /**
     *  You MUST set your senderId and display name
     */
    self.senderId = [[LeanMessageManager manager] selfClientID];
    self.senderDisplayName = [self displayNameByClientId:self.senderId];
    /**
     *  You can set custom avatar sizes
     */
    if (![NSUserDefaults incomingAvatarSetting]) {
        self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    }
    
    if (![NSUserDefaults outgoingAvatarSetting]) {
        self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    }
    
    self.showLoadEarlierMessagesHeader = YES;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage jsq_defaultTypingIndicatorImage] style:UIBarButtonItemStylePlain target:self action:@selector(receiveMessagePressed:)];
    
    /**
     *  Customize your toolbar buttons
     *
     *  self.inputToolbar.contentView.leftBarButtonItem = custom button or nil to remove
     *  self.inputToolbar.contentView.rightBarButtonItem = custom button or nil to remove
     */
    
    JSQMessagesBubbleImageFactory *bubbleFactory= [[JSQMessagesBubbleImageFactory alloc] init];
    
    self.outgoingBubbleImageData=[bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
    self.incomingBubbleImageData=[bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];
    
    [self loadMessagesWhenInit];
    
    [self setupReceiveMessageBlock];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    /**
     *  Enable/disable springy bubbles, default is NO.
     *  You must set this from `viewDidAppear:`
     *  Note: this feature is mostly stable, but still experimental
     */
    self.collectionView.collectionViewLayout.springinessEnabled = [NSUserDefaults springinessSetting];
}



#pragma mark - Testing

- (void)pushMainViewController
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *nc = [sb instantiateInitialViewController];
    [self.navigationController pushViewController:nc.topViewController animated:YES];
}


#pragma mark - Actions

- (void)receiveMessagePressed:(UIBarButtonItem *)sender
{
    /**
     *  DEMO ONLY
     *
     *  The following is simply to simulate received messages for the demo.
     *  Do not actually do this.
     */
    
    
    /**
     *  Show the typing indicator to be shown
     */
    self.showTypingIndicator = !self.showTypingIndicator;
    
    

    /**
     *  Scroll to actually view the indicator
     */
    [self scrollToBottomAnimated:YES];
    
    /**
     *  Copy last sent message, this will be the new "received" message
     */
    JSQMessage *copyMessage = [[self.displayMessages lastObject] copy];
    
    if (!copyMessage) {
        copyMessage = [JSQMessage messageWithSenderId:kJobsClientID
                                          displayName:[self displayNameByClientId:kJobsClientID]
                                                 text:@"First received!"];
    }
    
    /**
     *  Allow typing indicator to show
     */
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSMutableArray *userIds = [@[kJobsClientID,kWozClientID,kCookClientID]mutableCopy];
        [userIds removeObject:self.senderId] ;
        NSString *randomUserId = userIds[arc4random_uniform((int)[userIds count])];
        
        JSQMessage *newMessage = nil;
        id<JSQMessageMediaData> newMediaData = nil;
        id newMediaAttachmentCopy = nil;
        
        if (copyMessage.isMediaMessage) {
            /**
             *  Last message was a media message
             */
            id<JSQMessageMediaData> copyMediaData = copyMessage.media;
            
            if ([copyMediaData isKindOfClass:[JSQPhotoMediaItem class]]) {
                JSQPhotoMediaItem *photoItemCopy = [((JSQPhotoMediaItem *)copyMediaData) copy];
                photoItemCopy.appliesMediaViewMaskAsOutgoing = NO;
                newMediaAttachmentCopy = [UIImage imageWithCGImage:photoItemCopy.image.CGImage];
                
                /**
                 *  Set image to nil to simulate "downloading" the image
                 *  and show the placeholder view
                 */
                photoItemCopy.image = nil;
                
                newMediaData = photoItemCopy;
            }
            else if ([copyMediaData isKindOfClass:[JSQLocationMediaItem class]]) {
                JSQLocationMediaItem *locationItemCopy = [((JSQLocationMediaItem *)copyMediaData) copy];
                locationItemCopy.appliesMediaViewMaskAsOutgoing = NO;
                newMediaAttachmentCopy = [locationItemCopy.location copy];
                
                /**
                 *  Set location to nil to simulate "downloading" the location data
                 */
                locationItemCopy.location = nil;
                
                newMediaData = locationItemCopy;
            }
            else if ([copyMediaData isKindOfClass:[JSQVideoMediaItem class]]) {
                JSQVideoMediaItem *videoItemCopy = [((JSQVideoMediaItem *)copyMediaData) copy];
                videoItemCopy.appliesMediaViewMaskAsOutgoing = NO;
                newMediaAttachmentCopy = [videoItemCopy.fileURL copy];
                
                /**
                 *  Reset video item to simulate "downloading" the video
                 */
                videoItemCopy.fileURL = nil;
                videoItemCopy.isReadyToPlay = NO;
                
                newMediaData = videoItemCopy;
            }
            else {
                NSLog(@"%s error: unrecognized media item", __PRETTY_FUNCTION__);
            }
            
            newMessage = [JSQMessage messageWithSenderId:randomUserId
                                             displayName:[self displayNameByClientId:randomUserId]
                                                   media:newMediaData];
        }
        else {
            /**
             *  Last message was a text message
             */
            newMessage = [JSQMessage messageWithSenderId:randomUserId
                                             displayName:[self displayNameByClientId:randomUserId]
                                                    text:copyMessage.text];
        }
        
        /**
         *  Upon receiving a message, you should:
         *
         *  1. Play sound (optional)
         *  2. Add new id<JSQMessageData> object to your data source
         *  3. Call `finishReceivingMessage`
         */
        [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
        [self.displayMessages addObject:newMessage];
        [self finishReceivingMessageAnimated:YES];
        
        
        if (newMessage.isMediaMessage) {
            /**
             *  Simulate "downloading" media
             */
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                /**
                 *  Media is "finished downloading", re-display visible cells
                 *
                 *  If media cell is not visible, the next time it is dequeued the view controller will display its new attachment data
                 *
                 *  Reload the specific item, or simply call `reloadData`
                 */
                
                if ([newMediaData isKindOfClass:[JSQPhotoMediaItem class]]) {
                    ((JSQPhotoMediaItem *)newMediaData).image = newMediaAttachmentCopy;
                    [self.collectionView reloadData];
                }
                else if ([newMediaData isKindOfClass:[JSQLocationMediaItem class]]) {
                    [((JSQLocationMediaItem *)newMediaData)setLocation:newMediaAttachmentCopy withCompletionHandler:^{
                        [self.collectionView reloadData];
                    }];
                }
                else if ([newMediaData isKindOfClass:[JSQVideoMediaItem class]]) {
                    ((JSQVideoMediaItem *)newMediaData).fileURL = newMediaAttachmentCopy;
                    ((JSQVideoMediaItem *)newMediaData).isReadyToPlay = YES;
                    [self.collectionView reloadData];
                }
                else {
                    NSLog(@"%s error: unrecognized media item", __PRETTY_FUNCTION__);
                }
                
            });
        }
        
    });
}


#pragma mark - JSQMessagesViewController method overrides

- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date
{
    /**
     *  Sending a message. Your implementation of this method should do *at least* the following:
     *
     *  1. Play sound (optional)
     *  2. Add new id<JSQMessageData> object to your data source
     *  3. Call `finishSendingMessage`
     */
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    
    AVIMTextMessage *message=[AVIMTextMessage messageWithText:text attributes:nil];
    [self sendMessage:message];
}

- (void)didPressAccessoryButton:(UIButton *)sender
{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Media messages"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"Send photo", @"Send location", @"Send video", nil];
    
    [sheet showFromToolbar:self.inputToolbar];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
    
    WEAKSELF
    void (^PickerMediaBlock)(UIImage *image, NSDictionary *editingInfo) = ^(UIImage *image, NSDictionary *editingInfo) {
        if (image) {
            [weakSelf didSendMessageWithPhoto:image];
        } else {
            if (!editingInfo)
                return ;
            NSString *mediaType = [editingInfo objectForKey: UIImagePickerControllerMediaType];
            NSString *videoPath;
            NSURL *videoUrl;
            if (CFStringCompare ((__bridge CFStringRef) mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
                videoUrl = (NSURL*)[editingInfo objectForKey:UIImagePickerControllerMediaURL];
                videoPath = [videoUrl path];
                [weakSelf didSendMessageWithVideoPath:videoPath];
            } else {
                [weakSelf didSendMessageWithPhoto:[editingInfo valueForKey:UIImagePickerControllerOriginalImage]];
            }
        }
    };
    
    switch (buttonIndex) {
        case 0:
            [self.photographyHelper showOnPickerViewControllerSourceType:UIImagePickerControllerSourceTypePhotoLibrary onViewController:self compled:PickerMediaBlock];
            break;
        case 1:{
            [self didSendMessageWithLatitude:0 longitude:0];
        }break;
            
        case 2:
            [self.photographyHelper showOnPickerViewControllerSourceType:UIImagePickerControllerSourceTypeCamera onViewController:self compled:PickerMediaBlock];
            break;
    }
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    [self finishSendingMessageAnimated:YES];
}



#pragma mark - JSQMessages CollectionView DataSource

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.displayMessages objectAtIndex:indexPath.item];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  You may return nil here if you do not want bubbles.
     *  In this case, you should set the background color of your collection view cell's textView.
     *
     *  Otherwise, return your previously created bubble image data objects.
     */
    
    JSQMessage *message = [self.displayMessages objectAtIndex:indexPath.item];
    if ([message.senderId isEqualToString:self.senderId]) {
        return self.outgoingBubbleImageData;;
    }else{
        return self.incomingBubbleImageData;
    }
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Return `nil` here if you do not want avatars.
     *  If you do return `nil`, be sure to do the following in `viewDidLoad`:
     *
     *  self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
     *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
     *
     *  It is possible to have only outgoing avatars or only incoming avatars, too.
     */
    
    /**
     *  Return your previously created avatar image data objects.
     *
     *  Note: these the avatars will be sized according to these values:
     *
     *  self.collectionView.collectionViewLayout.incomingAvatarViewSize
     *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize
     *
     *  Override the defaults in `viewDidLoad`
     */
    
    JSQMessage *message=self.displayMessages[indexPath.row];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        if (![NSUserDefaults outgoingAvatarSetting]) {
            return nil;
        }
    }
    else {
        if (![NSUserDefaults incomingAvatarSetting]) {
            return nil;
        }
    }
    
    return [self avatarByClientId:message.senderId];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
     *  The other label text delegate methods should follow a similar pattern.
     *
     *  Show a timestamp for every 3rd message
     */
    if (indexPath.item % 3 == 0) {
        JSQMessage *message = [self.displayMessages objectAtIndex:indexPath.item];
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *message = [self.displayMessages objectAtIndex:indexPath.item];
    
    /**
     *  iOS7-style sender name labels
     */
    if ([message.senderId isEqualToString:self.senderId]) {
        return nil;
    }
    
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [self.displayMessages objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:message.senderId]) {
            return nil;
        }
    }
    
    /**
     *  Don't specify attributes to use the defaults.
     */
    return [[NSAttributedString alloc] initWithString:message.senderDisplayName];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.displayMessages count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Override point for customizing cells
     */
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    /**
     *  Configure almost *anything* on the cell
     *
     *  Text colors, label text, label colors, etc.
     *
     *
     *  DO NOT set `cell.textView.font` !
     *  Instead, you need to set `self.collectionView.collectionViewLayout.messageBubbleFont` to the font you want in `viewDidLoad`
     *
     *
     *  DO NOT manipulate cell layout information!
     *  Instead, override the properties you want on `self.collectionView.collectionViewLayout` from `viewDidLoad`
     */
    
    JSQMessage *msg = [self.displayMessages objectAtIndex:indexPath.item];
    
    if (!msg.isMediaMessage) {
        
        if ([msg.senderId isEqualToString:self.senderId]) {
            cell.textView.textColor = [UIColor blackColor];
        }
        else {
            cell.textView.textColor = [UIColor whiteColor];
        }
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    }
    
    return cell;
}



#pragma mark - JSQMessages collection view flow layout delegate

#pragma mark - Adjusting cell label heights

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Each label in a cell has a `height` delegate method that corresponds to its text dataSource method
     */
    
    /**
     *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
     *  The other label height delegate methods should follow similarly
     *
     *  Show a timestamp for every 3rd message
     */
    if (indexPath.item % 3 == 0) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  iOS7-style sender name labels
     */
    JSQMessage *currentMessage = [self.displayMessages objectAtIndex:indexPath.item];
    if ([[currentMessage senderId] isEqualToString:self.senderId]) {
        return 0.0f;
    }
    
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [self.displayMessages objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:[currentMessage senderId]]) {
            return 0.0f;
        }
    }
    
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return 0.0f;
}

#pragma mark - Responding to collection view tap events

- (void)collectionView:(JSQMessagesCollectionView *)collectionView
                header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender
{
    [self loadOldMessages];
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped avatar!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *message=self.displayMessages[indexPath.row];
    if([message.media isKindOfClass:[JSQPhotoMediaItem class]] ||
       [message.media isKindOfClass:[JSQVideoMediaItem class]]){
        XHDisplayMediaViewController *mediaVC=[[XHDisplayMediaViewController alloc] init];
        mediaVC.mediaItem=message.media;
        [self.navigationController pushViewController:mediaVC animated:YES];
    }
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath touchLocation:(CGPoint)touchLocation
{
    NSLog(@"Tapped cell at %@!", NSStringFromCGPoint(touchLocation));
}

#pragma mark - LeanMessage

-(void)loadMessagesWhenInit{
    WEAKSELF
    [self.conversation queryMessagesBeforeId:nil timestamp:0 limit:10 callback:^(NSArray *typedMessages, NSError *error) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableArray* messages=[NSMutableArray array];
            for(AVIMTypedMessage* typedMessage in typedMessages){
                [messages addObject:[weakSelf displayMessageByAVIMTypedMessage:typedMessage]];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.displayMessages=messages;
                [weakSelf.collectionView reloadData];
                [weakSelf scrollToBottomAnimated:YES];
            });
        });
    }];
}

-(NSString*)fetchDataOfMessageFile:(AVFile*)file fileName:(NSString*)fileName error:(NSError**)error{
    NSString* path=[[NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingString:fileName];
    NSData* data=[file getData:error];
    if(*error==nil){
        [data writeToFile:path atomically:YES];
    }
    return path;
}

-(JSQMessage*)displayMessageByAVIMTypedMessage:(AVIMTypedMessage*)typedMessage{
    AVIMMessageMediaType msgType = typedMessage.mediaType;
    JSQMessage *message;
    NSDate* timestamp=[NSDate dateWithTimeIntervalSince1970:typedMessage.sendTimestamp/1000];
    NSString *senderId=typedMessage.clientId;
    NSString *senderDisplayName=[self displayNameByClientId:senderId];
    BOOL outgoing=[self.senderId isEqualToString:typedMessage.clientId];
    switch (msgType) {
        case kAVIMMessageMediaTypeText: {
            AVIMTextMessage *receiveTextMessage = (AVIMTextMessage *)typedMessage;
            message=[[JSQMessage alloc] initWithSenderId:typedMessage.clientId senderDisplayName:senderDisplayName date:timestamp text:receiveTextMessage.text];
            break;
        }
        case kAVIMMessageMediaTypeImage: {
            AVIMImageMessage *imageMessage = (AVIMImageMessage *)typedMessage;
            NSError *error;
            NSData *data=[imageMessage.file getData:&error];
            UIImage *image=[UIImage imageWithData:data];
            JSQPhotoMediaItem *photoItem=[[JSQPhotoMediaItem alloc] initWithImage:image];
            photoItem.appliesMediaViewMaskAsOutgoing=outgoing;
            message=[[JSQMessage alloc] initWithSenderId:senderId senderDisplayName:senderDisplayName date:timestamp media:photoItem];
            break;
        }
        case kAVIMMessageMediaTypeVideo:{
            AVIMVideoMessage* receiveVideoMessage=(AVIMVideoMessage*)typedMessage;
            NSString* format=receiveVideoMessage.format;
            NSError* error;
            NSString* path=[self fetchDataOfMessageFile:typedMessage.file fileName:[NSString stringWithFormat:@"%@.%@",typedMessage.messageId,format] error:&error];
            NSURL *videoURL = [NSURL fileURLWithPath:path];
            JSQVideoMediaItem *videoItem = [[JSQVideoMediaItem alloc] initWithFileURL:videoURL isReadyToPlay:YES];
            videoItem.appliesMediaViewMaskAsOutgoing=outgoing;
            message = [[JSQMessage alloc] initWithSenderId:senderId senderDisplayName:senderDisplayName date:timestamp media:videoItem];
            break;
        }
        case kAVIMMessageMediaTypeLocation:{
            WEAKSELF
            AVIMLocationMessage *locationMessage=(AVIMLocationMessage*)typedMessage;
            CLLocation *location = [[CLLocation alloc] initWithLatitude:locationMessage.location.latitude longitude:locationMessage.location.longitude];
            JSQLocationMediaItem *locationItem = [[JSQLocationMediaItem alloc] init];
            [locationItem setLocation:location withCompletionHandler:^{
                [weakSelf.collectionView reloadData];
            }];
            locationItem.appliesMediaViewMaskAsOutgoing=outgoing;
            message=[[JSQMessage alloc] initWithSenderId:senderId senderDisplayName:senderDisplayName date:timestamp media:locationItem];
        }
        default:
            break;
    }
    return message;
}

-(BOOL)filterError:(NSError*)error{
    if(error){
        UIAlertView *alertView=[[UIAlertView alloc]
                                initWithTitle:nil message:error.description delegate:nil
                                cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alertView show];
        return NO;
    }
    return YES;
}

-(void)addMessage:(AVIMTypedMessage*)message completion:(dispatch_block_t)completion{
    WEAKSELF
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        JSQMessage *displayMessage=[self displayMessageByAVIMTypedMessage:message];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.displayMessages addObject:displayMessage];
            completion();
        });
    });
}

-(void)sendMessage:(AVIMTypedMessage*)message{
    WEAKSELF
    [self.conversation sendMessage:message callback:^(BOOL succeeded, NSError *error) {
        if([weakSelf filterError:error]){
            [weakSelf addMessage:message completion:^{
                [weakSelf finishSendingMessageAnimated:YES];
            }];
        }
    }];
}

-(void)setupReceiveMessageBlock{
    WEAKSELF
    [[LeanMessageManager manager] setupDidReceiveTypedMessageCompletion:^(AVIMConversation *conversation, AVIMTypedMessage *message) {
        // 富文本信息
        if([conversation.conversationId isEqualToString:self.conversation.conversationId]){
            [weakSelf addMessage:message completion:^{
                [weakSelf finishReceivingMessage];
            }];
        }
    }];
}

static CGPoint  delayOffset = {0.0};
-(void)loadOldMessages{
    if(self.displayMessages.count==0){
        return;
    }else{
        JSQMessage *firstMessage=self.displayMessages[0];
        WEAKSELF
        [self.conversation queryMessagesBeforeId:nil timestamp:[firstMessage.date timeIntervalSince1970]*1000 limit:20 callback:^(NSArray *typedMessages, NSError *error) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSMutableArray *oldMessages=[NSMutableArray array];
                for(AVIMTypedMessage* typedMessage in typedMessages){
                    [oldMessages addObject:[weakSelf displayMessageByAVIMTypedMessage:typedMessage]];
                }
                NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:oldMessages.count];
                delayOffset = weakSelf.collectionView.contentOffset;
                [oldMessages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
                    [indexPaths addObject:indexPath];
                    delayOffset.y+=[weakSelf.collectionView.collectionViewLayout sizeForItemAtIndexPath:indexPath].height;
                }];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [UIView setAnimationsEnabled:NO];
                    NSMutableArray *messages = [NSMutableArray arrayWithArray:oldMessages];
                    [messages addObjectsFromArray:weakSelf.displayMessages];
                    weakSelf.displayMessages=messages;
                    [weakSelf.collectionView insertItemsAtIndexPaths:indexPaths];
                    [weakSelf.collectionView setContentOffset:delayOffset];
                    [UIView setAnimationsEnabled:YES];
                });
            });
        }];
    }
}

-(XHPhotographyHelper*)photographyHelper{
    if(_photographyHelper==nil){
        _photographyHelper=[[XHPhotographyHelper alloc] init];
    }
    return _photographyHelper;
}

-(void)didSendMessageWithPhoto:(UIImage*)photo{
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"tmp.jpg"];
    NSData* photoData=UIImageJPEGRepresentation(photo,1.0);
    [photoData writeToFile:filePath atomically:YES];
    AVIMImageMessage *message = [AVIMImageMessage messageWithText:nil attachedFilePath:filePath attributes:nil];
    [self sendMessage:message];
}

-(void)didSendMessageWithVideoPath:(NSString*)path{
    AVIMVideoMessage* message=[AVIMVideoMessage messageWithText:nil attachedFilePath:path attributes:nil];
    [self sendMessage:message];
}

-(void)didSendMessageWithLatitude:(long)latitude longitude:(long)longitude{
    AVIMLocationMessage *message=[AVIMLocationMessage messageWithText:@"北京" latitude:39.f longitude:116.f attributes:nil];
    [self sendMessage:message];
}

@end
