//
//  NewPropertyViewController.m
//  findMe
//
//  Created by Brian Allen on 2014-10-11.
//  Copyright (c) 2014 Avial Ltd. All rights reserved.
//

#import "NewPropertyViewController.h"
#import "MBProgressHUD.h"
#import <Parse/Parse.h>
#import "UIView+Animation.h"
@interface NewPropertyViewController ()

@end

@implementation NewPropertyViewController
@synthesize userName;
@synthesize answersListTableView;

NSMutableArray *answersListArray;
NSMutableArray *acceptableAnswers;
NSString *questionText;
MBProgressHUD *HUD;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.answersListTableView.delegate = self;
    self.answersListTableView.dataSource = self;
    
    answersListArray = [[NSMutableArray alloc] init];
    acceptableAnswers = [[NSMutableArray alloc] init];
    
    self.answerTextField.delegate = self;
    self.questionTextField.delegate = self;
    
    self.hashtagButtons = [[NSMutableArray alloc] init];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
     tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
    
    self.firstStepLabel = [[UILabel alloc] initWithFrame:CGRectMake(15,20,70,70)];
    self.firstStepLabel.layer.cornerRadius = 10;
    self.firstStepLabel.textAlignment = NSTextAlignmentCenter;
    self.firstStepLabel.layer.borderWidth = 5;
    self.firstStepLabel.layer.borderColor = [UIColor whiteColor].CGColor;
    self.firstStepLabel.textColor = [UIColor whiteColor];
    
    self.firstStepLabel.layer.backgroundColor = [UIColor clearColor].CGColor;
    self.firstStepLabel.font = [UIFont fontWithName:@"Futura-Medium" size:40];
    self.firstStepLabel.text = @"1";
    self.firstStepLabel.alpha = 0;
    
    [self.view addSubview:self.firstStepLabel];
    
    self.secondStepLabel = [[UILabel alloc] initWithFrame:CGRectMake(15,20,70,70)];
    self.secondStepLabel.layer.cornerRadius = 10;
    self.secondStepLabel.textAlignment = NSTextAlignmentCenter;
    self.secondStepLabel.layer.borderWidth = 5;
    self.secondStepLabel.layer.borderColor = [UIColor whiteColor].CGColor;
    self.secondStepLabel.textColor = [UIColor whiteColor];
    
    self.secondStepLabel.layer.backgroundColor = [UIColor clearColor].CGColor;
    self.secondStepLabel.font = [UIFont fontWithName:@"Futura-Medium" size:40];
    self.secondStepLabel.text = @"2";
    
    self.thirdStepLabel = [[UILabel alloc] initWithFrame:CGRectMake(15,20,70,70)];
    self.thirdStepLabel.layer.cornerRadius = 10;
    self.thirdStepLabel.textAlignment = NSTextAlignmentCenter;
    self.thirdStepLabel.layer.borderWidth = 5;
    self.thirdStepLabel.layer.borderColor = [UIColor whiteColor].CGColor;
    self.thirdStepLabel.textColor = [UIColor whiteColor];
    
    self.thirdStepLabel.layer.backgroundColor = [UIColor clearColor].CGColor;
    self.thirdStepLabel.font = [UIFont fontWithName:@"Futura-Medium" size:40];
    self.thirdStepLabel.text = @"3";
    
    self.step1SideLabel = [[UILabel alloc] initWithFrame:CGRectMake(280,10,30,30)];
    self.step1SideLabel.layer.cornerRadius = 2;
    self.step1SideLabel.textAlignment = NSTextAlignmentCenter;
    self.step1SideLabel.layer.borderWidth = 2;
    self.step1SideLabel.layer.borderColor = [UIColor grayColor].CGColor;
    self.step1SideLabel.textColor = [UIColor grayColor];
    self.step1SideLabel.alpha = 0.5;
    
    self.step1SideLabel.layer.backgroundColor = [UIColor clearColor].CGColor;
    self.step1SideLabel.font = [UIFont fontWithName:@"Futura-Medium" size:25];
    self.step1SideLabel.text = @"1";
    
    [self.view addSubview:self.step1SideLabel];
    
   self.step2SideLabel = [[UILabel alloc] initWithFrame:CGRectMake(280,42,30,30)];
    self.step2SideLabel.layer.cornerRadius = 2;
    self.step2SideLabel.textAlignment = NSTextAlignmentCenter;
   self.step2SideLabel.layer.borderWidth = 2;
    self.step2SideLabel.layer.borderColor = [UIColor grayColor].CGColor;
    self.step2SideLabel.textColor = [UIColor grayColor];
    self.step2SideLabel.alpha = 0.5;
    
    self.step2SideLabel.layer.backgroundColor = [UIColor clearColor].CGColor;
    self.step2SideLabel.font = [UIFont fontWithName:@"Futura-Medium" size:25];
    self.step2SideLabel.text = @"2";
    
    [self.view addSubview:self.step2SideLabel];
    
    self.step3SideLabel = [[UILabel alloc] initWithFrame:CGRectMake(280,74,30,30)];
    self.step3SideLabel.layer.cornerRadius = 2;
    self.step3SideLabel.textAlignment = NSTextAlignmentCenter;
    self.step3SideLabel.layer.borderWidth = 2;
    self.step3SideLabel.layer.borderColor = [UIColor grayColor].CGColor;
    self.step3SideLabel.textColor = [UIColor grayColor];
    self.step3SideLabel.alpha = 0.5;
    
    self.step3SideLabel.layer.backgroundColor = [UIColor clearColor].CGColor;
    self.step3SideLabel.font = [UIFont fontWithName:@"Futura-Medium" size:25];
    self.step3SideLabel.text = @"3";
    
    [self.view addSubview:self.step3SideLabel];
    
    
    self.createQuestionLabel = [[UILabel alloc] initWithFrame:CGRectMake(95,20,200,70)];
    self.createQuestionLabel.textColor = [UIColor whiteColor];
    self.createQuestionLabel.alpha = 0;
    
    self.createQuestionLabel.text = @"Create A New Question";
    self.createQuestionLabel.numberOfLines = 2;
    
    self.createQuestionLabel.font = [UIFont fontWithName:@"Futura-Medium" size:25];
    
    [self.view addSubview:self.createQuestionLabel];
    
    self.addAnswersLabel = [[UILabel alloc] initWithFrame:CGRectMake(95,20,200,70)];
    self.addAnswersLabel.textColor = [UIColor whiteColor];
    self.addAnswersLabel.text = @"Add Some Real & Fake Answers";
    self.addAnswersLabel.numberOfLines = 2;
    self.addAnswersLabel.font = [UIFont fontWithName:@"Futura-Medium" size:25];
    
    //self.addAnswerButton = [[UIButton alloc] initWithFrame:CGRectMake(295,20,30,30)];
    //[self.addAnswerButton setTitle:@"Add" forState:UIControlStateNormal];
    //self.addAnswerButt
    self.addNewAnswerButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.addNewAnswerButton.layer.cornerRadius = 5.0f;
    self.addNewAnswerButton.layer.borderWidth = 2.0f;
    
    
    self.answerTextField.alpha = 0;
    self.answersListTableView.alpha = 0;
    self.step1Label.alpha = 0;
    self.step2Label.alpha = 0;
    self.step3Label.alpha = 0;
    self.addNewPropertyButton.alpha = 0;
    self.addNewAnswerButton.alpha = 0;
    
    
   self.recentQuestionsTitle = [[UILabel alloc] initWithFrame:CGRectMake(5,250,310,40)];
    self.recentQuestionsTitle.text = @"Recently Submitted Questions";
    self.recentQuestionsTitle.textColor = [UIColor whiteColor];
    
    self.recentQuestionsTitle.font = [UIFont fontWithName:@"Futura-Medium" size:22];
    self.recentQuestionsTitle.textAlignment = NSTextAlignmentCenter;
    self.recentQuestionsTitle.layer.borderWidth = 2.0f;
    self.recentQuestionsTitle.layer.borderColor = [UIColor whiteColor].CGColor;
    self.recentQuestionsTitle.layer.cornerRadius = 4.0f;
    
    [self.view addSubview:self.recentQuestionsTitle];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setItemSize:CGSizeMake(100, 40)];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    
    //[self.recentQuestionsCollectionView setCollectionViewLayout:flowLayout];
    
    self.recentQuestionsCollectionView.frame= CGRectMake(0,200,320,400);
    self.recentQuestionsCollectionView.alpha = 0;
    
    //= [[UICollectionView alloc] initWithFrame: collectionViewLayout:flowLayout];
    
    //[self.view addSubview:self.recentQuestionsCollectionView];
    
    //CGRectMake(0,200,320,400)];
    //populate example array of recent questions
    self.recentQuestions = [NSArray arrayWithObjects:@"What was I wearing?",@"What is our special inside joke?",@"Who do we both hate?",nil];
    
    [self layouthashtags:self.recentQuestions];
    
    
    
}

- (void) layouthashtags:(NSArray *) hashes
{
    
    float ypos;
    float xpos;
    float btnmargin;
    float xwidth;
    float xmargin;
    float maxheight;
    int maxhashcount = 10;
    
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        ypos = 300;
        xpos = 10;
        btnmargin = 5;
        xwidth = 300;
        xmargin = 5;
        maxheight = 350;
        
        
    }
    else
    {
        ypos = 250;
        xpos = 10;
        btnmargin = 10;
        xwidth = 600;
        xmargin = 10;
        maxheight = 800;
    }
    
    int tag = 0;
    
    float heightsofar;
    float heightadaptor;
    
    
    
    if (hashes.count ==0)
    {
        
        UILabel *NoStuff = [[UILabel alloc] initWithFrame:CGRectMake(10,150,220,50)];
        NoStuff.text = @"No Categories Retrieved";
        NoStuff.tag = 1;
        
        [self.view addSubview:NoStuff];
        
    }
    
    for (NSString *hash in hashes)
    {
        //NSNumber *hshnum = [hash objectForKey:@"hashcount"];
        
        NSInteger hshint = 10;
        
        if(hshint>=maxhashcount)
        {
            maxhashcount = hshint;
        }
    }
    
    
    for (NSString *hash in hashes)
    {
       
        
        NSInteger hshint = 10;
        
        CGSize btnsize = [self sizeForTag:hshint];
        
        CGRect btnframe = CGRectMake(xpos, ypos, btnsize.width, btnsize.height);
        
        
        
        //  NSLog(@"new cell left: %f", btnframe.origin.x);
        // NSLog(@"new cell top: %f", btnframe.origin.y);
        // NSLog(@"new cell width: %f", btnframe.size.width);
        NSLog(@"new cell height: %f", btnframe.size.height);
        
        
        UIButton *hashbutton = [[UIButton alloc] initWithFrame:btnframe];
        
        NSString *btnTitle = hash;
        //NSString *hshnumtext = [hshnum stringValue];
        //NSString *paren = @" (";
        //NSString *parenend = @")";
        
        //NSString *btnstring1 = [btnTitle stringByAppendingString:paren];
        //NSString *btnstring2 = [hshnumtext stringByAppendingString:parenend];
        
        NSString *fullbtnstring = hash;
        //hashbutton.titleLabel.numberOfLines = 1;
        
        UIFont *sysfont= [UIFont systemFontOfSize:10];
        NSString *familyName = sysfont.familyName;
        
        UIFont *fontforbtn = [self findAdaptiveFontWithName:familyName forbtnSize:btnsize withMinimumSize:10];
        
        CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
        CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
        CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
        UIColor *tcolor = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
        
        [hashbutton setTitleColor:tcolor forState:UIControlStateNormal];
        
        [hashbutton.titleLabel setFont:fontforbtn];
        
        hashbutton.titleLabel.adjustsFontSizeToFitWidth = TRUE;
        
        //hashbutton.titleLabel.lineBreakMode = NSLineBreakByClipping;
        
        [hashbutton setTitle:fullbtnstring forState:UIControlStateNormal];
        
        [hashbutton sizeToFit];
        
        [hashbutton setBackgroundColor: [UIColor whiteColor]];
        
        
        //CGRect lblframe = CGRectMake(btnframe.origin.x+lblxmargin + btnsize.width,btnframe.origin.y,25,btnsize.height);
        
        
        //UILabel *hashcount = [[UILabel alloc] initWithFrame:lblframe];
        
        
        
        
        //hashcount.text =hshnumtext;
        
        // hashcount.font = fontforbtn;
        //hashcount.textColor = tcolor;
        
        
        hashbutton.tag = tag;
        
        hashbutton.layer.cornerRadius = 5.0f;
        hashbutton.layer.borderWidth = 2.0f;
        
        
        [hashbutton addTarget:self action:@selector(hashButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
        
        // hashcount.tag = 1;
        
        
        hashbutton.layer.cornerRadius = 10; // this value vary as per your desire
        hashbutton.clipsToBounds = YES;
        
        [self.view addSubview:hashbutton];
        [self.hashtagButtons addObject:hashbutton];
        
        //[self.view addSubview:hashcount];
        
        //NSLog(@"new btn left: %f", hashbutton.frame.origin.x);
        // NSLog(@"new btn top: %f", hashbutton.frame.origin.y);
        // NSLog(@"new btnwidth: %f", hashbutton.frame.size.width);
        NSLog(@"new btn height: %f", hashbutton.frame.size.height);
        
        //set height adaptor if it's the first cell or if it's the first new cell in a row
        if(tag==1)
        {
            heightadaptor = hashbutton.frame.size.height;
            heightsofar = heightadaptor;
        }
        
        
        if(xpos==10)
        {
            //this cell becomes the new height adaptor
            heightadaptor = hashbutton.frame.size.height;
            NSLog(@"%f",heightadaptor);
            
            heightsofar = heightsofar+heightadaptor;
            
            
        }
        
        
        xpos = xpos+ hashbutton.frame.size.width + xmargin;
        
        if((xpos +hashbutton.frame.size.width)>xwidth)
        {
            xpos = 10;
            //change this to add to y pos from the first time item for each row since it's the biggest.
            ypos = ypos + heightadaptor + btnmargin;
            if (heightsofar>maxheight)
            {
                return;
            }
            
        }
        else
        {
            //not first of row, dont reset height
            
        }
        
        
        tag = tag+1;
        
    }
}

-(void)hashButtonTouched:(id)sender
{
    UIButton *hashButton = (UIButton *)sender;
    //hashbuttonTag
    NSInteger selectedTag = hashButton.tag;
    
    NSString *selectedQuestion = [self.recentQuestions objectAtIndex:selectedTag];
    self.questionTextField.text = selectedQuestion;
    self.confirmQuestionButton.alpha = 1;
    
}

-(UIFont *)findAdaptiveFontWithName:(NSString *)fontName forbtnSize:(CGSize)labelSize withMinimumSize:(NSInteger)minSize
{
    UIFont *tempFont = nil;
    NSString *testString = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    
    NSInteger tempMin = minSize;
    NSInteger tempMax = 256;
    NSInteger mid = 0;
    NSInteger difference = 0;
    
    while (tempMin <= tempMax) {
        @autoreleasepool {
            mid = tempMin + (tempMax - tempMin) / 2;
            tempFont = [UIFont fontWithName:fontName size:mid];
            CGSize size = [testString sizeWithAttributes:@{NSFontAttributeName:tempFont}];
            difference = labelSize.height - size.height;
            
            if (mid == tempMin || mid == tempMax) {
                if (difference < 0) {
                    return [UIFont fontWithName:fontName size:(mid - 1)];
                }
                
                return [UIFont fontWithName:fontName size:mid];
            }
            
            if (difference < 0) {
                tempMax = mid - 1;
            } else if (difference > 0) {
                tempMin = mid + 1;
            } else {
                return [UIFont fontWithName:fontName size:mid];
            }
        }
    }
    
    return [UIFont fontWithName:fontName size:mid];
}


//function needs context information on what the biggest hashtag is.
- (CGSize) sizeForTag:(NSInteger) tagcount
{
    float baseheight = 20;
    float basewidth = 93.75;
    
    
    // NSLog(@"heres the tagcount: %i",tagcount);
    
    float tcount = (float)tagcount;
    float maxhcount = (float)10;
    
    float sizeratio = tcount/maxhcount;
    
    float newheight = baseheight*sizeratio;
    float newwidth = basewidth;
    
    CGSize sizereturn = CGSizeMake(newwidth, newheight);
    
    return sizereturn;
    
}



-(void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    
    [HUD hide:NO];
    
}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(IBAction)addAnswerToList:(id)sender
{
    NSString *newAnswer = self.answerTextField.text;
    
    [answersListArray addObject:newAnswer];
    
    if(self.checkMark2.alpha==0)
    {
        self.checkMark2.alpha =1;
        
    }
    
    [self.answersListTableView reloadData];
    
}
-(IBAction)addNewProperty:(id)sender
{
    //add the question text, acceptable answers, and options array as a new case item on the casedetails screen.
    
    //add 1 to the value of each acceptableAnswerIndex to match the backend which starts from index 1.
    NSMutableArray *acceptableAnswersKeyPairValues = [[NSMutableArray alloc] init];
    
    for (NSNumber *ans in acceptableAnswers)
    {
        
        int num = [ans intValue];
        num = num+1;
        
        NSNumber *newans = [NSNumber numberWithInteger:num];
        NSString *newansString = [newans stringValue];
        
        //add the acceptableAnswers in the format of NSMutableDictionary's with the key a
        NSMutableDictionary *answerKeyPair = [[NSMutableDictionary alloc] init];
        [answerKeyPair setObject:newansString forKey:@"a"];
        [acceptableAnswersKeyPairValues addObject:answerKeyPair];
        
    }
    
    NSString *optionsList = [[answersListArray copy] componentsJoinedByString:@";"];
    
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    // Set determinate mode
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Updating With Your New Property";
    [HUD show:YES];
    
    
    [self.delegate recieveData:optionsList AcceptableAnswersList:[acceptableAnswersKeyPairValues copy]QuestionText:questionText];

}

#pragma mark UITableViewDelegateMethods
-(int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (int)[answersListArray count];
    
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"answerCell" forIndexPath:indexPath];
    
    UILabel *answerLabel = (UILabel *)[cell viewWithTag:1];
    answerLabel.text = [answersListArray objectAtIndex:indexPath.row];
    
    //check to see if the answer should be highlighted
    cell.backgroundColor = [UIColor clearColor];
    
    for (NSNumber *eachAns in acceptableAnswers)
    {
        int ansInt = [eachAns integerValue];
        if(ansInt==indexPath.row)
        {
            //highlight this cell in the table as one of the selected answers
            cell.backgroundColor = [UIColor greenColor];
            
        }
        
    }

    
    return cell;
}

- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    // Add your Colour.
    //UITableViewCell *cell = (UITableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    //[cell setTintColor:[UIColor clearColor]];
    //[cell setBackgroundColor:[UIColor clearColor]];
    
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if(cell.backgroundColor==[UIColor greenColor])
    {
        //remove this answer from the list.
        NSNumber *ansToRemove;
        for (NSNumber *eachAns in acceptableAnswers)
        {
            int ansInt = [eachAns integerValue];
            if(ansInt==indexPath.row)
            {
                ansToRemove = eachAns;
            
                cell.backgroundColor = [UIColor whiteColor];
            }
        }
        [acceptableAnswers removeObject:ansToRemove];
    }
    else
        
    {
        NSNumber *newAns = [NSNumber numberWithInteger:indexPath.row];
        [acceptableAnswers addObject:newAns];
        cell.backgroundColor = [UIColor greenColor];
        
        
        if(self.checkMark3.alpha==0)
        {
            self.checkMark3.alpha =1;
            self.addNewPropertyButton.enabled = 1;
            
        }

    }

}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
     self.confirmQuestionButton.alpha = 1;
    
    [self animateTextField:textField up:YES];
}


- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self animateTextField:textField up:NO];
    if(textField.tag ==44)
    {
        //set the question text.
        questionText = textField.text;
        //self.checkMark1.alpha = 1;
        
    }
    
}


- (void) animateTextField: (UITextField*) textField up: (BOOL) up
{
    int animatedDistance;
    int moveUpValue = textField.frame.origin.y+ textField.frame.size.height;
    UIInterfaceOrientation orientation =
    [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait ||
        orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        
        animatedDistance = 216-(460-moveUpValue-5);
    }
    else
    {
        animatedDistance = 162-(320-moveUpValue-5);
    }
    
    if(animatedDistance>0)
    {
        const int movementDistance = animatedDistance;
        const float movementDuration = 0.3f;
        int movement = (up ? -movementDistance : movementDistance);
        [UIView beginAnimations: nil context: nil];
        [UIView setAnimationBeginsFromCurrentState: YES];
        [UIView setAnimationDuration: movementDuration];
        self.view.frame = CGRectOffset(self.view.frame, 0, movement);
        [UIView commitAnimations];
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    //put the string of the text field onto a label now in the same cell
    //put -100 so it doesn't interfere with the uilabel tag of 3 in every cell
    if(textField.tag ==44)
    {
        //set the question text.
       // questionText = textField.text;
       // self.checkMark1.alpha = 1;
        
    }
    
    if(textField.tag==45)
    {
        
    }
    
    [textField resignFirstResponder];
    
    return YES;
}

-(void)dismissKeyboard {
    
    [self.view endEditing:YES];
}


-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [self.recentQuestions count]/3;
    
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return 3;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"cvCell";
    
    //CVCell *cell = (CVCell *)[collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    //NSMutableArray *data = [self.recentQuestions objectAtIndex:indexPath.section];
    
    NSString *cellData = [self.recentQuestions objectAtIndex:indexPath.row];
    
    UILabel *cellLabel;
    
    cellLabel = (UILabel *)[cell viewWithTag:1];
    
    if(cellLabel ==nil)
    {
        cellLabel = [[UILabel alloc] initWithFrame:cell.bounds];
        cellLabel.tag = 1;
        [cell addSubview:cellLabel];
        
    }
    
    [cellLabel setText:cellData];
    
    
    return cell;
    
}

-(IBAction)confirmQuestion
{
    questionText = self.questionTextField.text;
    
    //animate step1 up
    
    self.confirmQuestionButton.alpha = 0;
    
    self.step1SideLabel.layer.borderColor = [UIColor greenColor].CGColor;
    self.step1SideLabel.textColor = [UIColor greenColor];
    
    //animate these labels left and grow/add a new view for step2
    [self.firstStepLabel SlideOffLeft:self.firstStepLabel duration:1.0f];
    [self.createQuestionLabel SlideOffLeft:self.createQuestionLabel duration:1.0f];
    [self.recentQuestionsTitle SlideOffLeft:self.recentQuestionsTitle duration:1.0f];
    
    for(UIButton *hashBtn in self.hashtagButtons)
    {
        [hashBtn SlideOffLeft:hashBtn duration:1.0f];
        
    }
    
    [self.view BounceAddTheView:self.secondStepLabel];
    [self.view BounceAddTheView:self.addAnswersLabel];
    [self.view BounceAddTheView:self.addNewAnswerButton];
    
    self.answersListTableView.alpha = 1;
    
    
}




@end
