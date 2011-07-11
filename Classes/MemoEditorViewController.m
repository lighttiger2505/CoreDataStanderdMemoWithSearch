    //
//  DetailViewController.m
//  CoreDataMemo
//
//  Created by ohashi tosikazu on 11/06/16.
//  Copyright 2011 nagoya-bunri. All rights reserved.
//

#import "MemoEditorViewController.h"

#define TITLE_CELL_HEIGHT 40
#define TEXT_CELL_HEIGHT 418

@implementation MemoEditorViewController

@synthesize titleView, textView;
@synthesize memo;

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
	textView = nil;
}


- (void)dealloc {
	[textView release];
	[memo release];
	
    [super dealloc];
}

#pragma mark -
#pragma mark View lifecycle

/**
 ビューのロード後に呼び出される。
 */
- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = [self.memo valueForKey:@"title"];
	
	// ナビゲーションバー右にキーボードを画すボタンを追加
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel 
																							target:self action:@selector(finish:)] autorelease];
	
	self.tableView.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
	
	// タイトル入力のビューを作成して親のビューに追加
	UITextField *aTitleView = [[UITextField alloc] init];
	aTitleView.frame = CGRectMake(0, 0, 320, TITLE_CELL_HEIGHT);
	aTitleView.font = [UIFont systemFontOfSize:20.0f];
	aTitleView.placeholder = @"タイトルを入力してください。";
	aTitleView.backgroundColor = [UIColor lightGrayColor];
	aTitleView.textAlignment = UITextAlignmentCenter;
	aTitleView.contentVerticalAlignment = UIControlContentHorizontalAlignmentCenter;
	self.titleView = aTitleView;
	[aTitleView release];
	
	// テキスト入力のビューを作成して親のビューに追加。
	UITextView *aTextView = [[UITextView alloc] init];
	aTextView.delegate = self;
	aTextView.frame = [[UIScreen mainScreen] bounds];
	aTextView.font = [UIFont systemFontOfSize:20.0f];
	aTextView.scrollEnabled = YES;
	self.textView = aTextView;
	[aTextView release];
	
}

/**
 ビューを開いた際に呼び出される。
 渡されたメモの内容を反映。
 */
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:YES];
	
	// 渡されたオブジェクトからメモの内容を表示させる。
	self.titleView.text = [memo valueForKey:@"title"];
	self.textView.text = [memo valueForKey:@"text"];
	[textView scrollRangeToVisible:[textView selectedRange]];
	[self.titleView becomeFirstResponder];
}

/**
 ビューを閉じた際に呼び出される。
 メモの保存を実行。
 */
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:YES];
	
	// 何も文字列を入力していない場合
	if (titleView.text.length == 0 && textView.text.length == 0) {
		// メモの削除を実行
		[self deleteMemo];
	}else {
		// メモの保存を実行。
		[self saveMemo];
	}
}

/**
 メモを保存する。
 */
- (void)saveMemo {
	// 変更内容をデータオブジェクトに反映。
	[memo setValue:titleView.text forKey:@"title"];
	[memo setValue:textView.text forKey:@"text"];
	
	// コンテキストに保存内容を反映。
	NSError *error;
	if (![[memo managedObjectContext] save:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		exit(-1);  // Fail
	}
}

/** 
 メモを削除する。
 */
- (void)deleteMemo {
	// メモの削除を実行
	[[memo managedObjectContext] deleteObject:memo];
}

/**
 テキスト編集開始時に呼び出されるメソッド
 */
- (void)textViewDidBeginEditing:(UITextView *)handleTextView {
	// このメソッドの送信元がメモの編集ビューならば
	if(handleTextView == self.textView) {
		// ビューのサイズをキーボードで隠れない程度に小さくする
		CGRect  frame;
		frame.origin.x = 0 ;
		frame.origin.y = 0 ;
		frame.size.width = 320 ;
		frame.size.height = 232 ;
		
		handleTextView.frame = frame ;
	}
}

/**
 テキスト編集終了時に呼び出されるメソッド
 */
- (void)textViewDidEndEditing:(UITextView *)handleTextView {
	// このメソッドの送信元がメモの編集ビューならば
	if(handleTextView == self.textView) {
		// ビューのサイズを画面一杯のサイズに戻す
		CGRect  frame;
		frame.origin.x = 0 ;
		frame.origin.y = 0 ;
		frame.size.width = 320 ;
		frame.size.height = 480 ;
		
		handleTextView.frame = frame ;
	}
}

/**
 右上のボタンを押すことでで実行されるコマンド
 */
-(IBAction)finish:(id)sender {
	// キーボードを隠す処理
	[self.titleView resignFirstResponder];
	[self.textView resignFirstResponder];
}

#pragma mark -
#pragma mark Table view data source

/**
 セクション数を返すデリゲートの実装。
 */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

/**
 セクション内のデータ数を返すデリゲートの実装。
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{    
	if (indexPath.row == 0) {
		return TITLE_CELL_HEIGHT;
	}
	if (indexPath.row == 1) {
		return TEXT_CELL_HEIGHT;
	}
	return 0;
}

/**
 引数に渡されたセルの情報を編集して返すデリゲートの実装。
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	if (indexPath.row == 0) {
		[self configureTitleCell:cell atIndexPath:indexPath];
	}
	if (indexPath.row == 1) {
		[self configureTextCell:cell atIndexPath:indexPath];
	}
    return cell;
}

/**
 タイトル入力セルの内容を編集
 */
- (void)configureTitleCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath 
{
	[cell.contentView addSubview:self.titleView];
}

/**
 テキスト入力セルの内容を編集
 */
- (void)configureTextCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
	[cell.contentView addSubview:self.textView];
}
@end
