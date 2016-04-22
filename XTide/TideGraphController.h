//
//  TideGraphController.h
//  XTideCocoa
//
//  Created by Lee Ann Rucker on 7/15/06.
//  Copyright 2006 . 
//
/*
    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#import "TideController.h"

@class GraphView;

@interface TideGraphController : TideController
{
	IBOutlet GraphView *graphView;
	IBOutlet NSButton *nowButton;
	
	// Sheet
	IBOutlet NSWindow *markSheet;
	IBOutlet NSButton *showMarkCheckbox;
	IBOutlet NSTextField *markValueText;
	IBOutlet NSComboBox *markUnitsCombo;
	IBOutlet NSTextField *aspectValueText;

    NSTimer *nowTimer;
}

@property (readwrite, retain) NSTimer *nowTimer;

- (GraphView *)graphView;

- (IBAction)showOptionSheet:(id)sender;
- (IBAction)hideOptionSheet:(id)sender;
- (IBAction)updateStartTime:(id)sender;
- (IBAction)returnToNow:(id)sender;
@end
