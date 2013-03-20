//
//  WFIGUser.m
//
//  Created by William Fleming on 11/16/11.
//

#import "WFIGUser.h"

#import "WFInstagramAPI.h"
#import "WFIGResponse.h"
#import "WFIGMedia.h"
#import "WFIGMediaCollection.h"
#import "WFIGRelationship.h"

NSString * const WFIGUserDidChangeOutgoingStatusNotification = @"WFIGUserDidChangeOutgoingStatusNotification";

@interface WFIGUser (Private)
- (NSString*) effectiveApiId;
+ (WFIGMediaCollection*) getMedia:(NSString*)endpoint error:(NSError* __autoreleasing*)error;
@end

#pragma mark -
@implementation WFIGUser {
    BOOL _hasBasicInfo;
}

@synthesize username, instagramId, profilePicture, website, fullName, bio,
  followedByCount, followsCount, mediaCount;

+ (WFIGUser*) remoteUserWithId:(NSString*)userId error:(NSError* __autoreleasing*)error {
  WFIGUser *user = nil;
  WFIGResponse *response = [WFInstagramAPI get:[NSString stringWithFormat:@"/users/%@", userId]];
  if ([response isSuccess]) {
    NSDictionary *data = [[response parsedBody] objectForKey:@"data"];
    user = [[self alloc] initWithJSONFragment:data];
    user->_isCurrentUser = [@"self" isEqual:userId];
  } else {
    if (error) {
      *error = [response error];
    }
    WFIGDLOG(@"response error: %@", [response error]);
    WFIGDLOG(@"response body: %@", [response parsedBody]);
  }
  return user;
}

- (id) initWithJSONFragment:(NSDictionary*)json {
  if ((self = [self init])) {
      _hasBasicInfo = NO;
    self.instagramId = [json objectForKey:@"id"];
    self.username = [json objectForKey:@"username"];
    self.profilePicture = [json objectForKey:@"profile_picture"];
    self.website = [json objectForKey:@"website"];
    self.bio = [json objectForKey:@"bio"];
    self.fullName = [json objectForKey:@"full_name"];
    
    //TODO: counts properties on other than explicit user attrs
    NSDictionary *counts = [json objectForKey:@"counts"];
    self.followsCount = [counts objectForKey:@"follows"];
    self.followedByCount = [counts objectForKey:@"followed_by"];
    self.mediaCount = [counts objectForKey:@"media"];
  }
  return self;
}

- (WFIGMediaCollection*) recentMediaWithError:(NSError* __autoreleasing*)error; {
  NSString *endpoint = [NSString stringWithFormat:@"/users/%@/media/recent", [self effectiveApiId]];
  return [WFIGUser getMedia:endpoint error:error];
}

- (WFIGMediaCollection*) feedMediaWithError:(NSError* __autoreleasing*)error {
  return [WFIGUser getMedia:@"/users/self/feed" error:error];
}

- (void)relationshipWithCompletion:(WFIGRelationshipCallback)completion
{
    __block WFIGUser *blockSelf = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *endpoint = [NSString stringWithFormat:@"/users/%@/relationship", self.instagramId];
        WFIGResponse *response = [WFInstagramAPI get:endpoint];
        dispatch_async( dispatch_get_main_queue(), ^{
            if ([response isSuccess]) {
                @synchronized(self) {
                    self.relationship = [[WFIGRelationship alloc] initWithJSON:response.parsedBody];
                }
            } else {
                WFIGDLOG(@"response error: %@", [response error]);
                WFIGDLOG(@"response body: %@", [response parsedBody]);
            }
            
            completion(blockSelf, self.relationship, [response error]);
        });
    });
}

- (void)updateRelationship:(WFIGRelationshipAction)action withCompletion:(WFIGRelationshipCallback)completion
{
    __block WFIGUser *blockSelf = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSString *path = [NSString stringWithFormat:@"/users/%@/relationship", self.instagramId];
        NSDictionary *postParams = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [WFIGUser actionString:action], @"action",
                                    nil];
        WFIGResponse *response = [WFInstagramAPI post:postParams to:path];
        
        dispatch_async( dispatch_get_main_queue(), ^{
            if ([response isSuccess]) {
                WFIGOutgoingStatus oldOutgoingStatus = self.relationship.outgoingStatus;
                @synchronized(self) {
                    self.relationship = [[WFIGRelationship alloc] initWithJSON:response.parsedBody];
                }
                if (oldOutgoingStatus != self.relationship.outgoingStatus) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:WFIGUserDidChangeOutgoingStatusNotification
                                                                        object:self];
                }
            } else {
                WFIGDLOG(@"response error: %@", [response error]);
                WFIGDLOG(@"response body: %@", [response parsedBody]);
            }
            
            completion(blockSelf, self.relationship, [response error]);
        });
    });
}

+ (NSString *)actionString:(WFIGRelationshipAction)action
{
    switch (action) {
        case WFIGRelationshipActionFollow:
            return @"follow";
        case WFIGRelationshipActionUnfollow:
            return @"unfollow";
        case WFIGRelationshipActionBlock:
            return @"block";
        case WFIGRelationshipActionUnblock:
            return @"unblock";
        case WFIGRelationshipActionApprove:
            return @"approve";
        case WFIGRelationshipActionDeny:
            return @"deny";
    }
    return nil;
}

- (BOOL)hasBasicInfo
{
    return _hasBasicInfo;
}

- (void)loadBasicInfoWithCompletion:(WFIGBasicInfoCallback)completion
{
    __block WFIGUser *blockSelf = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *endpoint = [NSString stringWithFormat:@"/users/%@", self.instagramId];
        WFIGResponse *response = [WFInstagramAPI get:endpoint];
        dispatch_async( dispatch_get_main_queue(), ^{
            NSString *remoteId = response.parsedBody[@"data"][@"id"];
            if ([response isSuccess] && [self.instagramId isEqualToString:remoteId]) {
                @synchronized(self) {
                    _hasBasicInfo = YES;

                    NSDictionary *json = response.parsedBody[@"data"];
                    
                    self.username = [json objectForKey:@"username"];
                    self.profilePicture = [json objectForKey:@"profile_picture"];
                    self.website = [json objectForKey:@"website"];
                    self.bio = [json objectForKey:@"bio"];
                    self.fullName = [json objectForKey:@"full_name"];
                    
                    NSDictionary *counts = [json objectForKey:@"counts"];
                    self.followsCount = [counts objectForKey:@"follows"];
                    self.followedByCount = [counts objectForKey:@"followed_by"];
                    self.mediaCount = [counts objectForKey:@"media"];
                }
            } else {
                WFIGDLOG(@"response error: %@", [response error]);
                WFIGDLOG(@"response body: %@", [response parsedBody]);
            }
            
            completion(blockSelf, [response error]);
        });
    });
}

@end

#pragma mark -
@implementation WFIGUser (Private)

- (NSString*) effectiveApiId {
  return (_isCurrentUser ? @"self" : self.instagramId);
}

+ (WFIGMediaCollection*) getMedia:(NSString*)endpoint error:(NSError* __autoreleasing*)error {
  WFIGMediaCollection *media = nil;
  WFIGResponse *response = [WFInstagramAPI get:endpoint];
  if ([response isSuccess]) {
    media = [[WFIGMediaCollection alloc] initWithJSON:[response parsedBody]];
  } else {
    if (error) {
      *error = [response error];
    }
    WFIGDLOG(@"response error: %@", [response error]);
    WFIGDLOG(@"response body: %@", [response parsedBody]);
  }
  
  return media;
}

@end
