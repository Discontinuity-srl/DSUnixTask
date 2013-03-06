//
//  DSAppDelegate.m
//  Demo
//
//  Created by Fabio Pelosin on 04/03/13.
//  Copyright (c) 2013 Discontinuity s.r.l. unipersonale. MIT License.
//

#import "DSAppDelegate.h"

#import "DSUnixTaskXPCManager.h"
#import "DSUnixTaskSubProcessManager.h"

@interface DSAppDelegate ()

/*
 The task which recives the input from the standardInputTextField.
 */
@property DSUnixTask *inputTask;
@property NSMutableString *standardOutputLog;
@property NSMutableString *standardErrorLog;
@end

//------------------------------------------------------------------------------

/*
 Select a manager.
 */
#define USE_XPC TRUE

/*
 Select a demo.
 */
#define DEMO_1 FALSE

//------------------------------------------------------------------------------


#if USE_XPC
#define DSUnixTaskManager DSUnixTaskXPCManager
#else
#define DSUnixTaskManager DSDSUnixTaskLocalManager
#endif

#if DEMO_1
#define DemoSelector runDemo1
#else
#define DemoSelector runDemo2
#endif


@implementation DSAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  [[DSUnixTaskSubProcessManager sharedManager] setLoggingEnabled:TRUE];
  [[DSUnixTaskXPCManager sharedManager] setServiceBundleIdentifier:@"it.discontinuity.Service-Demo"];
  [[DSUnixTaskXPCManager sharedManager] setLoggingEnabled:TRUE];

  [self setStandardOutputLog:[NSMutableString new]];
  [self setStandardErrorLog:[NSMutableString new]];
  [self prettifyTextViews];

  NSLog(@"Using %@", NSStringFromClass([DSUnixTaskManager class]));
  [self DemoSelector];
}

//------------------------------------------------------------------------------
#pragma mark Library Showcase
//------------------------------------------------------------------------------

/*
 Demo1 shows:
 - Support for many tasks running concurrently.
 - Standard ourput and etandard error.
 - Standard input.
*/
- (void)runDemo1;
{
  [self.demoLabel setStringValue:@"demo 1"];

  [self setInputTask:[DSUnixTaskManager task]];
  [self.inputTask setCommand:@"/bin/cat"];
  [self hookLauncherToTextViews:self.inputTask];

  DSUnixTask *echoTask = [DSUnixTaskManager task];
  [echoTask setLaunchPath:@"/bin/echo"];
  [echoTask setArguments:@[@"Cat is listening and echoing back... try it!"]];
  [self hookLauncherToTextViews:echoTask];

  DSUnixTask *catWithErrorLauncher = [DSUnixTaskManager task];
  [catWithErrorLauncher setLaunchPath:@"/bin/cat"];
  [catWithErrorLauncher setArguments:@[@"This_file_will_not_be_found"]];
  [self hookLauncherToTextViews:catWithErrorLauncher];

  DSUnixTask *anotherCatLauncher = [DSUnixTaskManager task];
  [anotherCatLauncher setLaunchPath:@"/bin/cat"];
  [self hookLauncherToTextViews:anotherCatLauncher];

  [self.inputTask launch];
  [echoTask launch];
  [catWithErrorLauncher launch];
  [anotherCatLauncher launch];
}

/*
 Demo2 shows:
 - The usage of the shell task.
 - Running a Ruby repl (irb).

 Try:
 

 ```ruby
 ['c', 'b', 'a'].sort
 ```
 
 It is also possible to run a shell, try running `bash -i`.
*/
- (void)runDemo2;
{
  [self.demoLabel setStringValue:@"demo 2"];
  
  NSMutableDictionary *environment = [NSMutableDictionary new];
  environment[@"NSUnbufferedIO"] = @"YES";
  DSUnixShellTask *shellTask = [DSUnixTaskManager shellTask];
  [shellTask setCommand:@"irb"];
  [shellTask setEnvironment:environment];

  [self setInputTask:shellTask];
  [self hookLauncherToTextViews:self.inputTask];

  [self.inputTask launch];
}

/*
 Seding the input to the task.
 */
- (IBAction)standardInputAction:(NSTextField*)sender
{
  NSString *input = [[sender stringValue] stringByAppendingString:@"\n"];
  [self.inputTask writeStringToStandardInput:input];
}

- (void)hookLauncherToTextViews:(DSUnixTask*)launcher
{
  NSTextView *standardOutputTextView = self.standardOutputTextView;
  void (^standardOutputHandler)(DSUnixTask *, NSString *) = ^(DSUnixTask *taskLauncher, NSString *newOutput){
    NSString *line = [NSString stringWithFormat:@"[%@ %d] %@", taskLauncher.name, taskLauncher.processIdentifier, newOutput];
    appendLineToLog(self.standardOutputLog, line);
    [standardOutputTextView setString:self.standardOutputLog];
    [standardOutputTextView scrollToEndOfDocument:nil];
  };

  NSTextView *standardErrorTextView = self.standardErrorTextView;
  void (^standardErrorHandler)(DSUnixTask *, NSString *) = ^(DSUnixTask *taskLauncher, NSString *newOutput){
    NSString *line = [NSString stringWithFormat:@"[%@ %d] %@", taskLauncher.name, taskLauncher.processIdentifier, newOutput];
    appendLineToLog(self.standardErrorLog, line);
    [standardErrorTextView setString:self.standardErrorLog];
    [standardErrorTextView scrollToEndOfDocument:nil];
  };

  [launcher setStandardOutputHandler:standardOutputHandler];
  [launcher setStandardErrorHandler:standardErrorHandler];
}

//------------------------------------------------------------------------------
#pragma mark Not interesting
//------------------------------------------------------------------------------

/*
 Appends the given line to the given log.
 */
void appendLineToLog(NSMutableString *log, NSString *line)
{
  if (![log isEqualToString:@""] && ![log hasSuffix:@"\n"]) {
    [log appendString:@"\n"];
  }
  line = [line stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
  [log appendString:line];
}

/*
 Prettifies the text views.
 */
- (void)prettifyTextViews {
  [self configureTextView:self.standardOutputTextView];
  [self configureTextView:self.standardErrorTextView];
  [self.standardOutputTextView setTextColor:[NSColor colorWithDeviceWhite:0.25 alpha:1]];
  [self.standardErrorTextView setTextColor:[NSColor colorWithDeviceRed:0.802 green:0.399 blue:0.402 alpha:1.000]];
  [self.standardInputTextField setFont:[NSFont fontWithName:@"Menlo" size:12]];
}

- (void)configureTextView:(NSTextView *)textView;
{
  [textView setFont:[NSFont fontWithName:@"Menlo" size:12]];
  NSTextContainer *textContainer = [textView textContainer];
  [textContainer setContainerSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
  [textContainer setWidthTracksTextView: NO];
  [textView setHorizontallyResizable: YES];
}

@end
