//
//  LocationPickerViewController.m
//  ShadowUI
//
//  Created by Wyatt Gahm on 11/10/21.
//

#import <UIKit/UIKit.h>
#import "LocationPickerViewController.h"
#import "LocationPickerSearchResultsViewController.h"
#import "LocationPicker.h"

@implementation LocationPickerViewController
//exp
-(id)initWithCallback:(LocationHandler)handler{
    self.handler = handler;
    return [self init];
}


- (id)init{
    self = [super init];
    
    if (self) {
        self.lpView = [[LocationPickerView alloc] initWithFrame:CGRectMake(0,0,self.view.bounds.size.width,self.view.bounds.size.height) controller:self];

        if ([self respondsToSelector:@selector(setView:)])
            [self performSelectorOnMainThread:@selector(setView:) withObject:self.lpView waitUntilDone:YES];

        self.saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(save:)];
        self.saveButton.tintColor = [UIColor blackColor];
        self.navigationItem.rightBarButtonItem = self.saveButton;

        self.searchResultsController = [[LocationPickerSearchResultsViewController alloc] init];
        self.searchResultsController.parentController = self;

        self.searchController = [[UISearchController alloc] initWithSearchResultsController:self.searchResultsController];
        self.searchController.searchResultsUpdater = self.searchResultsController;
        self.searchController.obscuresBackgroundDuringPresentation = NO;
        self.searchController.hidesNavigationBarDuringPresentation = NO;

        self.searchController.searchBar.showsBookmarkButton = YES;
        self.searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
        self.searchController.searchBar.delegate = self;

        self.navigationItem.searchController = self.searchController;
        self.navigationItem.hidesSearchBarWhenScrolling = NO;

        self.definesPresentationContext = YES;

        self.favorites = [NSMutableArray new];
        self.dictionary = [NSMutableDictionary new];
        
        /*
        HBPreferences *prefs = [[HBPreferences alloc] initWithIdentifier:@"me.nepeta.relocate"];
        id obj = [prefs objectForKey:@"Favorites"];
        if (obj && [obj isKindOfClass:[NSArray class]]) {
            self.favorites = [((NSArray *)obj) mutableCopy];
        }
         
        if ([prefs objectForKey:@"MapType"]) {
            switch ([[prefs objectForKey:@"MapType"] intValue]) {
                case 1:
                    self.lpView.mapView.mapType = MKMapTypeSatellite;
                    break;
                case 2:
                    self.lpView.mapView.mapType = MKMapTypeHybrid;
                    break;
                default:
                    self.lpView.mapView.mapType = MKMapTypeStandard;
            }
        }
        */
        self.lpView.mapView.mapType = MKMapTypeStandard;
    }

    return self;
}

- (void)searchBarBookmarkButtonClicked:(UISearchBar *)searchBar {
    [self.searchController setActive:YES];
    self.searchResultsController.allowDeletion = YES;
    self.searchResultsController.view.hidden = NO;
    self.searchResultsController.items = self.favorites;
    [self.searchResultsController.tableView reloadData];
}

- (id)view {
    return self.lpView;
}

- (void)viewWillAppear:(BOOL)animated {
    [self setTitle:[self navigationTitle]];
    [self.navigationItem setTitle:[self navigationTitle]];
    
    //exp
    /*
    id value = [self readPreferenceValue:[self specifier]];
    if ([value isKindOfClass:[NSDictionary class]]) {
        self.dictionary = [(NSDictionary *)value mutableCopy];
        if (self.dictionary[@"Coordinate"]) {
            NSDictionary *coordinateDict = self.dictionary[@"Coordinate"];
            [self.lpView createPinAt:CLLocationCoordinate2DMake([coordinateDict[@"Latitude"] doubleValue], [coordinateDict[@"Longitude"] doubleValue])];
        }
    }
     */
}

- (NSString*)navigationTitle {
    //return [[self specifier] name] ?: @"Pick location";
    return @"Location Picker";
}

- (void)save:(id)sender {
    

    if (self.lpView.pin) {
        self.dictionary[@"Coordinate"] = @{
            @"Latitude": @(self.lpView.pin.coordinate.latitude),
            @"Longitude": @(self.lpView.pin.coordinate.longitude)
        };
        NSLog(@"Saved coordinate: %@",self.dictionary[@"Coordinate"]);
        self.handler([self.dictionary[@"Coordinate"] copy]);
        //[self setPreferenceValue:self.dictionary specifier:[self specifier]];
    }else{
        //self.handler(nil);
        //exit(0);
    }
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
    /*
    if ([[self specifier] propertyForKey:@"key"] && [[[self specifier] propertyForKey:@"key"] isEqualToString:@"GlobalLocation"]) {
        HBPreferences *prefs = [[HBPreferences alloc] initWithIdentifier:@"me.nepeta.relocate"];
        [prefs removeObjectForKey:@"SelectedFavorite"];
    }
    */
    //[self.navigationController popViewControllerAnimated:TRUE];
    //exp
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

-(void)updateSavedFavorites {
    /*
    HBPreferences *prefs = [[HBPreferences alloc] initWithIdentifier:@"me.nepeta.relocate"];
    [prefs setObject:self.favorites forKey:@"Favorites"];
     */
}

-(void)favorite:(id)sender {
    [self.lpView hideCallouts];

    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Add to favorites"
        message:@"Enter name"
        preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
        handler:^(UIAlertAction * action){
            NSString *name = [(UITextField *)alert.textFields[0] text];
            NSDictionary *favorite = @{
                @"Name": name,
                @"Latitude": @(self.lpView.pin.coordinate.latitude),
                @"Longitude": @(self.lpView.pin.coordinate.longitude)
            };

            [self.favorites addObject:favorite];
            [self updateSavedFavorites];

            UIAlertController* savedAlert = [UIAlertController alertControllerWithTitle:@"Favorites"
                                        message:@"Saved!"
                                        preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
            handler:^(UIAlertAction * action) {}];
            [savedAlert addAction:defaultAction];
            [self presentViewController:savedAlert animated:YES completion:nil];

            [alert dismissViewControllerAnimated:YES completion:nil];
        }
    ];
    
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault
        handler:^(UIAlertAction * action) {
            [alert dismissViewControllerAnimated:YES completion:nil];
        }
    ];

    [alert addAction:ok];
    [alert addAction:cancel];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Name";
        textField.keyboardType = UIKeyboardTypeDefault;
    }];

    [self presentViewController:alert animated:YES completion:nil];
}

@end
