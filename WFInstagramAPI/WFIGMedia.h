//
//  WFIGMedia.h
//
//  Created by William Fleming on 11/14/11.
//

#import <Foundation/Foundation.h>

@class WFIGMedia, WFIGUser, WFIGMediaCollection;

typedef void (^WFIGMediaImageCallback)(WFIGMedia *media, UIImage *image);

@interface WFIGMedia : NSObject {
}

@property (strong, nonatomic) NSString *instagramId;
@property (strong, nonatomic) NSString *imageURL; // S3 - don't trust persisted
@property (strong, nonatomic) NSString *thumbnailURL; // S3 - don't trust persisted
@property (strong, nonatomic) NSString *lowResolutionURL; // S3 - don't trust persisted
@property (strong, nonatomic) NSString *instagramURL;  // web url
@property (strong, nonatomic) NSDate *createdTime;
@property (strong, nonatomic) NSString *caption;
@property (nonatomic) int commentsCount;
@property (strong, nonatomic) NSArray *commentsData; // raw JSON comment data
@property (nonatomic) int likesCount;
@property (strong, nonatomic) NSArray *likesData; // raw JSON like data
@property (strong, nonatomic) NSMutableArray *tags; // array of strings
@property (strong, nonatomic) NSDictionary *userData;
@property (strong, nonatomic) NSDictionary *locationData;

+ (WFIGMediaCollection*) popularMediaWithError:(NSError* __autoreleasing*)error;

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
 */
- (NSMutableArray*) comments;

/**
 * array of WFIGUser instances, initially
 * generated from -likesData JSON.
 * Note that user attrs given by the API on like data are not
 * full: only a few attributes will actually be filled in.
 * You should use -[WFIGUser remoteUserWithId:error:] if you
 * require more user data.
 */
- (NSMutableArray*) likeUsers;

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
