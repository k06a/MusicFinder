//
//  ABAlbumTableViewController.m
//  MusicFinder
//
//  Created by Антон Буков on 19.03.13.
//  Copyright (c) 2013 Anton Bukov. All rights reserved.
//

#import "XMLReader.h"
#import "NSEnumerator+Linq.h"
#import "ABTrackTableViewController.h"
#import "ABAlbumTableViewController.h"

@interface ABAlbumTableViewController ()
@property (nonatomic) NSMutableDictionary * albums;
@property (nonatomic) NSMutableArray * releases;
@property (nonatomic) NSMutableDictionary * albumImageDict;
@property (nonatomic) int albumPage;
@property (nonatomic) BOOL albumFinished;
@end

@implementation ABAlbumTableViewController

- (NSMutableDictionary *)albums
{
    if (_albums == nil)
        _albums = [NSMutableDictionary dictionary];
    return _albums;
}

- (NSArray *)orderedAlbums
{
    return [[self.albums allValues] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj2[@"year"] compare:obj1[@"year"]];
    }];
}

- (NSMutableArray *)releases
{
    if (_releases == nil)
        _releases = [NSMutableArray array];
    return _releases;
}

- (NSMutableDictionary *)albumImageDict
{
    if (_albumImageDict == nil)
        _albumImageDict = [NSMutableDictionary dictionary];
    return _albumImageDict;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"segue_album2tracks"])
    {
        NSInteger row = [self.tableView indexPathForCell:sender].row;
        
        NSDictionary * album = [self orderedAlbums][row];
        NSDictionary * release = [[self.releases objectEnumerator] firstOrDefault:PREDICATE(id a, [a[@"release-group"][@"id"] isEqualToString:album[@"id"]])];
        NSDictionary * medium = release[@"medium-list"][@"medium"];
        if ([medium isKindOfClass:[NSArray class]])
            medium = [[medium objectEnumerator] max:FUNC(id, id a, @([a[@"track-list"][@"count"] intValue]))];
    
        ABTrackTableViewController * controller = segue.destinationViewController;
        controller.album = release;
        controller.tracks = medium[@"track-list"][@"track"];
    }
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.albums.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * cell_id = @"cell_album";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cell_id];
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:(UITableViewCellStyleSubtitle) reuseIdentifier:cell_id];
    
    NSDictionary * album = [self orderedAlbums][indexPath.row];
    NSDictionary * release = [[self.releases objectEnumerator] firstOrDefault:PREDICATE(id a, [a[@"release-group"][@"id"] isEqualToString:album[@"id"]])];
    cell.textLabel.text = [NSString stringWithFormat:@"%@",album[@"title"][@"text"],nil];
    
    id medium = release[@"medium-list"][@"medium"];
    if ([medium isKindOfClass:[NSArray class]])
        medium = [[medium objectEnumerator] max:FUNC(id, id a, @([a[@"track-list"][@"count"] intValue]))];
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ tracks",medium[@"track-list"][@"count"],nil];
    if (![album[@"year"] isEqualToString:@"0000"])
        cell.detailTextLabel.text = [cell.detailTextLabel.text stringByAppendingFormat:@" (%@)",album[@"year"],nil];
    /*
    NSString * image_url = album[@"image"][0][@"#text"];
    if (image_url.length == 0)
        return cell;
    
    UIImage * image= self.albumImageDict[image_url];
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
            self.albumImageDict[image_url] = image;
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

    self.title = self.artist[@"name"][@"text"];
    
    for (int i = 0; YES; i++)
    {
        NSLog(@"Request page #%d", i);
        NSString * url = [NSString stringWithFormat:@"http://www.musicbrainz.org/ws/2/release?artist=%@&inc=release-groups+recordings&type=album&status=official&limit=100&offset=%d",self.artist[@"id"],i*100,nil];
        
        NSError * error;
        NSData * data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
        NSDictionary * json = [XMLReader dictionaryForXMLData:data error:&error];
        
        NSArray * releases = json[@"metadata"][@"release-list"][@"release"];
        releases = [releases isKindOfClass:[NSArray class]] ? releases : @[releases];
        [self.releases addObjectsFromArray:releases];
        
        [self.albums addEntriesFromDictionary:[[[[releases objectEnumerator]
                                                 select:FUNC(id, id a, a[@"release-group"])]
                                                select:^id(id album) {
                                                    NSString * year = album[@"first-release-date"][@"text"];
                                                    year = year ? year : @"0000";
                                                    year = [year substringToIndex:MIN(year.length,4)];
                                                    NSMutableDictionary * dict = [album mutableCopy];
                                                    [dict addEntriesFromDictionary:@{@"year":year}];
                                                    return dict;
                                                }] toDictionary:FUNC(id, id album, album[@"id"])]];
        
        if (self.releases.count == [json[@"metadata"][@"release-list"][@"count"] intValue])
            break;
    };
    
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
