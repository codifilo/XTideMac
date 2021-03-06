//
//  TideTextViewController.m
//  XTideCocoa
//
//  Created by Lee Ann Rucker on 5/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TideTextViewController.h"
#import "XTSettings.h"
#import "XTStation.h"
#import "XTTideEventsOrganizer.h"
#import "XTTideEvent.h"
#import "XTGraphTouchBarView.h"

static TideTextViewController *selfContext;

static NSArray *prefsKeysOfInterest;
static NSString * const TideData_startDate = @"startDate";
static NSString * const TideData_dayRange = @"dayRange";
static NSString * const TideData_hourRange = @"hourRange";
static NSString * const TideData_monthRange = @"monthRange";

@interface TideTextViewController ()

@property BOOL customDate;
@property BOOL didAwakeFromNib;

@end

@implementation TideTextViewController

+ (void)initialize
{
	// If any of these prefs change, recompute the data elements
	prefsKeysOfInterest = [NSArray arrayWithObjects:
			XTide_eventmask, XTide_units, nil];
}

- (void)dealloc
{
    for (NSString *keyPath in prefsKeysOfInterest) {
        [XTSettings_GetUserDefaults() removeObserver:self
                                          forKeyPath:keyPath
                                             context:&selfContext];
    }
}


- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    // If it's showing a modified date, save it.
    if (self.customDate) {
        [coder encodeObject:[dateFromPicker dateValue] forKey:TideData_startDate];
    }
    [coder encodeInt:[dayStepper intValue] forKey:TideData_dayRange];
    [coder encodeInt:[hourStepper intValue] forKey:TideData_hourRange];
    [coder encodeInt:[monthStepper intValue] forKey:TideData_monthRange];
    [super encodeRestorableStateWithCoder:coder];
}

- (NSDate *)defaultStartDate
{
    // Standard default is today. Calendar has other ideas.
    return [NSDate date];
}

- (void)restoreStateWithCoder:(NSCoder *)coder
{
    // If it's nil, use default time.
    NSDate *displayDate = [coder decodeObjectForKey:TideData_startDate];
    if (displayDate) {
        self.customDate = YES;
    } else {
        displayDate = [self defaultStartDate];
    }
    [dateFromPicker setDateValue:displayDate];
    int dayRange = [coder decodeIntForKey:TideData_dayRange];
    int hourRange = [coder decodeIntForKey:TideData_hourRange];
    int monthRange = [coder decodeIntForKey:TideData_monthRange];
	[dayStepper setIntValue:dayRange];
	[hourStepper setIntValue:hourRange];
	[monthStepper setIntValue:monthRange];
	[dayField takeIntValueFrom:dayStepper];
	[hourField takeIntValueFrom:hourStepper];
	[monthField takeIntValueFrom:monthStepper];
	
	[self computeEvents];
	[self updateLabels];
    [super restoreStateWithCoder:coder];
}

- (NSInteger)defaultDayRange
{
	return 7;
}

// Oh, the fun of view-based tables calling awakeFromNib for every row.
- (void)awakeFromNib
{
    if (self.didAwakeFromNib) {
        return;
    }
	[super awakeFromNib];
    self.didAwakeFromNib = YES;
//#define DEBUG_PREDICTIONS 1

    for (NSString *keyPath in prefsKeysOfInterest) {
        [XTSettings_GetUserDefaults() addObserver:self
                                       forKeyPath:keyPath
                                          options:NSKeyValueObservingOptionNew
                                          context:&selfContext];
    }
	
    [dateFromPicker setDateValue:[self defaultStartDate]];
	[dayStepper setIntegerValue:[self defaultDayRange]];
	[monthStepper setIntegerValue:1];
	[hourStepper setIntValue:0];
	[dayField takeIntValueFrom:dayStepper];
	[hourField takeIntValueFrom:hourStepper];
	[monthField takeIntValueFrom:monthStepper];

    [dateFromPicker setTimeZone:[station timeZone]];
    [self returnToNow:nil];
}

- (NSString *)titleFormat
{
    return NSLocalizedString(@"%@ (List)", @"List window title");
}

// Events and display
- (void)computeEvents
{
	NSLog(@"subclass must implement");
}

- (void)syncStartDate:(NSDate *)date
{
    self.customDate = YES;
	NSDate *timeFrom = date;
	[dateFromPicker setDateValue:timeFrom];
	[self computeEvents];
	[self updateLabels];
    [self invalidateRestorableState];
    [super syncStartDate:date];
}

- (IBAction)returnToNow:(id)sender
{
    self.customDate = NO;
	NSDate *timeFrom = [NSDate date];
	[dateFromPicker setDateValue:timeFrom];
	[self computeEvents];
	[self updateLabels];
    [self invalidateRestorableState];
}


// Time changed
- (IBAction)updateStartTime:(id)sender
{
	[self computeEvents];
	[self updateLabels];
    [self.touchBarView setGraphdate:[self startDate]];
    [self invalidateRestorableState];
}

// Interval changed via steppers
- (IBAction)timeStepped:(id)sender
{
	[dayField takeIntValueFrom:dayStepper];
	[hourField takeIntValueFrom:hourStepper];
	[monthField takeIntValueFrom:monthStepper];
	[self computeEvents];
    [self invalidateRestorableState];
}

// Interval changed via textfields
- (IBAction)timeEntry:(id)sender
{
	[dayStepper takeIntValueFrom:dayField];
	[hourStepper takeIntValueFrom:hourField];
	[monthStepper takeIntValueFrom:monthField];
	[self computeEvents];
    [self invalidateRestorableState];
}

- (NSDate *)startDate
{
	return [dateFromPicker dateValue];
}

- (NSDate *)endDate
{
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.day = [dayStepper intValue];
    dateComponents.hour = [hourStepper intValue];
    dateComponents.month = [monthStepper intValue];
    return [currentCalendar dateByAddingComponents:dateComponents toDate:[self startDate] options:0];
}

#pragma mark export
- (NSString*)stringWithIndexes:(NSIndexSet *)rowIndexes form:(char)form mode:(char)mode
{
    XTTideEventsOrganizer *organizer = self.organizer;
    if ([organizer count] == 0) {
        organizer = [[XTTideEventsOrganizer alloc] init];
        [station predictTideEventsStart:[self startDate]
                                    end:[self endDate]
                              organizer:organizer
                                 filter:libxtide::Station::noFilter];
    }
    
    NSInteger i, first, last;
    if (rowIndexes == nil) {
        first = 0;
        last = [organizer count]-1;
    }
    else {
        first = [rowIndexes firstIndex];
        last = [rowIndexes lastIndex];
    }
    NSMutableString *str = [NSMutableString string];
    [str appendString:[XTTideEvent descriptionListHeadForm:form mode:mode station:station]];
    
    for (i = first; i <= last; i++) {
        [str appendString:[[organizer objectAtIndex:i] descriptionWithForm:form mode:mode station:station]];
        if (i < last && form == 't')
            [str appendString:@"\n"];
    }
    [str appendString:[XTTideEvent descriptionListTailForm:form mode:mode station:station]];
    return str;
}


- (NSArray *)writableTypes
{
	return @[@"ics", @"txt", @"csv"];
}

// Writes a text file 
- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	char form;
	if ([typeName isEqualToString:@"txt"])
		form = 't'; // plain text
	else if ([typeName isEqualToString:@"ics"])
		form = 'i'; // iCal format
	else if ([typeName isEqualToString:@"csv"])
		form = 'c'; // comma-separated value format
	else {
        NSLog(@"Bad type.");
		return NO;
    }
	
	// Set the form and mode based on typeName
	NSString *str = [self stringWithIndexes:nil form:form mode:'p'];
	if (str == nil) {
        NSLog(@"Could not generate contents.");
		return NO;
    }
	
	NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
	if (!data) {
        NSLog(@"Could not generate data.");
		return NO;
    }

	return [data writeToURL:absoluteURL options:NSDataWritingAtomic error:outError];
}

#pragma mark observation

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context != &selfContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    } else if (([prefsKeysOfInterest containsObject:keyPath])) {
        [self computeEvents];
    } else {
        NSAssert(0, @"Unhandled key %@ in %@", keyPath, [self className]);
    }
}

@end
