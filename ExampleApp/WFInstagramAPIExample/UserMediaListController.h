//
//  FirstViewController.h
//  WFInstagramAPIExample
//
//  Created by William Fleming on 1/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UserMediaListController : UITableViewController

@property (strong, atomic) WFIGMediaCollection *mediaCollection;

/**
 * initialize the controller with the user to show the photos of.
 * if user is nil, this controller will use the current authorized user.
 */
- (id) initWithWFIGUser:(WFIGUser*)user;

@end
