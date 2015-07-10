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
UIColor *colorForHighlights;

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
    
    self.answersListTableView.backgroundColor = [UIColor clearColor];
    
    self.questionTextView = [[UITextView alloc] initWithFrame:self.questionTextField.frame];
    self.questionTextView.delegate = self;
    self.questionTextView.tag = 45;
    
    colorForHighlights = [UIColor colorWithRed:41/255.0f green:188.0f/255.0f blue:243.0f/255.0f alpha:1];
    
    [self.view addSubview:self.questionTextView];
    self.questionTextView.backgroundColor = [UIColor whiteColor];
    self.questionTextView.font =[UIFont fontWithName:@"Futura-Medium" size:15];
    self.questionTextField.font = [UIFont fontWithName:@"Futura-Medium" size:15];
    self.questionTextField.alpha = 0;
    
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
    self.firstStepLabel.alpha = 1;
    
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
    self.createQuestionLabel.alpha = 1;
    
    self.createQuestionLabel.text = @"Create A New Question";
    self.createQuestionLabel.numberOfLines = 2;
    
    self.createQuestionLabel.font = [UIFont fontWithName:@"Futura-Medium" size:25];
    
    [self.view addSubview:self.createQuestionLabel];
    
    self.addAnswersLabel = [[UILabel alloc] initWithFrame:CGRectMake(95,20,200,70)];
    self.addAnswersLabel.textColor = [UIColor whiteColor];
    self.addAnswersLabel.text = @"Add Some Real & Fake Answers";
    self.addAnswersLabel.numberOfLines = 2;
    self.addAnswersLabel.font = [UIFont fontWithName:@"Futura-Medium" size:25];
    
    self.confirmAnswersLabel = [[UILabel alloc] initWithFrame:CGRectMake(95,20,200,70)];
    self.confirmAnswersLabel.textColor = [UIColor whiteColor];
    self.confirmAnswersLabel.text = @"Select Responses You'll Accept";
    self.confirmAnswersLabel.numberOfLines = 2;
    self.confirmAnswersLabel.font = [UIFont fontWithName:@"Futura-Medium" size:23];
    
    //self.addAnswerButton = [[UIButton alloc] initWithFrame:CGRectMake(295,20,30,30)];
    //[self.addAnswerButton setTitle:@"Add" forState:UIControlStateNormal];
    //self.addAnswerButt
    self.addNewAnswerButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.addNewAnswerButton.layer.cornerRadius = 5.0f;
    self.addNewAnswerButton.layer.borderWidth = 2.0f;
    
    self.confirmAnswersButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.confirmAnswersButton.layer.cornerRadius = 5.0f;
    self.confirmAnswersButton.layer.borderWidth = 2.0f;
    self.confirmAnswersButton.alpha = 0;
    
    self.addNewPropertyButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.addNewPropertyButton.layer.cornerRadius = 5.0f;
    self.addNewPropertyButton.layer.borderWidth = 2.0f;
    self.addNewPropertyButton.alpha = 0;
    
    self.editButton.layer.borderColor =[ UIColor whiteColor].CGColor;
    self.editButton.layer.cornerRadius = 5.0f;
    self.editButton.layer.borderWidth = 2.0f;
    self.editButton.alpha = 0;
    
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
    
    self.addNewPropertyButton.enabled = 1;
    
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
    float heightadaptor = 0.0;
    
    
    
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
            maxhashcount = (int)hshint;
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
        
        //NSString *btnTitle = hash;
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
    self.questionTextView.text = selectedQuestion;
    questionText = selectedQuestion;
    
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
    NSString *rawString = [self.answerTextField text];
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *trimmed = [rawString stringByTrimmingCharactersInSet:whitespace];
    if ([trimmed length] == 0) {
        // Text was empty or only whitespace.
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Answer Error", nil) message:@"Answer Must Not Be Blank" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
        return;
    }
    
    NSString *newAnswer = self.answerTextField.text;
    
    [answersListArray addObject:newAnswer];
    
    if(self.checkMark2.alpha==0)
    {
        //self.checkMark2.alpha =1;
        
    }
    
    [self.answersListTableView reloadData];
    
}
-(IBAction)addNewProperty:(id)sender
{
    //add the question text, acceptable answers, and options array as a new case item on the casedetails screen.
    
    //add 1 to the value of each acceptableAnswerIndex to match the backend which starts from index 1.
    NSMutableArray *acceptableAnswersKeyPairValues = [[NSMutableArray alloc] init];
    
    if(acceptableAnswers.count ==0)
    {
         [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Select an Answer", nil) message:@"Must Select At Least 1 Acceptable Answer" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
        return;
    }
    
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
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (NSInteger)[answersListArray count];
    
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"answerCell" forIndexPath:indexPath];
    
    UILabel *answerLabel = (UILabel *)[cell viewWithTag:1];
    answerLabel.text = [answersListArray objectAtIndex:indexPath.row];
    answerLabel.textColor = [UIColor whiteColor];
    answerLabel.font = [UIFont fontWithName:@"Futura-Medium" size:20];
    //check to see if the answer should be highlighted
    cell.backgroundColor = [UIColor clearColor];
    
    for (NSNumber *eachAns in acceptableAnswers)
    {
        int ansInt = [eachAns integerValue];
        if(ansInt==indexPath.row)
        {
            //highlight this cell in the table as one of the selected answers
            cell.backgroundColor = colorForHighlights;
            
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
    
    if([self.editingMode isEqualToString:@"Add"] || [self.editingMode isEqualToString:@"Edit"])
    {
        //loop through all cells and change BGcolor to clear color
        
        NSMutableArray *cells = [[NSMutableArray alloc] init];
        for (NSInteger j = 0; j < [tableView numberOfSections]; ++j)
        {
            for (NSInteger i = 0; i < [tableView numberOfRowsInSection:j]; ++i)
            {
                [cells addObject:[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:j]]];
            }
        }
        
        for (UITableViewCell *cell in cells)
        {
            cell.backgroundColor = [UIColor clearColor];
            
        }
        
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        
        cell.backgroundColor = colorForHighlights;
        
        //user should be editing this field.
        self.editingCellNumber = [NSNumber numberWithInteger:indexPath.row];
   
        UILabel *answerLabel = (UILabel *)[cell viewWithTag:1];
        
        self.answerTextField.text = answerLabel.text;
        
        self.addNewAnswerButton.alpha = 0;
        self.editButton.alpha = 1;
        
        self.editingMode = @"Edit";
        
        
        return;
        
    }
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if(cell.backgroundColor==colorForHighlights)
    {
        //remove this answer from the list.
        NSNumber *ansToRemove;
        for (NSNumber *eachAns in acceptableAnswers)
        {
            int ansInt = [eachAns integerValue];
            if(ansInt==indexPath.row)
            {
                ansToRemove = eachAns;
            
                cell.backgroundColor = [UIColor clearColor];
            }
        }
        [acceptableAnswers removeObject:ansToRemove];
    }
    else
        
    {
        NSNumber *newAns = [NSNumber numberWithInteger:indexPath.row];
        [acceptableAnswers addObject:newAns];
        cell.backgroundColor = colorForHighlights;
        
        if(self.checkMark3.alpha==0)
        {
            //self.checkMark3.alpha =1;
            self.addNewPropertyButton.enabled = 1;
            
        }

    }

}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    
    
    //self.confirmQuestionButton.alpha = 1;
    
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

-(void)textViewDidBeginEditing:(UITextView *)textView
{
    if(textView.tag ==45)
    {
        self.confirmQuestionButton.alpha = 1;
        
    }
    
    [self animateTextView:textView up:YES];
}
-(void)textViewDidEndEditing:(UITextView *)textView
{
    if(textView.tag ==45)
    {
        questionText = textView.text;
        
    }
    [self animateTextView:textView up:NO];
    
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
        
        animatedDistance = 270-(460-moveUpValue-5);
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

- (void) animateTextView: (UITextView*) textView up: (BOOL) up
{
    int animatedDistance;
    int moveUpValue = textView.frame.origin.y+ textView.frame.size.height;
    UIInterfaceOrientation orientation =
    [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait ||
        orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        
        animatedDistance = 270-(460-moveUpValue-5);
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

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    
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
    NSString *rawString = [self.questionTextView text];
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *trimmed = [rawString stringByTrimmingCharactersInSet:whitespace];
    if ([trimmed length] == 0) {
        // Text was empty or only whitespace.
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Answer Error", nil) message:@"Answer Must Not Be Blank" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
        return;
    }
    
    //animate step1 up
    
    self.confirmQuestionButton.alpha = 0;
    self.confirmAnswersButton.alpha = 1;
    
    self.step1SideLabel.layer.borderColor = [UIColor greenColor].CGColor;
    self.step1SideLabel.textColor = [UIColor greenColor];
    
    //animate these labels left and grow/add a new view for step2
    //[self.firstStepLabel SlideOffLeft:self.firstStepLabel duration:1.0f];
    //[self.createQuestionLabel SlideOffLeft:self.createQuestionLabel duration:1.0f];
    //[self.recentQuestionsTitle SlideOffLeft:self.recentQuestionsTitle duration:1.0f];
    
    for(UIButton *hashBtn in self.hashtagButtons)
    {
        [hashBtn SlideOffLeft:hashBtn duration:0.5f];
        
    }
    
    [self.view SlideOffLeft:self.firstStepLabel thenGrowNewView:self.secondStepLabel duration:0.5f];
    [self.view SlideOffLeft:self.createQuestionLabel thenGrowNewView:self.addAnswersLabel duration:0.5f];
    [self.view SlideOffLeft:self.recentQuestionsTitle thenGrowNewView:self.answersListTableView duration:0.5f];
  
    //slide up the questiontextView, disable it, and change the color of the text/background to show it's not editable
    
      self.questionTextField.enabled = FALSE;
    self.questionTextField.backgroundColor = [UIColor clearColor];
    self.questionTextField.textColor = [UIColor whiteColor];
    
    questionText = self.questionTextView.text;
    
    
    self.questionTextView.text = [@"Question: " stringByAppendingString:self.questionTextView.text];
    
    self.questionTextView.editable = NO;
    self.questionTextView.backgroundColor = [UIColor clearColor];
    self.questionTextView.textColor = [UIColor whiteColor];
    
    [self.view slideUpView:self.questionTextView duration:0.5f pixels:70];
     
    [self.view BounceAddTheView:self.answerTextField];
    
    //[self.view BounceAddTheView:self.secondStepLabel];
    //[self.view BounceAddTheView:self.addAnswersLabel];
    [self.view BounceAddTheView:self.addNewAnswerButton];
    
    self.editingMode = @"Add";
    
    
}

-(IBAction)confirmAnswers:(id)sender
{
    //if edit button is visible, tell user to finish editing before submitting
    if([self.editingMode isEqualToString:@"Edit"])
    {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Finish Editing", nil) message:@"Must Finish Editing Before Confirming Answers" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
        return;
        
    }
    
    if(answersListArray.count ==0)
    {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Need At Least 1 Answer", nil) message:@"Need To Enter At Least 1 Answer" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
        return;
    }
    
    self.editingMode = @"Select";
    
    //loop through and deselect all the answers
    
    self.step2SideLabel.layer.borderColor = [UIColor greenColor].CGColor;
    self.step2SideLabel.textColor = [UIColor greenColor];
    
    [self.view SlideOffLeft:self.secondStepLabel thenGrowNewView:self.thirdStepLabel duration:0.5f];
    [self.view SlideOffLeft:self.addAnswersLabel thenGrowNewView:self.confirmAnswersLabel duration:0.5f];
    [self.view SlideOffLeft:self.confirmAnswersButton thenGrowNewView:self.addNewPropertyButton duration:0.5f];
    
    //slide off AnswerTextField and slide off edit/add button
    //add Select answers label
    UILabel *TapToSelect = [[UILabel alloc] initWithFrame:self.answerTextField.frame];
    CGRect origFrame = TapToSelect.frame;
    origFrame.size.width = 320;
    [TapToSelect setFrame:origFrame];
    
    
    TapToSelect.text = @"Tap Below To Confirm Answers";
    TapToSelect.font = [UIFont fontWithName:@"Futura-Medium" size:15];
    TapToSelect.textColor = [UIColor whiteColor];
    
    
    [self.view SlideOffLeft:self.answerTextField thenGrowNewView:TapToSelect duration:0.5f];
    [self.view SlideOffLeft:self.editButton duration:0.5f];
    [self.view SlideOffLeft:self.addNewAnswerButton duration:0.5f];
    
    
}

-(IBAction) editButton:(id)sender
{
    //select the tableview cell being edited and replace it with the new text.
    NSInteger rowIndex = [self.editingCellNumber integerValue];
    
    NSIndexPath *editingCellIndexPath = [NSIndexPath indexPathForRow:rowIndex inSection:0];
    UITableViewCell *cell = [self.answersListTableView cellForRowAtIndexPath:editingCellIndexPath];
    UILabel *answerLabel = (UILabel *)[cell viewWithTag:1];
    answerLabel.text = self.answerTextField.text;
    
    //decolor the cell
    cell.backgroundColor = [UIColor clearColor];
    
    self.addNewAnswerButton.alpha = 1;
    self.editButton.alpha = 0;
    
    [answersListArray replaceObjectAtIndex:rowIndex withObject:self.answerTextField.text];
    
    self.editingMode = @"Add";
    
}


@end
