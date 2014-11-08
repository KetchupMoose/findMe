//
//  newCaseViewController.m
//  findMe
//
//  Created by Brian Allen on 2014-11-07.
//  Copyright (c) 2014 Avial Ltd. All rights reserved.
//

#import "newCaseViewController.h"
#import <Parse/Parse.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIImageView+UIActivityIndicatorForSDWebImage.h"
#import "UIImageView+Scaling.h"

@interface newCaseViewController ()

@end

@implementation newCaseViewController

NSArray *CaseOptionImages;
NSArray *templatePickerChoices;
NSMutableArray *templatePickerParentChoices;
NSMutableArray *templatePickerActiveChoices;

@synthesize CaseOptionsCollectionView;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //populate the URL's of images from parse.
    [self queryForTemplates];
    
    CaseOptionsCollectionView.dataSource = self;
    CaseOptionsCollectionView.delegate = self;
    
    [CaseOptionsCollectionView reloadData];
    
    
}

-(void) queryForTemplates
{
    //retrieve the five parent templatePickerChoices from Parse
    //templatePickerChoices =
    PFQuery *templateQuery = [PFQuery queryWithClassName:@"Templates"];
    
    [templateQuery whereKey:@"laiso" equalTo:@"EN"];
    
    
    templatePickerChoices = [templateQuery findObjects];
    templatePickerParentChoices = [[NSMutableArray alloc] init];
    
    for(PFObject *templateObject in templatePickerChoices)
    {
        if([templateObject objectForKey:@"parenttemplateid"]==nil)
        {
            [templatePickerParentChoices addObject:templateObject];
            
            
        }
    }

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
    return templatePickerParentChoices.count;
    
}



- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"caseOptionCell";
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    UIImageView *caseImageView= (UIImageView *)[cell viewWithTag:100];
    
    PFObject *templateObject = [templatePickerParentChoices objectAtIndex:indexPath.row];
    
    NSString *imgURL = [templateObject objectForKey:@"imageURL"];
    UIActivityIndicatorViewStyle activityStyle = UIActivityIndicatorViewStyleGray;
    
    
    [caseImageView setImageWithURL:[NSURL URLWithString:imgURL] usingActivityIndicatorStyle:(UIActivityIndicatorViewStyle)activityStyle];
    
    UILabel *descrLabel = (UILabel *) [cell viewWithTag:101];
    
    descrLabel.text = [templateObject objectForKey:@"description"];
    
    descrLabel.font = [UIFont systemFontOfSize:10];
    
    
    //caseImageView.image = [UIImage imageNamed:[recipeImages objectAtIndex:indexPath.row]];
    
    return cell;
}



@end
