//
//  WFIGMedia.h
//
//  Created by William Fleming on 11/14/11.
//

#import <Foundation/Foundation.h>

@class WFIGMedia, WFIGUser, WFIGMediaCollection;

typedef void (^WFIGMediaImageCallback)(WFIGMedia *media, UIImage *image);
typedef void (^WFIGMediaCommentsCallback)(WFIGMedia *media, NSArray *comments, NSError *error);
typedef void (^WFIGMediaLikesCallback)(WFIGMedia *media, NSArray *likes, NSError *error);

@interface WFIGMedia : NSObject {
}

@property (strong, nonatomic) NSString *instagramId;
@property (strong, nonatomic) NSString *imageURL; // S3 - don't trust persisted
@property (strong, nonatomic) NSString *thumbnailURL; // S3 - don't trust persisted
@property (strong, nonatomic) NSString *lowResolutionURL; // S3 - don't trust persisted
@property (strong, nonatomic) NSString *instagramURL;  // web url
@property (strong, nonatomic) NSDate *createdTime;
@property (strong, nonatomic) NSString *caption;
@property (readonly, nonatomic) int commentsCount;
@property (strong, nonatomic) NSArray *commentsData; // raw JSON comment data
@property (readonly, nonatomic) int likesCount;
@property (strong, nonatomic) NSArray *likesData; // raw JSON like data
@property (strong, nonatomic) NSMutableArray *tags; // array of strings
@property (strong, nonatomic) NSDictionary *userData;
@property (strong, nonatomic) NSDictionary *locationData;

+ (WFIGMediaCollection*) popularMediaWithError:(NSError* __autoreleasing*)error;
+ (WFIGMediaCollection*) mediaWithTag:(NSString *)tag error:(NSError* __autoreleasing*)error;

- (id) initWithJSONFragment:(NSDictionary*)json;

/**
 * An instagram:// URL to view the photo in the local client
 */
- (NSString*) iOSURL;

/**
 * instance created from -userData JSON
 */
- (WFIGUser*) user;

/**
 * array of WFIGComment instances, initially
 * generated from -commentsData JSON
 * Note that this method may only return 8 comments if the media has more
 * than 8 comments and this object was created from one of the media
 * endpoints (the media endpoints will only return 8 comments). If you need
 * all comments, you should first call 'loadAllCommentsWithCompletion:'
 */
- (NSMutableArray*) comments;

/**
 * returns YES if all comments have been loaded. The 'comments' method may
 * return less comments than 'commentsCount', because the media endpoints
 * only return 8 comments
 */
- (BOOL) hasAllComments;

/**
 * Loads all comments asynchronously on a background thread, and calls the
 * completion block on the main thread when the comments are loaded.
 */
- (void) allCommentsWithCompletionBlock:(WFIGMediaCommentsCallback)completionBlock;


/**
 * array of WFIGUser instances, initially generated from -likesData
 * Note that this method may only return 10 likes if the media has
 * more than 10 likes and this object was created from one of the
 * media endpoints (the media endpoints will only return 10 likes). If you
 * need all likes, you should first call 'loadAllLikesWithCompletion:'
 */
- (NSMutableArray *) likes;

/**
 * returns YES if all likes have been loaded. The 'likes' method
 * may return less likes than 'likesCount', because the media endpoints
 * only return 10 likes
 */
- (BOOL) hasAllLikes;

/**
 * Loads all likes asynchronously on a background thread, and calls the
 * completion block on the main thread when the likes are loaded.
 */
- (void) allLikesWithCompletionBlock:(WFIGMediaLikesCallback)completionBlock;

/**
 * Media methods. Variants with a completion block argument execute
 * asynchronously on a background thread: your block will get called on the
 * main thread when the image is ready.
 *
 * Variants without the completion block are synchronous.
 */
- (UIImage*) image;
- (void) imageCompletionBlock:(WFIGMediaImageCallback)completionBlock;
- (UIImage*) thumbnail;
- (void) thumbnailCompletionBlock:(WFIGMediaImageCallback)completionBlock;
- (UIImage*) lowResolutionImage;
- (void) lowResolutionImageWithCompletionBlock:(WFIGMediaImageCallback)completionBlock;

@end
