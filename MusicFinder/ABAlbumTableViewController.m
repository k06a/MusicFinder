//
//  ABAlbumTableViewController.m
//  MusicFinder
//
//  Created by Антон Буков on 19.03.13.
//  Copyright (c) 2013 Anton Bukov. All rights reserved.
//

#import "ABAlbumTableViewController.h"

@interface ABAlbumTableViewController ()
@property (nonatomic) NSMutableArray * albums;
@property (nonatomic) NSMutableDictionary * albumImageDict;
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
    cell.textLabel.text = album[@"name"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@""];
    
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

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSString * url = [NSString stringWithFormat:@"http://ws.audioscrobbler.com/2.0/?method=artist.gettopalbums&api_key=50baa20485da064d8c8c070387d79088&format=json&mbid=%@",self.artist[@"mbid"],nil];
        NSData * data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
        NSDictionary * json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        self.albums = json[@"topalbums"][@"album"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
