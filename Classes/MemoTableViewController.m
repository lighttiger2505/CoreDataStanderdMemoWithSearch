//
//  MemoViewController.m
//  CoreDataMemo
//
//  Created by ohashi tosikazu on 11/06/16.
//  Copyright 2011 nagoya-bunri. All rights reserved.
//

#import "MemoTableViewController.h"

#import "MemoEditorViewController.h"

@implementation MemoTableViewController

@synthesize fetchedResultsController;
@synthesize managedObjectContext;
@synthesize searchDisplayController;

@synthesize savedSearchTerm;
@synthesize savedScopeButtonIndex;
@synthesize searchWasActive;

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
	fetchedResultsController = nil;
	managedObjectContext = nil;
	searchDisplayController = nil;
}


- (void)dealloc {
	[fetchedResultsController release];
	[managedObjectContext release];
	[searchDisplayController release];
	
    [super dealloc];
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = @"メモ";
	
	// ナビゲーションバーに編集ボタンを作成。
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

	// ナビゲーションバーに追加ボタンを作成。
	UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
																			   target:self 
																			   action:@selector(addMemo:)];
	self.navigationItem.rightBarButtonItem = addButton;
	[addButton release];
	
	// 検索バーを作成
	UISearchBar *searchBar = [[[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 44.0)] autorelease];
    searchBar.autoresizingMask = (UIViewAutoresizingFlexibleWidth);
    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    self.tableView.tableHeaderView = searchBar;
	
	// 検索表示ビューコントローラ作成
    self.searchDisplayController = [[[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self] autorelease];
    self.searchDisplayController.delegate = self;
    self.searchDisplayController.searchResultsDataSource = self;
    self.searchDisplayController.searchResultsDelegate = self;
	
	if (self.savedSearchTerm)
    {
        [self.searchDisplayController setActive:self.searchWasActive];
        [self.searchDisplayController.searchBar setSelectedScopeButtonIndex:self.savedScopeButtonIndex];
        [self.searchDisplayController.searchBar setText:savedSearchTerm];
		
        self.savedSearchTerm = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// フェッチを実行
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        // Handle error
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
    }  
	
	[self.tableView reloadData];
}

/**
 ビュー非表示前に呼び出される。
 */
- (void)viewDidDisappear:(BOOL)animated
{
    // 再呼び出しされた時の為に状態を保存
    self.searchWasActive = [self.searchDisplayController isActive];
    self.savedSearchTerm = [self.searchDisplayController.searchBar text];
    self.savedScopeButtonIndex = [self.searchDisplayController.searchBar selectedScopeButtonIndex];
}

#pragma mark -
#pragma mark Adding a Student

/**
 メモの追加処理を行う。
 */
- (IBAction)addMemo:sender
{
	// 追加用ビューを作成。
	MemoEditorViewController *detailViewController = [[MemoEditorViewController alloc] init];
	
	// メモのエンティティを追加。
	detailViewController.memo = [NSEntityDescription insertNewObjectForEntityForName:@"Memo" inManagedObjectContext:self.managedObjectContext];
	
	// 追加メモの編集ビューをプッシュして表示
    [self.navigationController pushViewController:detailViewController animated:YES];
	
	[detailViewController release];
	
}

#pragma mark -
#pragma mark Table view data source

/**
 セルの内容を編集する。
 */
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
	// タイトルを表示
    NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
	NSString *memoTitle = [managedObject valueForKey:@"title"];
    cell.textLabel.text = memoTitle;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

/**
 セクション数を返すデリゲートの実装。
 */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

/**
 セクション内のデータ数を返すデリゲートの実装。
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	NSArray *sections = fetchedResultsController.sections;
	id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
	return [sectionInfo numberOfObjects];
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
    
	// 表示テーブルビューに応じたフェッチコントローラを取得し、フェッチの結果をテーブルセルに代入する。
	[self configureCell:cell atIndexPath:indexPath];
    return cell;
}

/**
 編集モード時の削除ボタンを押した際に呼び出されるメソッド
 */
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // indexPathから取得したオブジェクトを削除する
		NSManagedObjectContext *context = [fetchedResultsController managedObjectContext];
		[context deleteObject:[fetchedResultsController objectAtIndexPath:indexPath]];
		
		// 削除内容を保存
		NSError *error;
		if (![context save:&error]) {
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			abort();
		}
	}   
}

#pragma mark -
#pragma mark Table view delegate

/**
 引数に渡されたセルをタップした際のイベントを定義するデリゲートの実装。
 */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    // 選択したセルの情報の詳細表示ビューを作成して、そのビューに移動。
    MemoEditorViewController *detailViewController = [[MemoEditorViewController alloc] init];
	detailViewController.memo = [self.fetchedResultsController objectAtIndexPath:indexPath];
	[self.navigationController pushViewController:detailViewController animated:YES];
    [detailViewController release];
    
}

#pragma mark -
#pragma mark NSFetchedResultsControllerDelegate

- (UITableView*)tableViewForController:(NSFetchedResultsController*)controller 
{	
	if (controller == self.fetchedResultsController) {
		return self.tableView;
	}
	else {
		return self.searchDisplayController.searchResultsTableView;
	}
}

/**
 表示コンテンツに変更があった際に呼び出されるデリゲートの実装
 */
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller 
{
	UITableView *tableView = [self tableViewForController:controller];
	[tableView beginUpdates];
}

/**
 セクションに変更があった際に呼び出されるデリゲートの実装
 */
- (void)controller:(NSFetchedResultsController *)controller 
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex 
     forChangeType:(NSFetchedResultsChangeType)type 
{
	UITableView *tableView = [self tableViewForController:controller];
	[tableView beginUpdates];	
	
    switch(type) 
    {
        case NSFetchedResultsChangeInsert:
            [tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
			
        case NSFetchedResultsChangeDelete:
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

/**
 オブジェクトに変更があった際に呼び出されるデリゲートの実装
 */
- (void)controller:(NSFetchedResultsController *)controller 
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)theIndexPath 
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath 
{
    UITableView *tableView = [self tableViewForController:controller];
	
	// 変更の種類ごとに処理を分割
    switch(type) 
    {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
			
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:theIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
			
        case NSFetchedResultsChangeUpdate:
			[self configureCell:[tableView cellForRowAtIndexPath:theIndexPath] atIndexPath:theIndexPath];
            break;
			
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:theIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller 
{
	UITableView *tableView = [self tableViewForController:controller];
    [tableView endUpdates];
}

#pragma mark -
#pragma mark UISearchDisplayControllerDelegate 

/**
 取得した検索文字列を検索するようにフェッチコントローラーに条件を指定して
 フェッチを再実行する。
 */
- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    NSString *query = self.searchDisplayController.searchBar.text;
	// 検索文字列に変化があった場合
    if (query && query.length) {
		// 検索要求を作成してコントローラに設定
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title CONTAINS[cd] %@", searchText];
        [self.fetchedResultsController.fetchRequest setPredicate:predicate];
		[NSFetchedResultsController deleteCacheWithName:@"UserSearch"];
    }
	
	// フェッチを実行
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        // Handle error
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
    }  
	
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
	
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text] scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
	
    return YES;
}

#pragma mark - 
#pragma mark Fetched results controller   

/**
 フェッチのコントローラーを作成する。
 */
- (NSFetchedResultsController *)fetchedResultsController
{
    
    if (fetchedResultsController != nil) {
        return fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // フェッチによって取得するエンティティを指定する。
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Memo" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // 一度にフェッチする量を設定
    [fetchRequest setFetchBatchSize:20];
    
    // ソートの基準となる属性を指定する。
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // フェッチ要求を投げて、コントローラーを作成
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"UserSearch"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    [aFetchedResultsController release];
    [fetchRequest release];
    [sortDescriptor release];
    [sortDescriptors release];
    
	// フェッチを実行する。
    NSError *error = nil;
    if (![fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return fetchedResultsController;
}    

@end

