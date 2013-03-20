//
//  ABViewController.m
//  MusicFinder
//
//  Created by Антон Буков on 19.03.13.
//  Copyright (c) 2013 Anton Bukov. All rights reserved.
//

#import "XMLReader.h"
#import "NSEnumerator+Linq.h"
#import "ABArtistTableViewController.h"
#import "ABAlbumTableViewController.h"

@interface ABArtistTableViewController () <UISearchBarDelegate>
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (nonatomic) NSMutableArray * artists;
@property (nonatomic) NSMutableDictionary * artistImageDict;
@property (nonatomic) int artistsOffset;
@property (nonatomic) BOOL artistsFinished;
@property (nonatomic) int dangerRow;
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
    NSLog(@"Request offset %d", self.artistsOffset);
    
    NSString * str = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,(CFStringRef)name,NULL,(CFStringRef)@"!*'();:@&=+$,/?%#[] ",kCFStringEncodingUTF8));
    
    NSString * url = [NSString stringWithFormat:@"http://www.musicbrainz.org/ws/2/artist?limit=100&offset=%d&query=%@",self.artistsOffset,str,nil];
    
    NSError * error;
    NSData * data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    NSDictionary * json = [XMLReader dictionaryForXMLData:data error:&error];
    
    NSArray * artists = json[@"metadata"][@"artist-list"][@"artist"];
    artists = [artists isKindOfClass:[NSArray class]] ? artists : @[artists];
    self.artistsOffset += artists.count;
    if (artists.count < 100)
        self.artistsFinished = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.artists addObjectsFromArray:artists];
        self.dangerRow = MAX(0,self.artists.count-25);
        [self.tableView reloadData];
    });
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    self.artists = nil;
    self.artistsOffset = 0;
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
    
    if (!self.artistsFinished && indexPath.row == self.dangerRow)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self requestArtistsByName:self.searchBar.text];
        });
    }
    
    NSDictionary * artist = self.artists[indexPath.row];
    NSString * name = artist[@"name"][@"text"];
    NSString * disambiguation = artist[@"disambiguation"][@"text"];
    NSString * country = artist[@"country"][@"text"];
    id alias = artist[@"alias-list"][@"alias"];
    alias = ([alias isKindOfClass:[NSArray class]] ? alias[0] : alias)[@"text"];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%d. %@",indexPath.row+1,name,nil];
    if (disambiguation) cell.detailTextLabel.text = disambiguation;
    else if (alias)     cell.detailTextLabel.text = alias;
    else                cell.detailTextLabel.text = @"";
    if (country)
        cell.detailTextLabel.text = [cell.detailTextLabel.text stringByAppendingFormat:@" (%@)",country,nil];
    
    /*
    cell.imageView.image = nil;
    
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
     */
    
    return cell;
}

#pragma mark - UIView

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	[self.searchBar becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
