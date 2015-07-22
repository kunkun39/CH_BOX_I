//
//  CHProgramTableViewCell.m
//  TVhelper
//
//  Created by Jack Wang on 15/7/22.
//  Copyright (c) 2015年 shanshu. All rights reserved.
//

#import "CHProgramTableViewCell.h"

@implementation CHProgramTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

}

+ (CHProgramTableViewCell *) chProgramTableViewCell:(UITableView *)tableView {
    CHProgramTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ch_program_play"];
    
    if(cell == nil) {
        NSLog(@"创建CELL");
        cell = [[[NSBundle mainBundle] loadNibNamed:@"CHProgramTableViewCell" owner:nil options:nil] lastObject];
        cell.backgroundColor = COLOR_RGB(60, 60, 60, 1);
    }
    
    return cell;
}

@end
