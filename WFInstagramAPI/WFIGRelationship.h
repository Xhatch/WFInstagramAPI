//
//  WFIGRelationship.h
//  WFInstagramAPI
//
//  Created by Jacob Moore on 3/19/13.
//
//

#import <Foundation/Foundation.h>

typedef enum {
    WFIGIncomingStatusUnknown,
    WFIGIncomingStatusFollowedBy,
    WFIGIncomingStatusRequestedBy,
    WFIGIncomingStatusBlockedByYou,
    WFIGIncomingStatusNone,
} WFIGIncomingStatus;

typedef enum {
    WFIGOutgoingStatusUnknown,
    WFIGOutgoingStatusFollows,
    WFIGOutgoingStatusRequested,
    WFIGOutgoingStatusNone,
} WFIGOutgoingStatus;

@interface WFIGRelationship : NSObject

@property (nonatomic) WFIGIncomingStatus incomingStatus;
@property (nonatomic) WFIGOutgoingStatus outgoingStatus;
@property (nonatomic) BOOL isPrivate;

- (id) initWithJSON:(NSDictionary *)json;

@end
