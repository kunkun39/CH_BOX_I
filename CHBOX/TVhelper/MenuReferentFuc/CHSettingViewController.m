//
//  SettingViewController.m
//  TVhelper
//
//  Created by shanshu on 15/4/2.
//  Copyright (c) 2015年 shanshu. All rights reserved.
//

#import "CHSettingViewController.h"
#import "CHSettingTableViewCell.h"
#import "CHTipsViewController.h"
#define VERSINONS @"1.0.0"
@interface CHSettingViewController ()<UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) IBOutlet UITableView *settingTableView;

@property (strong, nonatomic) IBOutlet UIView *settingCell;
@property (strong, nonatomic) NSArray * arrayRow;
@property (strong, nonatomic) NSArray * arraySection;
@end

@implementation CHSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initDataSource];
    self.settingTableView.dataSource = self;
    self.settingTableView.delegate = self;
    self.view.backgroundColor = [UIColor blackColor];
    self.CHBoxBtn.hidden = YES;
    self.CHBoxImageView.hidden = YES;
    self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;    
    
}

- (void)initDataSource
{
    _arrayRow = @[@[@"系统帮助", @"遥控器帮助"],@[@"版本"]];
    _arraySection = @[@"高级设置", @"关于"];
}

- (void)processGobackBtn
{
    AudioServicesPlaySystemSound(SOUND_ID);
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _arraySection.count;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ((NSArray *)_arrayRow[section]).count;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView* customView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 35)];
    return customView;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * cellID = @"cellID";
       CHSettingTableViewCell *cell = (CHSettingTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"CHSettingTableViewCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    cell.leftLabel.text = _arrayRow[indexPath.section][indexPath.row];
//    cell.backgroundColor = [UIColor clearColor];
    if ([cell.leftLabel.text isEqualToString:@"版本"]) {
        cell.cellDetailLabel.text = @"1.0.0";
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }else cell.cellDetailLabel.hidden = YES;
    UIView * separete = [[UIView alloc]initWithFrame:CGRectMake(15, 5, SCREEN_WIDTH - 30, CGRectGetHeight(cell.frame) - 10)];
    cell.backgroundColor = COLOR_RGB(26, 28, 39, 1);
    separete.layer.borderWidth = 1;
    separete.layer.borderColor = [COLOR_RGB(235, 235, 235, 1) CGColor];
    separete.layer.cornerRadius = 10;
//    separete.layer.backgroundColor = [[UIColor whiteColor]CGColor];
    separete.backgroundColor = COLOR_RGB(50, 50, 50, 1);
    [cell addSubview: separete];
    [cell sendSubviewToBack:separete];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.settingTableView) {
        AudioServicesPlaySystemSound(SOUND_ID);
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        CHTipsViewController * detailVC = [[CHTipsViewController alloc]init];
        detailVC.titleStr = _arrayRow[indexPath.section][indexPath.row];
        if (![detailVC.titleStr isEqualToString:@"版本" ]) {
            [self presentViewController:detailVC animated:NO completion:nil];
        }

        return;
    }
}


@end
