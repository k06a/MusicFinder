//
//  ABAlbumTableViewController.m
//  MusicFinder
//
//  Created by Антон Буков on 19.03.13.
//  Copyright (c) 2013 Anton Bukov. All rights reserved.
//

#import "NSEnumerator+Linq.h"
#import "ABTrackTableViewController.h"
#import "ABAlbumTableViewController.h"

@interface ABAlbumTableViewController ()
@property (nonatomic) NSMutableArray * albums;
@property (nonatomic) NSMutableDictionary * albumImageDict;
@property (nonatomic) int albumPage;
@property (nonatomic) BOOL albumFinished;
@end

@implementation ABAlbumTableViewController

- (NSArray *)albums
{
    if (_albums == nil)
        _albums = [NSMutableArray array];
    return _albums;
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
        ABTrackTableViewController * controller = segue.destinationViewController;
        controller.album = self.albums[[self.tableView indexPathForCell:sender].row];
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
    
    NSDictionary * album = self.albums[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@",album[@"name"],nil];
    
    NSArray * tracks = album[@"tracks"][@"track"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d songs",tracks.count,nil];
    if (![album[@"year"] isEqualToString:@"0000"])
        cell.detailTextLabel.text = [cell.detailTextLabel.text stringByAppendingFormat:@" (%@)",album[@"year"],nil];
    
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
    
    return cell;
}

#pragma mark - UIView

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = self.artist[@"name"];
    
    __block int totalPages = 100;
    for (int i = 1; i < totalPages; i++)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            //NSString * artistName = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,(CFStringRef)self.artist[@"name"],NULL,(CFStringRef)@"!*'();:@&=+$,/?%#[] ",kCFStringEncodingUTF8));
            
            NSString * url = [NSString stringWithFormat:@"http://ws.audioscrobbler.com/2.0/?method=artist.gettopalbums&api_key=50baa20485da064d8c8c070387d79088&format=json&mbid=%@&page=%d",self.artist[@"mbid"],i,nil];
            NSData * data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
            NSDictionary * json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            totalPages = [json[@"topalbums"][@"@attr"][@"totalPages"] intValue];
            if (i > totalPages)
                return;
            
            NSArray * albums = json[@"topalbums"][@"album"];
            if (!albums)
                return;
            if (![albums isKindOfClass:[NSArray class]])
                albums = @[albums];
            //albums = [[[albums objectEnumerator] where:PREDICATE(id a, [a[@"mbid"] length])] allObjects];
            
            albums = [[[[albums objectEnumerator] select_parallel:^id(NSDictionary * album) {
                NSString * artistName = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,(CFStringRef)album[@"artist"][@"name"],NULL,(CFStringRef)@"!*'();:@&=+$,/?%#[] ",kCFStringEncodingUTF8));
                NSString * albumName = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,(CFStringRef)album[@"name"],NULL,(CFStringRef)@"!*'();:@&=+$,/?%#[] ",kCFStringEncodingUTF8));
                
                NSString * album_url = [NSString stringWithFormat:@"http://ws.audioscrobbler.com/2.0/?method=album.getinfo&api_key=50baa20485da064d8c8c070387d79088&format=json&lang=ru&artist=%@&album=%@",artistName,albumName,nil];
                /*album_url = [NSString stringWithFormat:@"http://ws.audioscrobbler.com/2.0/?method=album.getinfo&api_key=50baa20485da064d8c8c070387d79088&format=json&lang=ru&mbid=%@",album[@"mbid"],nil];*/
                NSData * album_data = [NSData dataWithContentsOfURL:[NSURL URLWithString:album_url]];
                NSDictionary * album_json = [NSJSONSerialization JSONObjectWithData:album_data options:0 error:nil];
                
                return album_json[@"album"];
            }] select:^id(NSDictionary * album) {
                NSMutableDictionary * dict = [album mutableCopy];
                NSString * year = [[[album[@"releasedate"] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" ,"]] objectEnumerator] firstOrDefault:PREDICATE(NSString * a, a.length == 4)];
                dict[@"year"] = (year ? year : @"0000");
                return dict;
            }] allObjects];
            
            
            self.albums = [[[self.albums arrayByAddingObjectsFromArray:albums]
                           sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                               return [obj2[@"year"] compare:obj1[@"year"] options:0];
                           }] mutableCopy];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        });
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
