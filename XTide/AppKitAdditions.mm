//
//  AppKitAdditions.m
//  XTide
//
//  Created by Lee Ann Rucker on 6/29/16.
//  Copyright © 2016 Lee Ann Rucker. All rights reserved.
//

#import "AppKitAdditions.h"
#import "XTColorUtils.h"
#import "XTGraph.h"

@implementation XTStationRef (MacOSAdditions)

- (NSImage *)stationDot
{
    return [NSImage imageWithSize:NSMakeSize(12, 12) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
        if (self.isReferenceStation) {
            [ColorForKey(XTide_ColorKeys[refcolor]) set];
        } else {
            [ColorForKey(XTide_ColorKeys[subcolor]) set];
        }
        [[NSBezierPath bezierPathWithOvalInRect:dstRect] fill];
        return YES;
    }];
}

@end


@implementation XTStation (MacOSAdditions)

#if DEBUG_GENERATE_WATCH_IMAGE

- (NSData *)SVGClockImageWithWidth:(CGFloat)width
                            height:(CGFloat)height
                              date:(NSDate *)clockDate
{
    Dstr text_out;
    libxtide::Timestamp clockTS = libxtide::Timestamp((time_t)[clockDate timeIntervalSince1970]);
    libxtide::SVGGraph g(width, height, libxtide::Graph::clock);
    g.drawTides(mStation, clockTS);
    g.print(text_out);
    return [DstrToNSString(text_out) dataUsingEncoding:NSUTF8StringEncoding];
}

// Create a placeholder image for the watch app when there's no station
// Use the 1984 ad day and Golden Gate station:
//      Jan 22, 1984
//      "San Francisco, San Francisco Bay, California"
// 38mm: (0.0, 0.0, 136.0, 170.0)
// 42mm: (0.0, 0.0, 156.0, 195.0)
//
// XXX: This is the hackiest code I've written in a long time.
// The image comes out inverted (not flipped; a non-flipped GC gives us correct text but inverted tides),
// so it'll need fixing in a nice app like GraphicConverter.
// But it's just a one-shot image generator, not user-facing, so it's good enough.

- (void)createWatchPlaceholderImages
{
    CGFloat scale = 2;
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.day = 22;
    dateComponents.month = 1;
    dateComponents.year = 1984;
    dateComponents.hour = 12;
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDate *date = [gregorianCalendar dateFromComponents:dateComponents];
    NSString *fileLoc = [@"~/watchBackground38@2x.png" stringByExpandingTildeInPath];
    if (fileLoc) {
        [self createWatchPlaceholderImage:fileLoc
                                     rect:CGRectMake(0, 0, 136 * scale, 170 * scale)
                                     date:date];
    }
 
    fileLoc = [@"~/watchBackground42@2x.png" stringByExpandingTildeInPath];
    if (fileLoc) {
        [self createWatchPlaceholderImage:fileLoc
                                     rect:CGRectMake(0, 0, 156 * scale, 195 * scale)
                                     date:date];
    }
    // This works, but isn't as pretty as the images - colors are muddy, font isn't clear.
    // PNG files are small enough to transfer to the watch.
    // Also I don't even know if the watch handles SVGs that aren't in files.
    fileLoc = [@"~/watchBackground.svg" stringByExpandingTildeInPath];
    NSData *svgImage = [self SVGClockImageWithWidth:136 * scale height:170 * scale date:date];
    if (svgImage) {
        [svgImage writeToFile:fileLoc atomically:YES];
    }
}

- (void)createWatchPlaceholderImage:(NSString *)fileLoc
                               rect:(CGRect)offscreenRect
                               date:(NSDate *)date
{
    NSURL *fileURL = [NSURL fileURLWithPath:fileLoc];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSSize size = offscreenRect.size;
    CGContextRef contextRef = CGBitmapContextCreate(NULL, size.width, size.height, 8, 0, colorSpace, kCGImageAlphaPremultipliedLast);
    NSGraphicsContext *graphicsContext = [NSGraphicsContext graphicsContextWithCGContext:contextRef flipped:YES];
    
    NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
    [NSGraphicsContext setCurrentContext:graphicsContext];
    XTGraph *graph = [[XTGraph alloc] initClockModeWithXSize:offscreenRect.size.width ysize:offscreenRect.size.height scale:1];
    [graph drawTides:self now:date];
    CGColorSpaceRelease(colorSpace);
    CGImageRef imageRef = CGBitmapContextCreateImage(contextRef);
    [NSGraphicsContext setCurrentContext:currentContext];

    CFURLRef url = (__bridge CFURLRef)fileURL;
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
    if (!destination) {
        NSLog(@"Failed to create CGImageDestination for %@", fileURL);
        return;
    }

    CGImageDestinationAddImage(destination, imageRef, nil);

    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"Failed to write image to %@", fileURL);
        CFRelease(destination);
        return;
    }

    CFRelease(destination);
}
#endif

- (NSAttributedString *)stationInfo
{
	return [[NSAttributedString alloc] initWithHTML:[[self stationInfoAsHTML] dataUsingEncoding:NSASCIIStringEncoding]
								 documentAttributes:NULL];
}

@end