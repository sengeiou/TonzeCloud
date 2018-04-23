//
//  CloudMenuDetailViewController.m
//  Product
//
//  Created by 肖栋 on 17/5/11.
//  Copyright © 2017年 TianJi. All rights reserved.
//

#import "CloudMenuDetailViewController.h"
#import "SDCycleScrollView.h"
#import "TJYApplicableEquipmentCell.h"
#import "HerderClassifyButton.h"
#import "TJYCookListModel.h"
#import "TJYCookDetailsEquipmentModel.h"
#import "TJYCookIngredientModel.h"
#import "TJYIngredientCell.h"
#import "TJYCookSetpModel.h"
#import "TJYCookStepCell.h"
#import "TJYMenuDetailsRemarksCell.h"
#import "DeviceModel.h"
#import "ControllerHelper.h"
#import "DeviceProgressViewController.h"
#import "TimePickerView.h"
#import "PreferenceModel.h"
#import "TJYMenuDetailIntroductionView.h"
#import "StartDeviceButton.h"

@interface CloudMenuDetailViewController ()<UITableViewDelegate,UITableViewDataSource,SDCycleScrollViewDelegate>
{
    CGFloat beginContentY;          //开始滑动的位置
    CGFloat endContentY;            //结束滑动的位置
    CGFloat sectionHeaderHeight;    //section的header高度
    NSMutableArray *deviceModelArr,*deviceListModel;//云端列表，匹配列表
    TimePickerView  *timePicker;
    DeviceModel  *orderModel;
    BOOL         isOrder;
    
    UIButton *likeBtn;
    UIButton *collectionBtn;
    BOOL          isLike;       //是否点赞
    BOOL          isCare;       //是否关注
}
@property (nonatomic, strong) UITableView *tableView;
/// 导航栏
@property (nonatomic ,strong) UIView *navigationView;
/// 菜谱名称
@property (nonatomic ,strong) UILabel *menuNameLabel;
/// 菜谱图片
@property (nonatomic ,strong) UIImageView *menuImg;
/// 头部视图
@property (nonatomic ,strong) UIView *headerView;

@property (nonatomic, copy) NSMutableArray *taskTypeArry;
/// 导航栏菜谱名称
@property (nonatomic ,strong) UILabel *menuNavLabel;
/// 导航菜谱图片
@property (nonatomic ,strong) UIImageView *menuNavImg;
/// banner 视图
@property (nonatomic,strong)  SDCycleScrollView   *cycleScrollView;
/// 食物热量
@property (nonatomic ,strong) UILabel *energyLabel;
/// 阅读量
@property (nonatomic ,strong) UILabel *readLabel;
/// 点赞量
@property (nonatomic ,strong) UILabel *likeLabel;
/// 菜谱描述
@property (nonatomic ,strong) UILabel *abstractLabel;
/// banner图片数据源
@property (nonatomic ,strong)  NSMutableArray *imageListArr;
/// 食材总热量
@property (nonatomic ,assign) NSInteger caloriesSum;
/// 设备数据源
@property (nonatomic ,copy) NSMutableArray *equipmentDataSource;
/// 食材数据源
@property (nonatomic ,copy) NSMutableArray *ingredientDataSource;
/// 菜谱详情模型
@property (nonatomic ,strong) TJYCookListModel *cookListModel;
/// 制作步骤数据源
@property (nonatomic, copy) NSMutableArray *stepDataSource;
/// 食材卡路里
@property (nonatomic, assign) NSInteger calories_sum ;
/// 食材总卡路里
@property (nonatomic, assign) NSInteger calories_pre100 ;

@property (nonatomic ,strong) TJYMenuDetailIntroductionView *introductionView;

@end

@implementation CloudMenuDetailViewController

/// 改变状态栏颜色
- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.baseTitle = @"菜谱详情";
    self.isHiddenNavBar = YES;
    isOrder = NO;
    [self buildUI];
    [self setNavigation];
    [self loadData];
}
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(OnPipeData:) name:kOnRecvLocalPipeData object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(OnPipeData:) name:kOnRecvPipeData object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(OnPipeData:) name:kOnRecvPipeSyncData object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(coverWindowClick) name:@"click" object:nil];
    
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kOnRecvLocalPipeData object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kOnRecvPipeData object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kOnRecvPipeSyncData object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"click" object:nil];

}

#pragma mark UIActionSheetDelegate (TimePickerView)
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex==1) {
        if (isOrder == YES) {
            self.model = orderModel;
        }
        if ([self.model.productID isEqualToString: CLOUD_KETTLE_PRODUCT_ID] ||[self.model.productID isEqualToString: COOKFOOD_COOKER_PRODUCT_ID]) {
            if (self.model.deviceType ==COOKFOOD_KETTLE) {
                [self.model.State setObject:@"云菜谱" forKey:@"state"];
            }
            //            //预约模式
            NSInteger hour=[timePicker.locatePicker selectedRowInComponent:0];
            NSInteger min=[timePicker.locatePicker selectedRowInComponent:1]*5;
            
            
            //获取间隔
            NSTimeInterval interval=[NSUserDefaultInfos getDateIntervalWithHour:hour Min:min];
            hour=interval/3600;
            min=(interval-hour*3600)/60;
            
            TJYCookDetailsEquipmentModel *equipmentModel= _equipmentDataSource[0];
            NSString *urlStr = [NSString stringWithFormat:@"%@%@",[self loadTitleAsc],equipmentModel.code];
            [self.model.State setObject:urlStr forKey:@"cloudMenu"];
            
            if (_cookListModel.tag_id==3) {
                [self.model.State setObject:@"降压粥" forKey:@"state"];
                
            }else if (_cookListModel.tag_id==4){
                [self.model.State setObject:@"降压汤" forKey:@"state"];
                
            }else{
                [self.model.State setObject:@"云菜谱" forKey:@"state"];
                
            }
            [self.model.State setObject:hour<10?[NSString stringWithFormat:@"0%li",(long)hour]:[NSString stringWithFormat:@"%li",(long)hour] forKey:@"orderHour"];
            [self.model.State setObject:min<10?[NSString stringWithFormat:@"0%li",(long)min]:[NSString stringWithFormat:@"%li",(long)min] forKey:@"orderMin"];
            
            if (self.model.deviceType ==COOKFOOD_KETTLE) {
                if (hour < 12) {
                    [[ControllerHelper shareHelper]controllDevice:self.model];
                }else{
                    [self showAlertWithTitle:@"提示" Message:@"最大预约时间为12小时"];
                }
            }else{
                [[ControllerHelper shareHelper]controllDevice:self.model];
            }
            
        } else {
            if (timePicker.isOrderType) {
                //预约模式
                NSInteger hour=[timePicker.locatePicker selectedRowInComponent:0];
                NSInteger min=[timePicker.locatePicker selectedRowInComponent:1]*5;
                
                //获取间隔
                TJYCookDetailsEquipmentModel *equipmentModel= _equipmentDataSource[0];
                NSString *urlStr = [NSString stringWithFormat:@"%@%@",[self loadTitleAsc],equipmentModel.code];
                [self.model.State setObject:urlStr forKey:@"cloudMenu"];
                NSTimeInterval interval=[NSUserDefaultInfos getDateIntervalWithHour:hour Min:min];
                hour=interval/3600;
                min=(interval-hour*3600)/60;
                [self.model.State setObject:@"云菜谱" forKey:@"state"];
                [self.model.State setObject:hour<10?[NSString stringWithFormat:@"0%li",(long)hour]:[NSString stringWithFormat:@"%li",(long)hour] forKey:@"orderHour"];
                [self.model.State setObject:min<10?[NSString stringWithFormat:@"0%li",(long)min]:[NSString stringWithFormat:@"%li",(long)min] forKey:@"orderMin"];
                
                [[ControllerHelper shareHelper] controllDevice:self.model];
            }
            
        }
    }
}
#pragma mark -- request Data

- (void)loadData{
    _imageListArr = [NSMutableArray array];
    _equipmentDataSource = [NSMutableArray array];
    _ingredientDataSource = [NSMutableArray array];
    _stepDataSource = [NSMutableArray array];
    
    NSString *url = [NSString stringWithFormat:@"%@?id=%ld",KMenuDetail,(long)_menuid];
    
    kSelfWeak;
    [[NetworkTool sharedNetworkTool] getMethodWithURL:url isLoading:YES success:^(id json) {
        NSDictionary *resultDic = [json objectForKey:@"result"];
        [weakSelf initDataWithDic:resultDic];
        
    } failure:^(NSString *errorStr) {
        [weakSelf.view makeToast:errorStr duration:1.0 position:CSToastPositionCenter];
    }];
}
/* 数据解析 */
- (void)initDataWithDic:(NSDictionary *)resultDic{
    /* 总卡路里*/
    _caloriesSum = [[resultDic objectForKey:@"caloriesSum"] integerValue];
    /* 每100克卡路里 */
    _calories_pre100 =[[resultDic objectForKey:@"calories_pre100"] integerValue];
    isLike = [[[resultDic objectForKey:@"cookList"] objectForKey:@"is_like"] integerValue]==0?NO:YES;
    isCare = [[[resultDic objectForKey:@"cookList"] objectForKey:@"is_collect"]integerValue]==0?NO:YES;
    self.introductionView.menuImg.hidden =[[[resultDic objectForKey:@"cookList"] objectForKey:@"is_yun"]integerValue]==1?NO:YES;
    _menuNavImg.hidden=[[[resultDic objectForKey:@"cookList"] objectForKey:@"is_yun"]integerValue]==1?NO:YES;
    _navigationView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.01];
    _menuNavImg.hidden = YES;
    _menuNavLabel.hidden = YES;
    [likeBtn setImage:[UIImage imageNamed:isLike==0?@"ic_top_zan":@"ic_top_zan_on"] forState:UIControlStateNormal];
    [collectionBtn setImage:[UIImage imageNamed:isCare==0?@"ic_top_collect_un":@"ic_top_collect_on"] forState:UIControlStateNormal];
    
    /* 菜谱简介 */
    NSDictionary *cookListDic = [resultDic objectForKey:@"cookList"];
    _cookListModel = [TJYCookListModel new];
    [_cookListModel setValues:cookListDic];
    
    _menuNavLabel.text = _cookListModel.name;//导航栏菜谱名称
    NSDictionary *attrs = @{NSFontAttributeName : [UIFont boldSystemFontOfSize:18]};
    CGSize size=[_menuNavLabel.text sizeWithAttributes:attrs];
    [_menuNavLabel setFrame:CGRectMake((SCREEN_WIDTH- size.width)/2, 20, size.width, 44)];
    
    self.introductionView.menuNameLabel.text = _cookListModel.name;
    [self.introductionView.menuNameLabel setFrame:CGRectMake((SCREEN_WIDTH- size.width)/2,15, size.width, 20)];
    self.introductionView.menuImg.frame = CGRectMake(self.introductionView.menuNameLabel.right+10, self.introductionView.menuNameLabel.top+4, 35/2, 23/2);
    self.introductionView.energyLabel.text =[NSString stringWithFormat:@"%ld千卡/100克(可食部分)",_calories_pre100];
    self.introductionView.readLabel.text = [NSString stringWithFormat:@"%ld看",_cookListModel.reading_number];
    self.introductionView.likeLabel.text = [NSString stringWithFormat:@"%ld点击",_cookListModel.like_number];
    /* banner图片 */
    NSArray *imgArr = [resultDic objectForKey:@"imageList"];
    if (imgArr.count > 0) {
        [_imageListArr addObjectsFromArray:imgArr];
    }
    self.cycleScrollView.imageURLStringsGroup = _imageListArr;
    /*  设备 */
    NSArray *equipmentArry = [resultDic objectForKey:@"equipment"];
    if (equipmentArry.count > 0) {
        for (NSDictionary *equipmentDic in equipmentArry) {
            TJYCookDetailsEquipmentModel *equipmentModel = [TJYCookDetailsEquipmentModel new];
            [equipmentModel setValues:equipmentDic];
            [_equipmentDataSource addObject:equipmentModel];
        }
    }
    /* 食材总热量 */
    _caloriesSum = [[resultDic objectForKey:@"calories_sum"] integerValue];
    /* 食材 */
    NSArray *ingredientArr = [resultDic objectForKey:@"ingredient"];
    if (ingredientArr.count > 0) {
        for (NSDictionary *ingredientDict in ingredientArr) {
            TJYCookIngredientModel *ingredientModel = [TJYCookIngredientModel new];
            [ingredientModel setValues:ingredientDict];
            [_ingredientDataSource addObject:ingredientModel];
        }
    }
    /* 制作步骤 */
    NSArray *stepListArr = [resultDic objectForKey:@"stepList"];
    for (NSDictionary *stepDic in stepListArr) {
        TJYCookSetpModel *stepModel = [TJYCookSetpModel new];
        [stepModel setValues:stepDic];
        [_stepDataSource addObject:stepModel];
    }
    [_tableView reloadData];
}
#pragma mark -- 获取菜谱的asc编码
- (NSString *)loadTitleAsc{
    
    NSString *string = _cookListModel.name;
    NSString *str = @"";
    for (int i=0; i<string.length; i++) {
        int asciiCode = [string characterAtIndex:i]; //65
        NSString *hexString = [NSString stringWithFormat:@"%@",[[NSString alloc] initWithFormat:@"%1x",asciiCode]];
        str = [NSString stringWithFormat:@"%@%@",str,hexString];
    }
    NSInteger length = str.length;
    for (int i=0; i<40-length; i++) {
        str = [NSString stringWithFormat:@"%@0",str];
    }
    return str;
}
#pragma mark -- Build UI

- (void)buildUI{
    [self.view addSubview:self.tableView];
}

#pragma mark -- Navigation
/** 导航栏 **/
- (void)setNavigation{
    
    _navigationView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth, 64)];
    _navigationView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.01];
    [self.view addSubview:_navigationView];
    
    UIButton *backBtn=[[UIButton alloc] initWithFrame:CGRectMake(5, 22, 40, 40)];
    [backBtn setImage:[UIImage drawImageWithName:@"back.png" size:CGSizeMake(12, 19)] forState:UIControlStateNormal];
    [backBtn setImageEdgeInsets:UIEdgeInsetsMake(0,-10.0, 0, 0)];
    [backBtn addTarget:self action:@selector(leftButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [_navigationView addSubview:backBtn];
    
    _menuNavLabel = InsertLabel(_navigationView, CGRectMake((SCREEN_WIDTH-150)/2, 20, 150, 44), NSTextAlignmentCenter, @"", kFontSize(18), [UIColor whiteColor], NO);
    
    _menuNavImg = [[UIImageView alloc] initWithFrame:CGRectZero];
    _menuNavImg.image = [UIImage imageNamed:@"ic_lite_yun"];
    [_navigationView addSubview:_menuNavImg];
    
    /// 点赞
    likeBtn =  InsertButtonWithType(_navigationView, CGRectMake(kScreenWidth - 75, 22 , 40, 40), 1000, self, @selector(rightBtnClick:), UIButtonTypeCustom);
    
    /// 收藏
    collectionBtn = InsertButtonWithType(_navigationView, CGRectMake(kScreenWidth - 45, 22 , 40, 40), 1001, self, @selector(rightBtnClick:), UIButtonTypeCustom);
    
    
}

#pragma mark -- Action
/** 收藏 **/
- (void)rightBtnClick:(UIButton *)sender{
    
    switch (sender.tag) {
        case 1000:
        {/// 点赞
            isLike = !isLike;
            NSString *body = [NSString stringWithFormat:@"cook_id=%ld",(long)self.menuid];
            kSelfWeak;
            [[NetworkTool sharedNetworkTool]postMethodWithURL:KEditlike body:body success:^(id json) {
                [likeBtn setImage:[UIImage imageNamed:isLike==0?@"ic_top_zan":@"ic_top_zan_on"] forState:UIControlStateNormal];
                NSInteger status  = [[json objectForKey:@"status"] integerValue];
                if (status== 1) {
                    if (!isLike) {

                            weakSelf.cookListModel.like_number = weakSelf.cookListModel.like_number - 1;
                            weakSelf.introductionView.likeLabel.text = [NSString stringWithFormat:@"%ld", (long)weakSelf.cookListModel.like_number];
                    }else{
                        weakSelf.cookListModel.like_number = weakSelf.cookListModel.like_number + 1;
                        weakSelf.introductionView.likeLabel.text = [NSString stringWithFormat:@"%ld", (long)weakSelf.cookListModel.like_number];

                    }
                }
            } failure:^(NSString *errorStr) {
                [weakSelf.view makeToast:errorStr duration:1.0 position:CSToastPositionCenter];
            }];
        }break;
        case 1001:
        {/// 收藏
            isCare = !isCare;
            NSString *body = [NSString stringWithFormat:@"target_type=cook&doSubmit=1&target_id=%ld",(long)self.menuid];
            kSelfWeak;
            [[NetworkTool sharedNetworkTool]postMethodWithURL:KCollection body:body success:^(id json) {
                [collectionBtn setImage:[UIImage imageNamed:isCare==0?@"ic_top_collect_un":@"ic_top_collect_on"] forState:UIControlStateNormal];
                collectionBtn.selected = !collectionBtn.selected;
                NSInteger status  = [[json objectForKey:@"status"] integerValue];
                NSString *messageStr = [json objectForKey:@"message"];
                if (status== 1) {
                    [weakSelf.view makeToast:messageStr duration:1.0 position:CSToastPositionCenter];
                }
            } failure:^(NSString *errorStr) {
                [weakSelf.view makeToast:errorStr duration:1.0 position:CSToastPositionCenter];
            }];
        }break;
        default:
            break;
    }
}
#pragma mark -- 立即启动／预约启动／设置偏好
- (void)deviceAction:(UIButton *)button{
    if (button.tag==100) { //立即启动
        if (_cookListModel.tag_id==3) {
            [self.model.State setObject:@"降压粥" forKey:@"state"];
  
        }else if (_cookListModel.tag_id==4){
            [self.model.State setObject:@"降压汤" forKey:@"state"];

        }else{
            [self.model.State setObject:@"云菜谱" forKey:@"state"];

        }
        TJYCookDetailsEquipmentModel *equipmentModel= _equipmentDataSource[0];
        [self.model.State setObject:@"00" forKey:@"orderHour"];
        [self.model.State setObject:@"00" forKey:@"orderHourMin"];
        
        NSString *urlStr = [NSString stringWithFormat:@"%@%@",[self loadTitleAsc],equipmentModel.code];
        [self.model.State setObject:urlStr forKey:@"cloudMenu"];
        [self.model.State setObject:self.model.deviceName forKey:@"name"];
        [[ControllerHelper shareHelper] controllDevice:self.model];

    }else if (button.tag == 101){ //预约启动
                timePicker =[[TimePickerView alloc]initWithTitle:@"预约时间" delegate:self];
                timePicker.timeDisplayIn24=YES;
                timePicker.isOrderType=YES;
                timePicker.isSetTime=YES;
                timePicker.pickerStyle=PickerStyle_Time;
                //获取当前时间
                NSString *time=[NSUserDefaultInfos getCurrentDate];
                int selectHour=[time substringWithRange:NSMakeRange(11, 2)].intValue;
                int selectMin=[time substringWithRange:NSMakeRange(14, 2)].intValue/5+1;
                
                //55分到59分处理
                if (selectMin==12) {
                    selectHour++;
                    selectMin=0;
                }
                [timePicker.locatePicker selectRow:selectHour inComponent:0 animated:YES];
                [timePicker.locatePicker selectRow:selectMin inComponent:1 animated:YES];
                [timePicker showInView:self.view];
                [timePicker pickerView:timePicker.locatePicker didSelectRow:selectHour inComponent:0];
                [timePicker pickerView:timePicker.locatePicker didSelectRow:selectMin  inComponent:1];
    }
}
- (void)leftButtonAction{
    [self.navigationController popViewControllerAnimated:YES];
}
#pragma mark -- 监听点击状态栏返回顶部
- (void)coverWindowClick {
    [UIView animateWithDuration:0.5 animations:^{
        self.tableView.contentOffset =  CGPointMake(0, 0);
    }];
}
#pragma mark 收到信息回调
-(void)OnPipeData:(NSNotification *)noti{
    NSDictionary *dict = noti.object;
    DeviceEntity *device=[dict objectForKey:@"device"];
    NSData *recvData=[dict objectForKey:@"payload"];

    if (isOrder==YES) {
        self.model = orderModel;
    }
    if ([[device getMacAddressSimple]isEqualToString:self.model.mac]) {
        DeviceModel *model=[[DeviceModel alloc]init];
        
        model.deviceName=[DeviceHelper getDeviceName:device];
        model.isOnline=YES;
        model.deviceType=[DeviceHelper getDeviceTypeWithMac:[device getMacAddressSimple]];
        model.deviceID=[device getDeviceID];
        model.mac=[device getMacAddressSimple];
        model.State=[DeviceHelper getStateDicWithDevice:device Data:recvData];
        model.productID=device.productID;
        
        if ([[model.State objectForKey:@"state"]isEqualToString:@"云菜谱"] || [[model.State objectForKey:@"state"]isEqualToString:@"云功能"]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [NSUserDefaultInfos putKey:@"name" andValue:[model.State objectForKey:@"name"]];
                    [[ControllerHelper shareHelper] dismissProgressView];
                    
                    UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                    DeviceProgressViewController * deviceProgressVC = [mainStoryBoard instantiateViewControllerWithIdentifier:@"DeviceProgressViewController"];
                    deviceProgressVC.model = model;
                    deviceProgressVC.index = 1;
                    [self.navigationController pushViewController:deviceProgressVC animated:YES];
                });
            });
            
        }
    }
}
#pragma mark -- tableHeaderView
- (UIView *)tableViewHeaderView{
    _headerView = [[UIView alloc]initWithFrame:CGRectMake(0,0 , kScreenWidth,240*kScreenWidth/320 + 100)];
    _headerView.backgroundColor = [UIColor whiteColor];
    [_headerView addSubview:self.cycleScrollView];
    [_headerView addSubview:self.introductionView];
    return _headerView;
}

#pragma mark -- TableViewfooterView
- (UIView *)tableViewfooterView{
    
    UIView *footerView = InsertView(nil, CGRectMake(0, 0,kScreenWidth , 160), [UIColor bgColor_Gray]);
    UIView *whiteBgView = InsertView(footerView, CGRectMake(15, 15, kScreenWidth -30, 120), [UIColor bgColor_Gray]);
    NSArray *footerBtnTitleArray = @[@"立即启动",@"预约启动"];
    NSArray *colorArray = @[@"0xffc72f",@"0x81d570"];
    NSArray *footerBtnImgArray = @[@"ic_caipu_shebei",@"ic_caipu_time"];
    
    for (NSInteger i = 0; i < 2; i++) {
        StartDeviceButton *footerBtn = [[StartDeviceButton alloc]initWithFrame:CGRectMake( i * whiteBgView.width/2+(whiteBgView.width/2-80)/2, 10 ,80, 80) dict:footerBtnImgArray[i]];
        footerBtn.tag = 100+i;
        footerBtn.layer.cornerRadius =40;
        footerBtn.backgroundColor = [UIColor colorWithHexString:colorArray[i]];
        [footerBtn addTarget:self action:@selector(deviceAction:) forControlEvents:UIControlEventTouchUpInside];
        [whiteBgView addSubview:footerBtn];
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(footerBtn.left, footerBtn.bottom+5, footerBtn.width, 20)];
        titleLabel.text = footerBtnTitleArray[i];
        titleLabel.textAlignment  = NSTextAlignmentCenter;
        titleLabel.textColor = [UIColor grayColor];
        titleLabel.font = [UIFont systemFontOfSize:15];
        [whiteBgView addSubview:titleLabel];
    }
    return footerView;
}

#pragma mark 轮播图点击事件
-(void)cycleScrollViewDidClickActionWithIndex:(NSInteger)index{
    
    
}

#pragma  mark --  UITableViewDelegate,UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 5;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    switch (section) {
        case 0:
        {
            return kIsEmptyString(_cookListModel.abstract)? 0: 1 ;
        }break;
        case 1:
        {
            return _equipmentDataSource.count;
        }break;
        case 2:
        {
            return _ingredientDataSource.count;
        }break;
        case 3:
        {
            return _stepDataSource.count;
        }break;
        case 4:
        {
            return kIsEmptyString(_cookListModel.remarks) ? 0: 1;
        }break;
        default:
            break;
    }
    return 0;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    switch (indexPath.section) {
        case 0:
        {
            CGFloat statusHeight = [TJYMenuDetailsRemarksCell tableView:tableView rowHeightForObject:_cookListModel.abstract];
            return statusHeight>0? statusHeight + 16:0;
        }break;
        case 1:
        {
            return 80;
        }break;
        case 2:
        {
            return 40;
        }
        case 3:
        {/// 制作过程
            TJYCookSetpModel *stepModel  =_stepDataSource[indexPath.row];
            BOOL isFlay = [_stepDataSource count] - 1 == indexPath.row ? YES : NO;
            CGFloat cellHeight = [TJYCookStepCell returnRowHeightForObject:stepModel isScrollDown:isFlay];
            return cellHeight;
        }break;
        case 4:
        {// 小贴士动态高度
            CGFloat statusHeight = [TJYMenuDetailsRemarksCell tableView:tableView rowHeightForObject:_cookListModel.remarks];
            return statusHeight>0? statusHeight + 16:0;
        }break;
        default:
            break;
    }
    return 0;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    
    if (section==1&& self.introductionView.menuImg.hidden==YES) {
        return 0.1;
    }else if (section==0){
        return 0.1;
    }else if (section==4&&_cookListModel.remarks.length==0){
        return 0.1;
    }else{
        return 30;
    }
    return 0.01;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    if (section == 2) {
        return 40; // 用于显示热量
    }else{
        return 0.01;
    }
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIView *sectionHeaderView = InsertView(nil, CGRectMake(0, 0, kScreenWidth, 30), kBackgroundColor);
    UILabel *sectionTitle = InsertLabel(sectionHeaderView, CGRectMake(15,15/2, 200, 15), NSTextAlignmentLeft, @"", kFontSize(15), UIColorHex(0x666666), NO);
    switch (section) {
        case 1:
        {
            sectionTitle.text = self.introductionView.menuImg.hidden==YES?@"":@"适用设备";
        }break;
        case 2:
        {
            sectionTitle.text = @"所需食材";
        }break;
        case 3:
        {
            sectionTitle.text = @"制作步骤";
        }break;
        case 4:
        {
            sectionTitle.text = _cookListModel.remarks.length==0?@"":@"小贴士";
        }break;
        default:
            break;
    }
    return sectionHeaderView;
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    if (section == 2) {
        UIView *sectionFooterView = InsertView(nil, CGRectMake(0, 0, kScreenWidth, 40), [UIColor whiteColor]);
        InsertView(sectionFooterView, CGRectMake(0,0, kScreenWidth, 0.5), kLineColor);
        InsertLabel(sectionFooterView, CGRectMake(15,10 , 100, 20), NSTextAlignmentLeft, @"热量", kFontSize(13), UIColorHex(0xff9d38), NO);
        UILabel *heatLabel = InsertLabel(sectionFooterView, CGRectMake(kScreenWidth - 160,10 , 150, 20), NSTextAlignmentRight, @"热量", kFontSize(13), UIColorHex(0xff9d38), NO);
        heatLabel.text = [NSString stringWithFormat:@"≈%ld千卡",_caloriesSum];
        return sectionFooterView;
    }else{
        return nil;
    }
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *equipmentCellIdentifier = @"equipmentCell";
    static NSString *ingredientCellIdentifier = @"ingredientCell";
    static NSString *StepCellIdentifier = @"CookStepCell";
    static NSString *remarksCellIdentifier = @"remarksCell";
    switch (indexPath.section) {
        case 0:
        {
            TJYMenuDetailsRemarksCell *remarksCell = [[TJYMenuDetailsRemarksCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:remarksCellIdentifier];
            remarksCell.selectionStyle = UITableViewCellSelectionStyleNone;
            [remarksCell cellInitWithData:_cookListModel.abstract];
            return remarksCell;
        }break;
        case 1:
        {
            TJYApplicableEquipmentCell *equipmentCell = [tableView dequeueReusableCellWithIdentifier:equipmentCellIdentifier];
            if (!equipmentCell) {
                equipmentCell = [[TJYApplicableEquipmentCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:equipmentCellIdentifier];
            }
            [equipmentCell cellWithData:_equipmentDataSource[indexPath.row]];
            equipmentCell.selectionStyle = UITableViewCellSelectionStyleNone;
            return equipmentCell;
        }break;
        case 2:
        {
            TJYIngredientCell *ingredientCell = [tableView dequeueReusableCellWithIdentifier:ingredientCellIdentifier];
            if (!ingredientCell) {
                ingredientCell = [[TJYIngredientCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ingredientCellIdentifier];
            }
            [ingredientCell cellInitWithData:_ingredientDataSource[indexPath.row]];
            ingredientCell.selectionStyle = UITableViewCellSelectionStyleNone;
            return ingredientCell;
        }
        case 3:
        {
            TJYCookStepCell *stepCell = [tableView dequeueReusableCellWithIdentifier:StepCellIdentifier];
            if (!stepCell) {
                stepCell = [[TJYCookStepCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:StepCellIdentifier];
            }
            stepCell.selectionStyle = UITableViewCellSelectionStyleNone;
            stepCell.titleLabel.text = [NSString stringWithFormat:@"%ld",indexPath.row+1];
            [stepCell cellInitWithData:_stepDataSource[indexPath.row]];
            return stepCell;
        }break;
        case 4:
        {
            TJYMenuDetailsRemarksCell *remarksCell = [[TJYMenuDetailsRemarksCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:remarksCellIdentifier];
            remarksCell.selectionStyle = UITableViewCellSelectionStyleNone;
            [remarksCell cellInitWithData:_cookListModel.remarks];
            return remarksCell;
        }break;
        default:
            break;
    }
    UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (scrollView.contentOffset.y > 80) {
        
        [UIView animateWithDuration:0.5 delay:0.3 options:UIViewAnimationOptionCurveEaseIn animations:^{
            // 导航条加颜色（不再透明）
            _navigationView.backgroundColor = kSystemColor;
            // 滑动范围下移动至导航条下从64开始（确保分区头视图贴着导航条下边缘显示）
            scrollView.contentInset =UIEdgeInsetsMake(64,0, 0,0);
            _menuNavImg.hidden = NO;
            _menuNavLabel.hidden = NO;
        } completion:^(BOOL finished) {
            
        }];
        
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            //导航条透明
            _navigationView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.01];
            _menuNavImg.hidden = YES;
            _menuNavLabel.hidden = YES;
            //滑动范围熊0开始
            scrollView.contentInset =UIEdgeInsetsMake(0,0, 0,0);
            //             NSLog( @"不透明");
        }];
    }
}

- (UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth, kAllHeight) style:UITableViewStyleGrouped];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = kBackgroundColor;
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.tableHeaderView = [self tableViewHeaderView];
        _tableView.tableFooterView = [self tableViewfooterView];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return _tableView;
}
/* Banner视图 */
-(SDCycleScrollView *)cycleScrollView{
    if (_cycleScrollView==nil) {
        _cycleScrollView=[SDCycleScrollView cycleScrollViewWithFrame:CGRectMake(0, 0, kScreenWidth, 240 *(kScreenWidth/320)) delegate:self placeholderImage:[UIImage imageNamed:@"img_caipu_nor"]];
        _cycleScrollView.pageControlAliment = SDCycleScrollViewPageContolAlimentCenter;
        _cycleScrollView.currentPageDotColor = kSystemColor; // 自定义分页控件小圆标颜色
    }
    return _cycleScrollView;
}
- (TJYMenuDetailIntroductionView *)introductionView{
    if (!_introductionView) {
        _introductionView = [[TJYMenuDetailIntroductionView alloc]initWithFrame:CGRectMake(0, _headerView.height - 100, kScreenWidth, 100)];
    }
    return _introductionView;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
