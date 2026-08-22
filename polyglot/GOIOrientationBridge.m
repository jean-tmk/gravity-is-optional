#import <Foundation/Foundation.h>
typedef struct { double x; double y; } GOIVector;
@interface GOIOrientationBridge:NSObject
-(GOIVector)fieldForAngle:(double)degrees strength:(double)strength;
-(NSDictionary<NSString*,NSNumber*>*)manifestForAngle:(double)degrees strength:(double)strength stability:(NSInteger)stability;
@end
@implementation GOIOrientationBridge
-(GOIVector)fieldForAngle:(double)degrees strength:(double)strength{const double radians=degrees*M_PI/180.0;return(GOIVector){.x=cos(radians)*strength,.y=sin(radians)*strength};}
-(NSDictionary<NSString*,NSNumber*>*)manifestForAngle:(double)degrees strength:(double)strength stability:(NSInteger)stability{return@{@"angle":@(fmod(degrees+360.0,360.0)),@"strength":@(MAX(0.0,MIN(100.0,strength))),@"stability":@(MAX(0,MIN(100,stability)))};}
@end
