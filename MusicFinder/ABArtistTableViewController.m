//
//  ABViewController.m
//  MusicFinder
//
//  Created by Антон Буков on 19.03.13.
//  Copyright (c) 2013 Anton Bukov. All rights reserved.
//

#import "ABArtistTableViewController.h"
#import "ABAlbumTableViewController.h"

@interface ABArtistTableViewController () <UISearchBarDelegate>
@property (nonatomic) NSMutableArray * artists;
@property (nonatomic) NSMutableDictionary * artistImageDict;
@property (nonatomic) NSMutableDictionary * futureRequests;
@end

@implementation ABArtistTableViewController

- (NSMutableArray *)artists
{
    if (_artists == nil)
        _artists = [NSMutableArray array];
    return _artists;
}

- (NSMutableDictionary *)artistImageDict
{
    if (_artistImageDict == nil)
        _artistImageDict = [NSMutableDictionary dictionary];
    return _artistImageDict;
}

- (NSMutableDictionary *)futureRequests
{
    if (_futureRequests == nil)
        _futureRequests = [NSMutableDictionary dictionary];
    return _futureRequests;
}

- (void)addFutureRequestsObject:(id)object forIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray * array = self.futureRequests[indexPath];
    if (array == nil)
    {
        array = [NSMutableArray array];
        self.futureRequests[indexPath] = array;
    }
    [array addObject:object];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"segue_artist2albums"])
    {
        ABAlbumTableViewController * controller = segue.destinationViewController;
        controller.artist = self.artists[[self.tableView indexPathForCell:sender].row];
    }
}

#pragma mark - UISearchBar

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    self.artists = nil;
    self.futureRequests = nil;
    [self.tableView reloadData];
    
    __block ABArtistTableViewController * this = self;
    for (int i = 0; i < 100; i++) {
        const int rowsByRequest = 30;
        const int actionRow = MAX(0,i*rowsByRequest-rowsByRequest/2); // 0,50,150,250,350...
        
        [self addFutureRequestsObject:[^{
            NSLog(@"Request page #%d", i);
            NSString * str = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                 (CFStringRef)searchBar.text,
                                                                                 NULL,
                                                                                 (CFStringRef)@"!*'();:@&=+$,/?%#[] ",
                                                                                 kCFStringEncodingUTF8));
            
            NSString * url = [NSString stringWithFormat:@"http://ws.audioscrobbler.com/2.0/?method=artist.search&api_key=50baa20485da064d8c8c070387d79088&format=json&artist=%@&limit=%d&page=%d",str,rowsByRequest,i,nil];
            
            NSData * data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
            NSDictionary * json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSArray * artists = json[@"results"][@"artistmatches"][@"artist"];
            [this.artists addObjectsFromArray:artists];
            [this.tableView reloadData];
        } copy] forIndexPath:[NSIndexPath indexPathForRow:actionRow inSection:0]];
    }
    
    NSIndexPath * zeroIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    void(^func)() = [self.futureRequests[zeroIndexPath] objectAtIndex:0];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), func);
    [self.futureRequests removeObjectForKey:zeroIndexPath];
    
    [searchBar resignFirstResponder];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.artists count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * cell_id = @"cell_artist";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cell_id];
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:(UITableViewCellStyleValue1) reuseIdentifier:cell_id];
    
    NSArray * tasks = self.futureRequests[indexPath];
    if (tasks)
    {
        for (void(^func)() in tasks)
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), func);
        [self.futureRequests removeObjectForKey:indexPath];
    }
    
    NSDictionary * artist = self.artists[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%d. %@",indexPath.row+1,artist[@"name"],nil];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@👂",artist[@"listeners"],nil];
    cell.imageView.image = nil;
    
    NSString * image_url = artist[@"image"][0][@"#text"];
    if (image_url.length == 0)
        return cell;
    
    UIImage * image= self.artistImageDict[image_url];
    if (image)
    {
        cell.imageView.image = image;
        return cell;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData * data = [NSData dataWithContentsOfURL:[NSURL URLWithString:image_url]];
        UIImage * image = [UIImage imageWithData:data];
        dispatch_async(dispatch_get_main_queue(), ^{
            //UITableViewCell * cell2 = [tableView cellForRowAtIndexPath:indexPath];
            //cell2.imageView.image = image;
            self.artistImageDict[image_url] = image;
            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:(UITableViewRowAnimationAutomatic)];
            NSLog(@"Set image for %@", indexPath);
        });
    });
    
    return cell;
}

#pragma mark - UIView

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
