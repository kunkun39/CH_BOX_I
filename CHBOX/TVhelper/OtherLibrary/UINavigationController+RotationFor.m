//
//  UINavigationController+RotationFor.m
//  TVhelper
//
//  Created by shanshu on 15/5/25.
//  Copyright (c) 2015年 shanshu. All rights reserved.
//

#import "UINavigationController+RotationFor.h"

@implementation UINavigationController (RotationFor)
-(BOOL)shouldAutorotate {
    return [[self.viewControllers lastObject] shouldAutorotate];
}

-(NSUInteger)supportedInterfaceOrientations {
    return [[self.viewControllers lastObject] supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return [[self.viewControllers lastObject] preferredInterfaceOrientationForPresentation];
}
@end
