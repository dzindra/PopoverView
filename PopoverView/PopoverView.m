//
//  PopoverView.m
//  Embark
//
//  Created by Oliver Rickard on 20/08/2012.
//
//

#import "PopoverView.h"
#import "PopoverView_Configuration.h"
#import <QuartzCore/QuartzCore.h>

#pragma mark - Implementation

@implementation PopoverView



#pragma mark - View Lifecycle

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        self.backgroundColor = [UIColor clearColor];
        
        self.titleView = nil;
        self.contentView = nil;

        [self setPropertiesFromConfiguration];
        
        showDividerRects = self.showDividersBetweenViews;
    }
    return self;
}

- (void)dealloc
{
    self.subviewsArray = nil;
    
    if (dividerRects) {
        dividerRects = nil;
    }
    
    self.contentView = nil;
    self.titleView = nil;
}

- (void)setPropertiesFromConfiguration {
    // default values are set directly into ivars to allow UIAppearance selectors to work;
    _arrowHeight = kArrowHeight;
    _boxPadding = kBoxPadding;
    _CPOffset = kCPOffset;
    _boxRadius = kBoxRadius;
    _arrowCurvature = kArrowCurvature;
    _arrowHorizontalPadding = kArrowHorizontalPadding;
    _shadowAlpha = kShadowAlpha;
    _shadowBlur = kShadowBlur;
    _boxAlpha = kBoxAlpha;
    _topMargin = kTopMargin;
    _horizontalMargin = kHorizontalMargin;
    _imageTopPadding = kImageTopPadding;
    _imageBottomPadding = kImageBottomPadding;
    _showArrow = YES;
    _showDividersBetweenViews = kShowDividersBetweenViews;
    _dividerColor = kDividerColor;
    _gradientBottomColor = kGradientBottomColor;
    _gradientTopColor = kGradientTopColor;
    _drawTitleGradient = kDrawTitleGradient;
    _gradientTitleBottomColor = kGradientTitleBottomColor;
    _gradientTitleTopColor = kGradientTitleTopColor;
    _textFont = kTextFont;
    _textColor = kTextColor;
    _textHighlightColor = kTextHighlightColor;
    _textAlignment = kTextAlignment;
    _titleFont = kTitleFont;
    _titleColor = kTitleColor;
    _drawBorder = kDrawBorder;
    _borderColor = kBorderColor;
    _borderWidth = kBorderWidth;
}

#pragma mark - Display methods

- (void)showAtPoint:(CGPoint)point inView:(UIView *)view withContentView:(UIView *)cView {
    
    //NSLog(@"point:%f,%f", point.x, point.y);
    
    self.contentView = cView;

    // get the top view
    // http://stackoverflow.com/questions/3843411/getting-reference-to-the-top-most-view-window-in-ios-application/8045804#8045804
    topView = [[[[UIApplication sharedApplication] keyWindow] subviews] lastObject];
    
    [self setupLayout:point inView:view];
    
    // Make the view small and transparent before animation
    self.alpha = 0.f;
    self.transform = CGAffineTransformMakeScale(0.1f, 0.1f);
    
    // animate into full size
    // First stage animates to 1.05x normal size, then second stage animates back down to 1x size.
    // This two-stage animation creates a little "pop" on open.
    [UIView animateWithDuration:0.2f delay:0.f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.alpha = 1.f;
        self.transform = CGAffineTransformMakeScale(1.05f, 1.05f);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.08f delay:0.f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.transform = CGAffineTransformIdentity;
        } completion:nil];
    }];
}

- (void)layoutAtPoint:(CGPoint)point inView:(UIView *)view
{
    // make transparent
    self.alpha = 0.f;
    
    [self setupLayout:point inView:view];
    
    // animate back to full opacity
    [UIView animateWithDuration:0.2f delay:0.f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.alpha = 1.f;
    } completion:nil];
}

-(void)setupLayout:(CGPoint)point inView:(UIView*)view
{
    CGPoint topPoint = [topView convertPoint:point fromView:view];

    arrowPoint = topPoint;

    //NSLog(@"arrowPoint:%f,%f", arrowPoint.x, arrowPoint.y);

    CGRect topViewBounds = topView.bounds;
    //NSLog(@"topViewBounds %@", NSStringFromCGRect(topViewBounds));

    float contentHeight = _contentView.frame.size.height;
    float contentWidth = _contentView.frame.size.width;

    float padding = self.boxPadding;

    float boxHeight = contentHeight + 2.f*padding;
    float boxWidth = contentWidth + 2.f*padding;

    float xOrigin = 0.f;

    //Make sure the arrow point is within the drawable bounds for the popover.
    if (arrowPoint.x + self.arrowHeight > topViewBounds.size.width - self.horizontalMargin - self.boxRadius - self.arrowHorizontalPadding) {//Too far to the right
        arrowPoint.x = topViewBounds.size.width - self.horizontalMargin - self.boxRadius - self.arrowHorizontalPadding - self.arrowHeight;
        //NSLog(@"Correcting Arrow Point because it's too far to the right");
    } else if (arrowPoint.x - self.arrowHeight < self.horizontalMargin + self.boxRadius + self.arrowHorizontalPadding) {//Too far to the left
        arrowPoint.x = self.horizontalMargin + self.arrowHeight + self.boxRadius + self.arrowHorizontalPadding;
        //NSLog(@"Correcting Arrow Point because it's too far to the left");
    }

    //NSLog(@"arrowPoint:%f,%f", arrowPoint.x, arrowPoint.y);

    xOrigin = floorf(arrowPoint.x - boxWidth*0.5f);

    //Check to see if the centered xOrigin value puts the box outside of the normal range.
    if (xOrigin < CGRectGetMinX(topViewBounds) + self.horizontalMargin) {
        xOrigin = CGRectGetMinX(topViewBounds) + self.horizontalMargin;
    } else if (xOrigin + boxWidth > CGRectGetMaxX(topViewBounds) - self.horizontalMargin) {
        //Check to see if the positioning puts the box out of the window towards the left
        xOrigin = CGRectGetMaxX(topViewBounds) - self.horizontalMargin - boxWidth;
    }

    float arrowHeight = self.showArrow ? self.arrowHeight : 0;

    float topPadding = self.topMargin;

    above = YES;

    if (topPoint.y - contentHeight - arrowHeight - topPadding < CGRectGetMinY(topViewBounds)) {
        //Position below because it won't fit above.
        above = NO;

        boxFrame = CGRectMake(xOrigin, arrowPoint.y + arrowHeight, boxWidth, boxHeight);
    } else {
        //Position above.
        above = YES;

        boxFrame = CGRectMake(xOrigin, arrowPoint.y - arrowHeight - boxHeight, boxWidth, boxHeight);
    }

    //NSLog(@"boxFrame:(%f,%f,%f,%f)", boxFrame.origin.x, boxFrame.origin.y, boxFrame.size.width, boxFrame.size.height);

    CGRect contentFrame = CGRectMake(boxFrame.origin.x + padding, boxFrame.origin.y + padding, contentWidth, contentHeight);
    _contentView.frame = contentFrame;

    //We set the anchorPoint here so the popover will "grow" out of the arrowPoint specified by the user.
    //You have to set the anchorPoint before setting the frame, because the anchorPoint property will
    //implicitly set the frame for the view, which we do not want.
    self.layer.anchorPoint = CGPointMake(arrowPoint.x / topViewBounds.size.width, arrowPoint.y / topViewBounds.size.height);
    self.frame = topViewBounds;
    [self setNeedsDisplay];

    [self addSubview:_contentView];
    [topView addSubview:self];

    //Add a tap gesture recognizer to the large invisible view (self), which will detect taps anywhere on the screen.
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    tap.cancelsTouchesInView = NO; // Allow touches through to a UITableView or other touchable view, as suggested by Dimajp.
    [self addGestureRecognizer:tap];

    self.userInteractionEnabled = YES;
}


#pragma mark - Activity Indicator

//Animates in a progress indicator, and removes
- (void)showActivityIndicatorWithMessage:(NSString *)msg
{
    if ([_titleView isKindOfClass:[UILabel class]]) {
        ((UILabel *)_titleView).text = msg;
    }
    
    if (_subviewsArray && (_subviewsArray.count > 0)) {
        [UIView animateWithDuration:0.2f animations:^{
            for (UIView *view in _subviewsArray) {
                view.alpha = 0.f;
            }
        }];
        
        if (showDividerRects) {
            showDividerRects = NO;
            [self setNeedsDisplay];
        }
    }
    
    if (activityIndicator) {
        [activityIndicator removeFromSuperview];
        activityIndicator = nil;
    }
    
    activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.frame = CGRectMake(CGRectGetMidX(_contentView.bounds) - 10.f, CGRectGetMidY(_contentView.bounds) - 10.f + 20.f, 20.f, 20.f);
    [_contentView addSubview:activityIndicator];
    
    [activityIndicator startAnimating];
}

- (void)hideActivityIndicatorWithMessage:(NSString *)msg
{
    if ([_titleView isKindOfClass:[UILabel class]]) {
        ((UILabel *)_titleView).text = msg;
    }
    
    [activityIndicator stopAnimating];
    [UIView animateWithDuration:0.1f animations:^{
        activityIndicator.alpha = 0.f;
    } completion:^(BOOL finished) {
        [activityIndicator removeFromSuperview];
        activityIndicator = nil;
    }];
}

- (void)showImage:(UIImage *)image withMessage:(NSString *)msg
{
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.alpha = 0.f;
    imageView.frame = CGRectMake(floorf(CGRectGetMidX(_contentView.bounds) - image.size.width*0.5f), floorf(CGRectGetMidY(_contentView.bounds) - image.size.height*0.5f + ((self.titleView) ? 20 : 0.f)), image.size.width, image.size.height);
    imageView.transform = CGAffineTransformMakeScale(0.1f, 0.1f);
    
    [_contentView addSubview:imageView];
    
    if (_subviewsArray && (_subviewsArray.count > 0)) {
        [UIView animateWithDuration:0.2f animations:^{
            for (UIView *view in _subviewsArray) {
                view.alpha = 0.f;
            }
        }];
        
        if (showDividerRects) {
            showDividerRects = NO;
            [self setNeedsDisplay];
        }
    }
    
    if (msg) {
        if ([_titleView isKindOfClass:[UILabel class]]) {
            ((UILabel *)_titleView).text = msg;
        }
    }
    
    [UIView animateWithDuration:0.2f delay:0.2f options:UIViewAnimationOptionCurveEaseOut animations:^{
        imageView.alpha = 1.f;
        imageView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        //[imageView removeFromSuperview];
    }];
}

- (void)showError
{
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error"]];
    imageView.alpha = 0.f;
    imageView.frame = CGRectMake(CGRectGetMidX(_contentView.bounds) - 20.f, CGRectGetMidY(_contentView.bounds) - 20.f + ((self.titleView) ? 20 : 0.f), 40.f, 40.f);
    imageView.transform = CGAffineTransformMakeScale(0.1f, 0.1f);
    
    [_contentView addSubview:imageView];
    
    if (_subviewsArray && (_subviewsArray.count > 0)) {
        [UIView animateWithDuration:0.1f animations:^{
            for (UIView *view in _subviewsArray) {
                view.alpha = 0.f;
            }
        }];
        
        if (showDividerRects) {
            showDividerRects = NO;
            [self setNeedsDisplay];
        }
    }
    
    [UIView animateWithDuration:0.1f delay:0.1f options:UIViewAnimationOptionCurveEaseOut animations:^{
        imageView.alpha = 1.f;
        imageView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        //[imageView removeFromSuperview];
    }];
    
}

- (void)showSuccess
{
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"success"]];
    imageView.alpha = 0.f;
    imageView.frame = CGRectMake(CGRectGetMidX(_contentView.bounds) - 20.f, CGRectGetMidY(_contentView.bounds) - 20.f + ((self.titleView) ? 20 : 0.f), 40.f, 40.f);
    imageView.transform = CGAffineTransformMakeScale(0.1f, 0.1f);
    
    [_contentView addSubview:imageView];
    
    if (_subviewsArray && (_subviewsArray.count > 0)) {
        [UIView animateWithDuration:0.1f animations:^{
            for (UIView *view in _subviewsArray) {
                view.alpha = 0.f;
            }
        }];
        
        if (showDividerRects) {
            showDividerRects = NO;
            [self setNeedsDisplay];
        }
    }
    
    [UIView animateWithDuration:0.1f delay:0.1f options:UIViewAnimationOptionCurveEaseOut animations:^{
        imageView.alpha = 1.f;
        imageView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        //[imageView removeFromSuperview];
    }];
    
}

#pragma mark - User Interaction

- (void)tapped:(UITapGestureRecognizer *)tap
{    
    CGPoint point = [tap locationInView:_contentView];
    
    //NSLog(@"point:(%f,%f)", point.x, point.y);
    
    BOOL found = NO;
    
    //NSLog(@"_subviewsArray:%@", _subviewsArray);
    
    for (int i = 0; i < _subviewsArray.count && !found; i++) {
        UIView *view = [_subviewsArray objectAtIndex:i];
        
        //NSLog(@"Rect:(%f,%f,%f,%f)", view.frame.origin.x, view.frame.origin.y, view.frame.size.width, view.frame.size.height);
        
        if (CGRectContainsPoint(view.frame, point)) {
            //The tap was within this view, so we notify the delegate, and break the loop.
            
            found = YES;
            
            //NSLog(@"Tapped subview:%d", i);
            
            if ([view isKindOfClass:[UIButton class]]) {
                return;
            }
            
            if (_delegate && [_delegate respondsToSelector:@selector(popoverView:didSelectItemAtIndex:)]) {
                [_delegate popoverView:self didSelectItemAtIndex:i];
            }
            
            break;
        }
    }
    
    if (!found && CGRectContainsPoint(_contentView.bounds, point)) {
        found = YES;
        //NSLog(@"popover box contains point, ignoring user input");
    }
    
    if (!found) {
        [self dismiss:YES];
    }
    
}

- (void)didTapButton:(UIButton *)sender
{
    int index = [_subviewsArray indexOfObject:sender];
    
    if (index == NSNotFound) {
        return;
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(popoverView:didSelectItemAtIndex:)]) {
        [_delegate popoverView:self didSelectItemAtIndex:index];
    }
}

- (void)dismiss
{
    [self dismiss:YES];
}

- (void)dismiss:(BOOL)animated
{
    if (!animated)
    {
        [self dismissComplete];
    }
    else
    {
        [UIView animateWithDuration:0.3f animations:^{
            self.alpha = 0.1f;
            self.transform = CGAffineTransformMakeScale(0.1f, 0.1f);
        } completion:^(BOOL finished) {
            [self dismissComplete];
        }];
    }
}

- (void)dismissComplete
{
    [self removeFromSuperview];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(popoverViewDidDismiss:)]) {
        [_delegate popoverViewDidDismiss:self];
    }
}

- (void)animateRotationToNewPoint:(CGPoint)point inView:(UIView *)view withDuration:(NSTimeInterval)duration
{
    [self layoutAtPoint:point inView:view];
}

#pragma mark - Drawing Routines

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    
    // Build the popover path
    CGRect frame = boxFrame;
    
    float xMin = CGRectGetMinX(frame);
    float yMin = CGRectGetMinY(frame);
    
    float xMax = CGRectGetMaxX(frame);
    float yMax = CGRectGetMaxY(frame);
    
    float radius = self.boxRadius; //Radius of the curvature.
    
    float cpOffset = self.CPOffset; //Control Point Offset.  Modifies how "curved" the corners are.
    
    
    /*
     LT2            RT1
     LT1⌜⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⌝RT2
     |               |
     |    popover    |
     |               |
     LB2⌞_______________⌟RB1
     LB1           RB2
     
     Traverse rectangle in clockwise order, starting at LT1
     L = Left
     R = Right
     T = Top
     B = Bottom
     1,2 = order of traversal for any given corner
     
     */
    
    UIBezierPath *popoverPath = [UIBezierPath bezierPath];
    [popoverPath moveToPoint:CGPointMake(CGRectGetMinX(frame), CGRectGetMinY(frame) + radius)];//LT1
    [popoverPath addCurveToPoint:CGPointMake(xMin + radius, yMin) controlPoint1:CGPointMake(xMin, yMin + radius - cpOffset) controlPoint2:CGPointMake(xMin + radius - cpOffset, yMin)];//LT2
    
    //If the popover is positioned below (!above) the arrowPoint, then we know that the arrow must be on the top of the popover.
    //In this case, the arrow is located between LT2 and RT1
    if (self.showArrow && !above) {
        [popoverPath addLineToPoint:CGPointMake(arrowPoint.x - self.arrowHeight, yMin)];//left side
        [popoverPath addCurveToPoint:arrowPoint controlPoint1:CGPointMake(arrowPoint.x - self.arrowHeight + self.arrowCurvature, yMin) controlPoint2:arrowPoint];//actual arrow point
        [popoverPath addCurveToPoint:CGPointMake(arrowPoint.x + self.arrowHeight, yMin) controlPoint1:arrowPoint controlPoint2:CGPointMake(arrowPoint.x + self.arrowHeight - self.arrowCurvature, yMin)];//right side
    }
    
    [popoverPath addLineToPoint:CGPointMake(xMax - radius, yMin)];//RT1
    [popoverPath addCurveToPoint:CGPointMake(xMax, yMin + radius) controlPoint1:CGPointMake(xMax - radius + cpOffset, yMin) controlPoint2:CGPointMake(xMax, yMin + radius - cpOffset)];//RT2
    [popoverPath addLineToPoint:CGPointMake(xMax, yMax - radius)];//RB1
    [popoverPath addCurveToPoint:CGPointMake(xMax - radius, yMax) controlPoint1:CGPointMake(xMax, yMax - radius + cpOffset) controlPoint2:CGPointMake(xMax - radius + cpOffset, yMax)];//RB2
    
    //If the popover is positioned above the arrowPoint, then we know that the arrow must be on the bottom of the popover.
    //In this case, the arrow is located somewhere between LB1 and RB2
    if (self.showArrow && above) {
        [popoverPath addLineToPoint:CGPointMake(arrowPoint.x + self.arrowHeight, yMax)];//right side
        [popoverPath addCurveToPoint:arrowPoint controlPoint1:CGPointMake(arrowPoint.x + self.arrowHeight - self.arrowCurvature, yMax) controlPoint2:arrowPoint];//arrow point
        [popoverPath addCurveToPoint:CGPointMake(arrowPoint.x - self.arrowHeight, yMax) controlPoint1:arrowPoint controlPoint2:CGPointMake(arrowPoint.x - self.arrowHeight + self.arrowCurvature, yMax)];
    }
    
    [popoverPath addLineToPoint:CGPointMake(xMin + radius, yMax)];//LB1
    [popoverPath addCurveToPoint:CGPointMake(xMin, yMax - radius) controlPoint1:CGPointMake(xMin + radius - cpOffset, yMax) controlPoint2:CGPointMake(xMin, yMax - radius + cpOffset)];//LB2
    [popoverPath closePath];
    
    //// General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Shadow Declarations
    UIColor* shadow = [UIColor colorWithWhite:0.0f alpha:self.shadowAlpha];
    CGSize shadowOffset = CGSizeMake(0, 1);
    CGFloat shadowBlurRadius = self.shadowBlur;
    
    //// Gradient Declarations
    NSArray* gradientColors = [NSArray arrayWithObjects:
                               (id)self.gradientTopColor.CGColor,
                               (id)self.gradientBottomColor.CGColor, nil];
    CGFloat gradientLocations[] = {0, 1};
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)gradientColors, gradientLocations);
    
    
    //These floats are the top and bottom offsets for the gradient drawing so the drawing includes the arrows.
    float bottomOffset = (self.showArrow && above ? self.arrowHeight : 0.f);
    float topOffset = (self.showArrow && !above ? self.arrowHeight : 0.f);
    
    //Draw the actual gradient and shadow.
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, shadowOffset, shadowBlurRadius, shadow.CGColor);
    CGContextBeginTransparencyLayer(context, NULL);
    [popoverPath addClip];
    CGContextDrawLinearGradient(context, gradient, CGPointMake(CGRectGetMidX(frame), CGRectGetMinY(frame) - topOffset), CGPointMake(CGRectGetMidX(frame), CGRectGetMaxY(frame) + bottomOffset), 0);
    CGContextEndTransparencyLayer(context);
    CGContextRestoreGState(context);
    
    //// Cleanup
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    
    
    //Draw the title background
    if (self.drawTitleGradient) {
        //Calculate the height of the title bg
        float titleBGHeight = -1;
        
        //NSLog(@"titleView:%@", titleView);
        
        if (_titleView != nil) {
            titleBGHeight = self.boxPadding*2.f + _titleView.frame.size.height;
        }
        
        
        //Draw the title bg height, but only if we need to.
        if (titleBGHeight > 0.f) {
            CGPoint startingPoint = CGPointMake(xMin, yMin + titleBGHeight);
            CGPoint endingPoint = CGPointMake(xMax, yMin + titleBGHeight);
            
            UIBezierPath *titleBGPath = [UIBezierPath bezierPath];
            [titleBGPath moveToPoint:startingPoint];
            [titleBGPath addLineToPoint:CGPointMake(CGRectGetMinX(frame), CGRectGetMinY(frame) + radius)];//LT1
            [titleBGPath addCurveToPoint:CGPointMake(xMin + radius, yMin) controlPoint1:CGPointMake(xMin, yMin + radius - cpOffset) controlPoint2:CGPointMake(xMin + radius - cpOffset, yMin)];//LT2
            
            //If the popover is positioned below (!above) the arrowPoint, then we know that the arrow must be on the top of the popover.
            //In this case, the arrow is located between LT2 and RT1
            if (self.showArrow && !above) {
                [titleBGPath addLineToPoint:CGPointMake(arrowPoint.x - self.arrowHeight, yMin)];//left side
                [titleBGPath addCurveToPoint:arrowPoint controlPoint1:CGPointMake(arrowPoint.x - self.arrowHeight + self.arrowCurvature, yMin) controlPoint2:arrowPoint];//actual arrow point
                [titleBGPath addCurveToPoint:CGPointMake(arrowPoint.x + self.arrowHeight, yMin) controlPoint1:arrowPoint controlPoint2:CGPointMake(arrowPoint.x + self.arrowHeight - self.arrowCurvature, yMin)];//right side
            }
            
            [titleBGPath addLineToPoint:CGPointMake(xMax - radius, yMin)];//RT1
            [titleBGPath addCurveToPoint:CGPointMake(xMax, yMin + radius) controlPoint1:CGPointMake(xMax - radius + cpOffset, yMin) controlPoint2:CGPointMake(xMax, yMin + radius - cpOffset)];//RT2
            [titleBGPath addLineToPoint:endingPoint];
            [titleBGPath addLineToPoint:startingPoint];
            [titleBGPath closePath];
            
            //// General Declarations
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGContextRef context = UIGraphicsGetCurrentContext();
            
            //// Gradient Declarations
            NSArray* gradientColors = [NSArray arrayWithObjects:
                                       (id)self.gradientTitleTopColor.CGColor,
                                       (id)self.gradientTitleBottomColor.CGColor, nil];
            CGFloat gradientLocations[] = {0, 1};
            CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)gradientColors, gradientLocations);
            
            
            //These floats are the top and bottom offsets for the gradient drawing so the drawing includes the arrows.
            float topOffset = (self.showArrow && !above ? self.arrowHeight : 0.f);
            
            //Draw the actual gradient and shadow.
            CGContextSaveGState(context);
            CGContextBeginTransparencyLayer(context, NULL);
            [titleBGPath addClip];
            CGContextDrawLinearGradient(context, gradient, CGPointMake(CGRectGetMidX(frame), CGRectGetMinY(frame) - topOffset), CGPointMake(CGRectGetMidX(frame), CGRectGetMinY(frame) + titleBGHeight), 0);
            CGContextEndTransparencyLayer(context);
            CGContextRestoreGState(context);
            
            UIBezierPath *dividerLine = [UIBezierPath bezierPathWithRect:CGRectMake(startingPoint.x, startingPoint.y, (endingPoint.x - startingPoint.x), 0.5f)];
            [[UIColor colorWithRed:0.741 green:0.741 blue:0.741 alpha:0.5f] setFill];
            [dividerLine fill];
            
            //// Cleanup
            CGGradientRelease(gradient);
            CGColorSpaceRelease(colorSpace);
        }
    }
    
    
    
    //Draw the divider rects if we need to
    {
        if (self.showDividersBetweenViews && showDividerRects) {
            if (dividerRects && dividerRects.count > 0) {
                for (NSValue *value in dividerRects) {
                    CGRect rect = value.CGRectValue;
                    rect.origin.x += _contentView.frame.origin.x;
                    rect.origin.y += _contentView.frame.origin.y;
                    
                    UIBezierPath *dividerPath = [UIBezierPath bezierPathWithRect:rect];
                    [self.dividerColor setFill];
                    [dividerPath fill];
                }
            }
        }
    }
    
    //Draw border if we need to
    //The border is done last because it needs to be drawn on top of everything else
    if (self.drawBorder) {
        [self.borderColor setStroke];
        popoverPath.lineWidth = self.borderWidth;
        [popoverPath stroke];
    }
    
}

@end
