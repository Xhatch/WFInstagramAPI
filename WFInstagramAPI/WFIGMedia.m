//
//  WFIGMedia.m
//
//  Created by William Fleming on 11/14/11.
//

#import "WFIGMedia.h"

#import "WFInstagramAPI.h"
#import "WFIGFunctions.h"
#import "WFIGImageCache.h"
#import "WFIGUser.h"
#import "WFIGComment.h"
#import "WFIGResponse.h"

@interface WFIGMedia()
@property (readwrite, nonatomic) int commentsCount;
@property (readwrite, nonatomic) int likesCount;
@end

@implementation WFIGMedia {
  NSMutableArray *_comments;
  BOOL _hasAllComments;
    NSMutableArray *_likes;
    BOOL _hasAllLikes;
}

@synthesize instagramId, imageURL, thumbnailURL, lowResolutionURL, instagramURL, createdTime,
  caption, commentsCount, commentsData, likesCount, likesData, tags, userData, locationData;

#pragma mark - class methods

+ (WFIGMediaCollection*) popularMediaWithError:(NSError* __autoreleasing*)error {
  WFIGMediaCollection *media = nil;
  WFIGResponse *response = [WFInstagramAPI get:@"/media/popular"];
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

+ (WFIGMediaCollection*) mediaWithTag:(NSString *)tag error:(NSError* __autoreleasing*)error
{
    WFIGMediaCollection *media = nil;
    NSString *url = [NSString stringWithFormat:@"/tags/%@/media/recent", tag];
    WFIGResponse *response = [WFInstagramAPI get:url];
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

#pragma mark - instance methods

- (id) init {
  if ((self = [super init])) {
    _hasAllComments = NO;
    _hasAllLikes = NO;
  }
  return self;
}

- (id) initWithJSONFragment:(NSDictionary*)json {
  if ((self = [self init])) {
    self.instagramId = [json objectForKey:@"id"];
    
    self.imageURL = [[[json objectForKey:@"images"] objectForKey:@"standard_resolution"] objectForKey:@"url"];
    self.thumbnailURL = [[[json objectForKey:@"images"] objectForKey:@"thumbnail"] objectForKey:@"url"];
    self.lowResolutionURL = [[[json objectForKey:@"images"] objectForKey:@"low_resolution"] objectForKey:@"url"];
    
    if (![[NSNull null] isEqual:[json objectForKey:@"link"]]) {
      self.instagramURL = [json objectForKey:@"link"];
    }
    
    self.createdTime = WFIGDateFromJSONString([json objectForKey:@"created_time"]);
    
    // from some requests, caption is just text. others, a dict.
    id captionInfo = [json objectForKey:@"caption"];
    if ([captionInfo isKindOfClass:[NSDictionary class]]) {
      self.caption = [(NSDictionary*)captionInfo objectForKey:@"text"];
    } else if (![[NSNull null] isEqual:captionInfo]){
      self.caption = captionInfo;
    }
    
    self.commentsCount = [[[json objectForKey:@"comments"] objectForKey:@"count"] intValue];
    self.commentsData = [[json objectForKey:@"comments"] objectForKey:@"data"];

    self.likesCount = [[[json objectForKey:@"likes"] objectForKey:@"count"] intValue];
    self.likesData = [[json objectForKey:@"likes"] objectForKey:@"data"];
    
    self.tags = [json objectForKey:@"tags"];
    self.userData = [json objectForKey:@"user"];
    self.locationData = [json objectForKey:@"location"];
  }
  return self;
}

- (NSString*) iOSURL {
  return [NSString stringWithFormat:@"instagram://media?id=%@", self.instagramId];
}

- (WFIGUser*) user {
  return [[WFIGUser alloc] initWithJSONFragment:self.userData];
}

- (NSMutableArray*) comments {
  if (nil == _comments) {
    _comments = [WFIGComment commentsWithJSON:self.commentsData];
  }
  return _comments;
}

- (BOOL) hasAllComments {
  if ([[self comments] count] == [self commentsCount]) _hasAllComments = YES;
  return _hasAllComments;
}

- (void) allCommentsWithCompletionBlock:(WFIGMediaCommentsCallback)completionBlock
{
  __block WFIGMedia *blockSelf = self;

  if ([self hasAllComments]) {
    completionBlock(blockSelf, _comments, nil);
    return;
  }

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSString *endpoint = [NSString stringWithFormat:@"/media/%@/comments", self.instagramId];
    WFIGResponse *response = [WFInstagramAPI get:endpoint];

    dispatch_async( dispatch_get_main_queue(), ^{
      if ([response isSuccess]) {
        @synchronized(self) {
          _comments = [WFIGComment commentsWithJSON:[[response parsedBody] objectForKey:@"data"]];
          self.commentsCount = [[self comments] count];
        }
      } else {
        WFIGDLOG(@"response error: %@", [response error]);
        WFIGDLOG(@"response body: %@", [response parsedBody]);
      }
  
      completionBlock(blockSelf, _comments, [response error]);
    });
  });
}

- (NSMutableArray *) likes {
    if (nil == _likes) {
        _likes = [NSMutableArray new];
        for (NSDictionary *userDictionary in self.likesData) {
            [_likes addObject:[[WFIGUser alloc] initWithJSONFragment:userDictionary]];
        }
    }
    return _likes;
}

- (BOOL) hasAllLikes {
    if ([[self likes] count] == [self likesCount]) _hasAllLikes = YES;
    return _hasAllLikes;
}

- (void) allLikesWithCompletionBlock:(WFIGMediaCommentsCallback)completionBlock
{
    __block WFIGMedia *blockSelf = self;
    
    if ([self hasAllLikes]) {
        completionBlock(blockSelf, _likes, nil);
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *endpoint = [NSString stringWithFormat:@"/media/%@/likes", self.instagramId];
        WFIGResponse *response = [WFInstagramAPI get:endpoint];
        
        dispatch_async( dispatch_get_main_queue(), ^{
            if ([response isSuccess]) {
                @synchronized(self) {
                    _likes = [self likesWithJSON:[[response parsedBody] objectForKey:@"data"]];
                    self.likesCount = [[self likes] count];
                }
            } else {
                WFIGDLOG(@"response error: %@", [response error]);
                WFIGDLOG(@"response body: %@", [response parsedBody]);
            }
            
            completionBlock(blockSelf, _likes, [response error]);
        });
    });
}

- (NSMutableArray *)likesWithJSON:(NSArray *)json
{
    NSMutableArray *likes = [NSMutableArray new];
    for (NSDictionary *likeJson in json) {
        [likes addObject:[[WFIGUser alloc] initWithJSONFragment:likeJson]];
    }
    return likes;
}

#pragma mark - Media methods
- (UIImage*) image {
  return [WFIGImageCache getImageAtURL:self.imageURL];
}

- (void) imageCompletionBlock:(WFIGMediaImageCallback)completionBlock {
  __block WFIGMedia *blockSelf = self;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    __block UIImage *image = [blockSelf image];
    dispatch_async(dispatch_get_main_queue(), ^{
      completionBlock(blockSelf, image);
    });
  });
}

- (UIImage*) thumbnail {
  return [WFIGImageCache getImageAtURL:self.thumbnailURL];
}

- (void) thumbnailCompletionBlock:(WFIGMediaImageCallback)completionBlock {
  __block WFIGMedia *blockSelf = self;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    __block UIImage *image = [blockSelf thumbnail];
    dispatch_async(dispatch_get_main_queue(), ^{
      completionBlock(blockSelf, image);
    });
  });
}

- (UIImage*) lowResolutionImage {
  return [WFIGImageCache getImageAtURL:self.lowResolutionURL];
}

- (void) lowResolutionImageWithCompletionBlock:(WFIGMediaImageCallback)completionBlock {
  __block WFIGMedia *blockSelf = self;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    __block UIImage *image = [blockSelf lowResolutionImage];
    dispatch_async(dispatch_get_main_queue(), ^{
      completionBlock(blockSelf, image);
    });
  });
}

@end
