//
//  DSAppDelegate.h
//  Demo
//
//  Created by Fabio Pelosin on 04/03/13.
//  Copyright (c) 2013 Discontinuity s.r.l. unipersonale. MIT License.
//

#import <Cocoa/Cocoa.h>

@interface DSAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (unsafe_unretained) IBOutlet NSTextView *standardOutputTextView;
@property (unsafe_unretained) IBOutlet NSTextView *standardErrorTextView;
@property (weak) IBOutlet NSTextField *standardInputTextField;
@property (weak) IBOutlet NSTextField *demoLabel;

@end
