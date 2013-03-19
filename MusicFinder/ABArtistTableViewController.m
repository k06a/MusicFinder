//
//  ABViewController.m
//  MusicFinder
//
//  Created by Антон Буков on 19.03.13.
//  Copyright (c) 2013 Anton Bukov. All rights reserved.
//

#import "NSEnumerator+Linq.h"
#import "ABArtistTableViewController.h"
#import "ABAlbumTableViewController.h"

@interface ABArtistTableViewController () <UISearchBarDelegate>
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (nonatomic) NSMutableArray * artists;
@property (nonatomic) NSMutableDictionary * artistImageDict;
@property (nonatomic) int artistsPage;
@property (nonatomic) BOOL artistsFinished;
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"segue_artist2albums"])
    {
        ABAlbumTableViewController * controller = segue.destinationViewController;
        controller.artist = self.artists[[self.tableView indexPathForCell:sender].row];
    }
}

#pragma mark - UISearchBar

- (void)requestArtistsByName:(NSString *)name
{
    NSLog(@"Request page %d", self.artistsPage);
    self.artistsPage += 1;
    
    NSString * str = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                           (CFStringRef)name,
                                                                                           NULL,
                                                                                           (CFStringRef)@"!*'();:@&=+$,/?%#[] ",
                                                                                           kCFStringEncodingUTF8));
    
    NSString * url = [NSString stringWithFormat:@"http://ws.audioscrobbler.com/2.0/?method=artist.search&api_key=50baa20485da064d8c8c070387d79088&format=json&artist=%@&limit=%d&page=%d",str,30,self.artistsPage-1,nil];
    
    NSData * data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    NSDictionary * json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSArray * artists = json[@"results"][@"artistmatches"][@"artist"];
    if (artists.count < 30)
        self.artistsFinished = YES;
    artists = [[[artists objectEnumerator] where:PREDICATE(id a, [a[@"mbid"] length])] allObjects];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.artists addObjectsFromArray:artists];
        [self.tableView reloadData];
    });
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    self.artists = nil;
    self.artistsPage = 1;
    self.artistsFinished = NO;
    [self.tableView reloadData];
    
    [self requestArtistsByName:searchBar.text];
    
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
    
    if (!self.artistsFinished && indexPath.row + 1 == self.artists.count)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self requestArtistsByName:self.searchBar.text];
        });
    }
    
    NSDictionary * artist = self.artists[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%d. %@",indexPath.row+1,artist[@"name"],nil];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@👂",artist[@"listeners"],nil];
    cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
    cell.imageView.image = nil;
    cell.imageView.bounds = CGRectMake(0, 0, 30, 30);
    
    NSString * image_url = artist[@"image"][0][@"#text"];
    if (image_url.length == 0)
        return cell;
    
    UIImage * image = self.artistImageDict[image_url];
    if (image)
    {
        cell.imageView.image = image;
        cell.imageView.bounds = CGRectMake(0, 0, 30, 30);
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
