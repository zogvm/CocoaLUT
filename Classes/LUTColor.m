//
//  LUTColor.m
//  DropLUT
//
//  Created by Wil Gieseler on 12/15/13.
//  Copyright (c) 2013 Wil Gieseler. All rights reserved.
//

#import "LUTColor.h"
#import "LUTHelper.h"

#define LUT_COLOR_EQUALITY_ERROR_MARGIN .0005

@implementation LUTColor

+ (instancetype)colorWithRed:(LUTColorValue)r green:(LUTColorValue)g blue:(LUTColorValue)b {
    LUTColor *color = [[LUTColor alloc] init];
    color.red = r;
    color.green = g;
    color.blue = b;
    return color;
}

+ (instancetype)colorFromIntegersWithBitDepth:(NSUInteger)bitdepth red:(NSUInteger)r green:(NSUInteger)g blue:(NSUInteger)b {
    NSUInteger maxBits = pow(2, bitdepth) - 1;
    return [LUTColor colorWithRed:nsremapint01(r, maxBits) green:nsremapint01(g, maxBits) blue:nsremapint01(b, maxBits)];
}

+ (instancetype)colorFromIntegersWithMaxOutputValue:(NSUInteger)maxOutputValue red:(NSUInteger)r green:(NSUInteger)g blue:(NSUInteger)b {
    return [LUTColor colorWithRed:nsremapint01(r, maxOutputValue) green:nsremapint01(g, maxOutputValue) blue:nsremapint01(b, maxOutputValue)];
}

- (LUTColor *)clampedWithLowerBound:(double)lowerBound
                         upperBound:(double)upperBound{
    return [LUTColor colorWithRed:clamp(self.red, lowerBound, upperBound)
                            green:clamp(self.green, lowerBound, upperBound)
                             blue:clamp(self.blue, lowerBound, upperBound)];
}

- (LUTColor *)contrastStretchWithCurrentMin:(double)currentMin
                                 currentMax:(double)currentMax
                                   finalMin:(double)finalMin
                                   finalMax:(double)finalMax{
    return [LUTColor colorWithRed:contrastStretch(self.red, currentMin, currentMax, finalMin, finalMax)
                            green:contrastStretch(self.green, currentMin, currentMax, finalMin, finalMax)
                             blue:contrastStretch(self.blue, currentMin, currentMax, finalMin, finalMax)];
}

- (LUTColor *)colorByAddingColor:(LUTColor *)offsetColor{
    return [LUTColor colorWithRed:self.red+offsetColor.red green:self.green+offsetColor.green blue:self.blue+offsetColor.blue];
}

//thanks http://git.dyne.org/frei0r/plain/src/filter/sopsat/sopsat.cpp
//  The "saturation" parameter works like this:
//    0.0 creates a black-and-white image.
//    0.5 reduces the color saturation by half.
//    1.0 causes no change.
//    2.0 doubles the color saturation.
//  Note:  A "change" value greater than 1.0 may project your RGB values
//  beyond their normal range, in which case you probably should truncate
//  them to the desired range before trying to use them in an image.
//  ex: REC709 luma: 0.212636821677 R + 0.715182981841 G + 0.0721801964814 B
///  AlexaWideGamut: 0.291948669899 R + 0.823830265984 G + -0.115778935883 B
- (LUTColor *)colorByChangingSaturation:(double)saturation
                             usingLumaR:(double)lumaR
                                  lumaG:(double)lumaG
                                  lumaB:(double)lumaB{
    
    double luma = (self.red)*lumaR + (self.green)*lumaG + (self.blue)*lumaB;
    
    return [LUTColor colorWithRed:luma + saturation * (self.red - luma)
                            green:luma + saturation * (self.green - luma)
                             blue:luma + saturation * (self.blue - luma)];
    
}


//thanks http://en.wikipedia.org/wiki/ASC_CDL
- (LUTColor *)colorByApplyingSlope:(double)slope
                            offset:(double)offset
                             power:(double)power{
    
    offset = clampLowerBound(slope, 0);
    power = clampLowerBound(power, 0);
    
    double newRed = pow(self.red*slope + offset, power);
    double newGreen = pow(self.green*slope + offset, power);
    double newBlue = pow(self.blue*slope + offset, power);
    
    return [LUTColor colorWithRed:newRed green:newGreen blue:newBlue];
    
}


- (LUTColor *)clamped01 {
    return [LUTColor colorWithRed:clamp01(self.red) green:clamp01(self.green) blue:clamp01(self.blue)];
}

- (LUTColor *)lerpTo:(LUTColor *)otherColor amount:(double)amount {
    return [LUTColor colorWithRed:lerp1d(self.red, otherColor.red, amount)
                            green:lerp1d(self.green, otherColor.green, amount)
                             blue:lerp1d(self.blue, otherColor.blue, amount)];
}

- (LUTColor *)remappedFromInputLow:(double)inputLow
                         inputHigh:(double)inputHigh
                         outputLow:(double)outputLow
                        outputHigh:(double)outputHigh{
    return [LUTColor colorWithRed:remap(self.red, inputLow, inputHigh, outputLow, outputHigh)
                            green:remap(self.green, inputLow, inputHigh, outputLow, outputHigh)
                             blue:remap(self.blue, inputLow, inputHigh, outputLow, outputHigh)];
}

- (NSString *)description{
    return [NSString stringWithFormat:@"%.6f %.6f %.6f", self.red, self.green, self.blue];
}

- (BOOL)isEqualToLUTColor:(LUTColor *)otherColor{
    if (!otherColor){
        return NO;
    }
    return fabs(self.red - otherColor.red) <= LUT_COLOR_EQUALITY_ERROR_MARGIN && fabs(self.green - otherColor.green) <= LUT_COLOR_EQUALITY_ERROR_MARGIN && fabs(self.blue - otherColor.blue) <= LUT_COLOR_EQUALITY_ERROR_MARGIN;
    
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[LUTColor class]]) {
        return NO;
    }
    
    return [self isEqualToLUTColor:(LUTColor *)object];
}


#if TARGET_OS_IPHONE
- (UIColor *)UIColor {
    return [UIColor colorWithRed:self.red green:self.green blue:self.blue alpha:1];
}
+ (instancetype)colorWithUIColor:(UIColor *)color {
    return [LUTColor colorWithRed:color.redComponent green:color.greenComponent blue:color.blueComponent];
}
#elif TARGET_OS_MAC
- (NSColor *)NSColor {
    return [NSColor colorWithDeviceRed:self.red green:self.green blue:self.blue alpha:1];
}
+ (instancetype)colorWithNSColor:(NSColor *)color {
    return [LUTColor colorWithRed:color.redComponent green:color.greenComponent blue:color.blueComponent];
}
#endif


@end
