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
#import "UIView+Animation.h"

@interface newCaseViewController ()

@end

@implementation newCaseViewController

NSArray *CaseOptionImages;
NSArray *templatePickerChoices;
NSMutableArray *templatePickerParentChoices;
NSMutableArray *templatePickerActiveChoices;
int pickedParentTemplateIndex;

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
    
    //check to see if a button is already created, if not, create a button overlayed on top of the UIImageView.  This button when tapped will activate the next step for the index of its displayed template.
    
    UIButton *templateChooseButton = (UIButton *)[cell viewWithTag:indexPath.row+1];
    
    if(templateChooseButton ==nil)
    {
        UIButton *templateChooseButton = [[UIButton alloc] initWithFrame:caseImageView.bounds];
        
        templateChooseButton.tag = indexPath.row+1;
        
        [templateChooseButton addTarget:self action:@selector(parentTemplatePicked:) forControlEvents:UIControlEventTouchUpInside];
        
        [cell addSubview:templateChooseButton];
        
        
    }
    
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

-(void) parentTemplatePicked:(UIButton *)sender
{
    int btnTag = sender.tag;
    
    //select the next template display based on this button.

    NSLog(@"%i",btnTag);
    
    pickedParentTemplateIndex = btnTag -1;
    
    //remove all the templatePicker Parent Views With An Interesting Animation
    [self removeTemplatePickerParentViews];
    
}

-(void) removeTemplatePickerParentViews
{
    int j=-0;
    for (UICollectionViewCell *templateCell in [CaseOptionsCollectionView visibleCells])
    {
        j=j+1;
        
        if(j==[[CaseOptionsCollectionView visibleCells] count])
        {
            [templateCell BounceViewThenFadeAlpha:templateCell shouldRemoveParentView:@"yes"];
        }
        else
        {
           [templateCell BounceViewThenFadeAlpha:templateCell shouldRemoveParentView:@"no"];
        }
        
        
    }
    //[CaseOptionsCollectionView removeFromSuperview];
    
}

@end
