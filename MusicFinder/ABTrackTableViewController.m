//
//  ABTrackTableViewController.m
//  MusicFinder
//
//  Created by Антон Буков on 20.03.13.
//  Copyright (c) 2013 Anton Bukov. All rights reserved.
//

#import "ABListenTrackViewController.h"
#import "ABTrackTableViewController.h"

@interface ABTrackTableViewController ()

@end

@implementation ABTrackTableViewController

- (NSArray *)tracks
{
    return self.album[@"tracks"][@"track"];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"segue_track2listen"])
    {
        ABListenTrackViewController * controller = segue.destinationViewController;
        NSDictionary * track = self.tracks[[self.tableView indexPathForCell:sender].row];
        controller.title = track[@"name"];
        controller.url = track[@"url"];
    }
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tracks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * cell_id = @"cell_track";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cell_id];
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:(UITableViewCellStyleSubtitle) reuseIdentifier:cell_id];
    
    NSDictionary * track = self.tracks[indexPath.row];
    int duration = [track[@"duration"] intValue];
    cell.textLabel.text = [NSString stringWithFormat:@"%d. %@",indexPath.row+1,track[@"name"],nil];
    if (duration < 60*60)
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%d:%02d",duration/60,duration%60,nil];
    else
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%d:%02d:%02d",duration/3600,(duration%3600)/60,duration%60,nil];
    
    return cell;
}

#pragma mark - UIView

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.title = self.album[@"name"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
