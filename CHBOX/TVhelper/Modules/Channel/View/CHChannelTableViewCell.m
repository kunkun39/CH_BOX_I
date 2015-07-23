//
//  CHChannelTableViewCell.m
//  TVhelper
//
//  Created by shanshu on 15/5/20.
//  Copyright (c) 2015年 shanshu. All rights reserved.
//

#import "CHChannelTableViewCell.h"

@interface CHChannelTableViewCell()

@end

@implementation CHChannelTableViewCell

- (void)awakeFromNib {
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

+ (CHChannelTableViewCell *) chChannelTableViewCell:(UITableView *)tableView {
    CHChannelTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ch_channel_play"];
    
    if(cell == nil) {
        NSLog(@"创建CELL");
        cell = [[[NSBundle mainBundle] loadNibNamed:@"CHChannelTableViewCell" owner:nil options:nil] lastObject];
        cell.backgroundColor = COLOR_RGB(60, 60, 60, 1);
    }
    
    return cell;
}


@end
