//
//  WFIGRelationship.m
//  WFInstagramAPI
//
//  Created by Jacob Moore on 3/19/13.
//
//

#import "WFIGRelationship.h"

@implementation WFIGRelationship

- (id) initWithJSON:(NSDictionary *)json
{
    if ((self = [self init])) {
        _incomingStatus = [WFIGRelationship incomingStatusFromString:json[@"data"][@"incoming_status"]];
        _outgoingStatus = [WFIGRelationship outgoingStatusFromString:json[@"data"][@"outgoing_status"]];
        _isPrivate = [json[@"data"][@"target_user_is_private"] intValue];
    }
    return self;
}

+ (WFIGIncomingStatus)incomingStatusFromString:(NSString *)statusString
{
    if ([statusString isEqualToString:@"followed_by"]) return WFIGIncomingStatusFollowedBy;
    if ([statusString isEqualToString:@"requested_by"]) return WFIGIncomingStatusRequestedBy;
    if ([statusString isEqualToString:@"blocked_by_you"]) return WFIGIncomingStatusBlockedByYou;
    if ([statusString isEqualToString:@"none"]) return WFIGIncomingStatusNone;
    return WFIGOutgoingStatusNone;
}

+ (WFIGOutgoingStatus)outgoingStatusFromString:(NSString *)statusString
{
    if ([statusString isEqualToString:@"follows"]) return WFIGOutgoingStatusFollows;
    if ([statusString isEqualToString:@"requested"]) return WFIGOutgoingStatusRequested;
    if ([statusString isEqualToString:@"none"]) return WFIGOutgoingStatusNone;
    return WFIGIncomingStatusNone;
}

@end
