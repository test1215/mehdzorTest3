//
//  ViewController.m
//  mehdzorTest3
//
//  Created by M on 27.02.15.
//  Copyright (c) 2015 M. All rights reserved.
//

#import "ViewController.h"

static const CGFloat kViewWidthMin = 40.0; // NOTE: минимальный размер "клетки" увеличен с 10 до 40 поинтов
static const CGFloat kViewHeightMin = 40.0;

@interface ViewController ()

@property (nonatomic, strong) NSSet *viewsSet;
@property (nonatomic, strong) UITouch *touchCurrent;
@property (nonatomic) CGPoint touchPointPrev;
@property (nonatomic, strong) UIView *viewCurrent;

@end

@implementation ViewController

#pragma mark - View Controller Lifecycle -

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setViewsSet];
    
    if (![self testField]) {
        [self showBadFieldAlert];
    }
}

#pragma mark - Touches -

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches) {
        self.viewCurrent = [self touchedView:touch];
        if (!self.viewCurrent) {
            self.touchCurrent = nil;
            return;
        }
        self.touchCurrent = touch;
        self.touchPointPrev = [touch locationInView:self.view];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!self.touchCurrent) {
        return;
    }
    
    for (UITouch *touch in touches) {
        if (touch != self.touchCurrent) {
            continue;
        }
        
        CGPoint touchPoint = [touch locationInView:self.viewCurrent];
        const CGSize viewCurrentSize = self.viewCurrent.frame.size;
        if (touchPoint.x < 0 || touchPoint.y < 0 || touchPoint.x > viewCurrentSize.width || touchPoint.y > viewCurrentSize.height) {
            self.touchCurrent = nil;
            return;
        }
        
        touchPoint = [touch locationInView:self.view];
        const CGVector direction = {.dx = touchPoint.x - self.touchPointPrev.x, .dy = touchPoint.y - self.touchPointPrev.y};
        self.touchPointPrev = touchPoint;
        
        // X
        
        if (direction.dx) {
            
            if (direction.dx > 0) { // ➡️
                
                NSSet *col = [self colForView:self.viewCurrent];
                for (UIView *view in col) {
                    [self moveView:view toTheRight:direction.dx];
                }
                
            } else { // ⬅️
                
                NSSet *col = [self colForView:self.viewCurrent];
                for (UIView *view in col) {
                    [self moveView:view toTheLeft:direction.dx];
                }
            }
            
        }
        
        // Y
        
        if (direction.dy) {
            
            if (direction.dy > 0) { // ⬇️
                
                NSSet *row = [self rowForView:self.viewCurrent];
                for (UIView *view in row) {
                    [self moveView:view toTheDown:direction.dy];
                }
                
            } else { // ⬆️
                
                NSSet *row = [self rowForView:self.viewCurrent];
                for (UIView *view in row) {
                    [self moveView:view toTheUp:direction.dy];
                }
            }
            
        }
        
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.touchCurrent = nil;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:event];
}

#pragma mark -

- (UIView *)touchedView:(UITouch *)touch
{
    for (UIView *view in self.viewsSet) {
        const CGPoint touchPoint = [touch locationInView:view];
        if (touchPoint.x < 0 || touchPoint.x > view.frame.size.width) {
            continue;
        }
        if (touchPoint.y < 0 || touchPoint.y > view.frame.size.height) {
            continue;
        }
        return view;
    }
    return nil;
}

#pragma mark - Moves -

- (void)moveView:(UIView *)view toTheRight:(CGFloat)dx
{
    if (!view) {
        return;
    }
    
    NSSet *rowRight = [self viewsInTheRowToTheRightOf:view];
    const CGFloat widthRightMin = rowRight.count * kViewWidthMin;
    const CGFloat widthRight = [self sizeOfViews:rowRight].width;
    
    if (widthRight == widthRightMin) { // все соседи по направлению движения схлопнуты до минимального размера или отсутствуют
        if (view.frame.size.width > kViewWidthMin) {
            [self moveView:[self viewNextToTheLeftOf:view] toTheRight:dx];
        }
        return;
    }
    
    if (dx > widthRight - widthRightMin) {
        dx = widthRight - widthRightMin;
    }
    
    if (dx) {
        view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width + dx, view.frame.size.height);
        
        UIView *viewCur = view;
        while (dx) {
            UIView *viewNext = [self viewNextToTheRightOf:viewCur];
            dx = [self view:viewNext compressLeftSide:dx];
            if (dx) {
                [self view:viewNext shiftHorizontally:dx];
            }
            viewCur = viewNext;
        }
    }
}

- (void)moveView:(UIView *)view toTheLeft:(CGFloat)dx
{
    if (!view) {
        return;
    }
    
    NSSet *rowLeft = [self viewsInTheRowToTheLeftOf:view];
    const CGFloat widthLeftMin = rowLeft.count * kViewWidthMin;
    const CGFloat widthLeft = [self sizeOfViews:rowLeft].width;
    
    if (widthLeft == widthLeftMin) { // все соседи по направлению движения схлопнуты до минимального размера или отсутствуют
        if (view.frame.size.width > kViewWidthMin) {
            [self moveView:[self viewNextToTheRightOf:view] toTheLeft:dx];
        }
        return;
    }
    
    if (dx < widthLeftMin - widthLeft) {
        dx = widthLeftMin - widthLeft;
    }
    
    if (dx) {
        view.frame = CGRectMake(view.frame.origin.x + dx, view.frame.origin.y, view.frame.size.width - dx, view.frame.size.height);
        
        UIView *viewCur = view;
        while (dx) {
            UIView *viewNext = [self viewNextToTheLeftOf:viewCur];
            dx = -([self view:viewNext compressRightSide:-dx]);
            if (dx) {
                [self view:viewNext shiftHorizontally:dx];
            }
            viewCur = viewNext;
        }
    }
}

- (void)moveView:(UIView *)view toTheDown:(CGFloat)dy
{
    if (!view) {
        return;
    }
    
    NSSet *colBot = [self viewsInTheColToTheBotOf:view];
    const CGFloat heightBotMin = colBot.count * kViewHeightMin;
    const CGFloat heightBot = [self sizeOfViews:colBot].height;
    
    if (heightBot == heightBotMin) { // все соседи по направлению движения схлопнуты до минимального размера или отсутствуют
        if (view.frame.size.height > kViewHeightMin) {
            [self moveView:[self viewNextToTheTopOf:view] toTheDown:dy];
        }
        return;
    }
    
    if (dy > heightBot - heightBotMin) {
        dy = heightBot - heightBotMin;
    }
    
    NSAssert(dy >= 0, @"diffY < 0");
    
    if (dy) {
        view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, view.frame.size.height + dy);
        
        UIView *viewCur = view;
        while (dy) {
            UIView *viewNext = [self viewNextToTheBotOf:viewCur];
            dy = [self view:viewNext compressUpSide:dy];
            NSAssert(dy >= 0, @"diffY < 0");
            if (dy) {
                [self view:viewNext shiftVertically:dy];
            }
            viewCur = viewNext;
        }
    }
}

- (void)moveView:(UIView *)view toTheUp:(CGFloat)dy
{
    if (!view) {
        return;
    }
    
    NSSet *colTop = [self viewsInTheRowToTheUpOf:view];
    const CGFloat heightTopMin = colTop.count * kViewHeightMin;
    const CGFloat heightTop = [self sizeOfViews:colTop].height;
    
    if (heightTop == heightTopMin) { // все соседи по направлению движения схлопнуты до минимального размера или отсутствуют
        if (view.frame.size.height > kViewHeightMin) {
            [self moveView:[self viewNextToTheBotOf:view] toTheUp:dy];
        }
        return;
    }
    
    if (dy < heightTopMin - heightTop) {
        dy = heightTopMin - heightTop;
    }
    
    if (dy) {
        view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y + dy, view.frame.size.width, view.frame.size.height - dy);
        
        UIView *viewCur = view;
        while (dy) {
            UIView *viewNext = [self viewNextToTheTopOf:viewCur];
            dy = -([self view:viewNext compressDownSide:-dy]);
            if (dy) {
                [self view:viewNext shiftVertically:dy];
            }
            viewCur = viewNext;
        }
    }
}

#pragma mark -

- (CGFloat)view:(UIView *)view compressLeftSide:(CGFloat)dx
{
    CGFloat r = 0;
    if (dx > view.frame.size.width - kViewWidthMin) {
        r = dx - (view.frame.size.width - kViewWidthMin);
        dx = view.frame.size.width - kViewWidthMin;
    }
    if (dx) {
        view.frame = CGRectMake(view.frame.origin.x + dx, view.frame.origin.y, view.frame.size.width - dx, view.frame.size.height);
    }
    return r;
}

- (CGFloat)view:(UIView *)view compressUpSide:(CGFloat)dy
{
    CGFloat r = 0;
    if (dy > view.frame.size.height - kViewHeightMin) {
        r = dy - (view.frame.size.height - kViewHeightMin);
        dy = view.frame.size.height - kViewHeightMin;
    }
    if (dy) {
        view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y + dy, view.frame.size.width, view.frame.size.height - dy);
    }
    return r;
}

- (CGFloat)view:(UIView *)view compressRightSide:(CGFloat)dx
{
    NSAssert(dx > 0, @"dx <= 0"); // NOTE: передавать положительное смещение
    
    CGFloat r = 0;
    if (dx > view.frame.size.width - kViewWidthMin) {
        r = dx - (view.frame.size.width - kViewWidthMin);
        dx = view.frame.size.width - kViewWidthMin;
    }
    if (dx) {
        view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width - dx, view.frame.size.height);
    }
    return r;
}

- (CGFloat)view:(UIView *)view compressDownSide:(CGFloat)dy
{
    NSAssert(dy > 0, @"dy <= 0"); // NOTE: передавать положительное смещение
    
    CGFloat r = 0;
    if (dy > view.frame.size.height - kViewHeightMin) {
        r = dy - (view.frame.size.height - kViewHeightMin);
        dy = view.frame.size.height - kViewHeightMin;
    }
    if (dy) {
        view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, view.frame.size.height - dy);
    }
    return r;
}

#pragma mark -

- (void)view:(UIView *)view shiftHorizontally:(CGFloat)dx
{
    view.frame = (CGRect){.origin.x = view.frame.origin.x + dx, .origin.y = view.frame.origin.y, .size = view.frame.size};
}

- (void)view:(UIView *)view shiftVertically:(CGFloat)dy
{
    view.frame = (CGRect){.origin.x = view.frame.origin.x, .origin.y = view.frame.origin.y + dy, .size = view.frame.size};
}

#pragma mark - Views Set -

#pragma mark - setup

- (void)setViewsSet
{
    NSMutableSet *viewsSet = [NSMutableSet set];
    for (UIView *view in self.view.subviews) {
        if ([view isMemberOfClass:[UIView class]]) {
            [viewsSet addObject:view];
        }
    }
    self.viewsSet = [NSSet setWithSet:viewsSet];
}

- (BOOL)testField
{
    UIView *firstView = [self firstView];
    if (!firstView) {
        return NO;
    }
    
    // test first row: все клетки строки имеют одинаковую высоту, не пересекаются и прилегают друг к другу
    
    CGFloat rowWidth = firstView.frame.size.width;
    NSSet *firstRow = [self rowForView:firstView];
    for (UIView *view in firstRow) {
        if (view == firstView) {
            continue;
        }
        if (view.frame.size.height != firstView.frame.size.height) {
            return NO;
        }
        for (UIView *view1 in firstRow) {
            if (view != view1) {
                if (CGRectIntersectsRect(view.frame, view1.frame)) {
                    return NO;
                }
            }
        }
        CGRect rectUnion = CGRectUnion(firstView.frame, view.frame);
        if (rowWidth < rectUnion.size.width) {
            rowWidth = rectUnion.size.width;
        }
    }
    
    if (rowWidth != [self sizeOfViews:firstRow].width) {
        return NO;
    }
    
    // test first col
    
    CGFloat colHeight = firstView.frame.size.height;
    NSSet *firstCol = [self colForView:firstView];
    for (UIView *view in firstCol) {
        if (view == firstView) {
            continue;
        }
        if (view.frame.size.width != firstView.frame.size.width) {
            return NO;
        }
        for (UIView *view1 in firstCol) {
            if (view != view1) {
                if (CGRectIntersectsRect(view.frame, view1.frame)) {
                    return NO;
                }
            }
        }
        CGRect rectUnion = CGRectUnion(firstView.frame, view.frame);
        if (colHeight < rectUnion.size.height) {
            colHeight = rectUnion.size.height;
        }
    }
    
    if (colHeight != [self sizeOfViews:firstCol].height) {
        return NO;
    }
    
    //
    
    if (firstRow.count * firstCol.count != self.viewsSet.count) {
        return NO;
    }
    
    // test other rows: одинаковая клеток в строке + origin.x должны совпадать с первой строкой
    
    for (UIView *colView in firstCol) {
        if (colView == firstView) {
            continue;
        }
        NSSet *row = [self rowForView:colView];
        if (row.count != firstRow.count) {
            return NO;
        }
        
        NSMutableSet *firstRowCopy = [firstRow mutableCopy];
        UIView *rowView = nil;
        for (UIView *view in row) {
            if (!rowView) {
                rowView = view;
            } else if (view.frame.size.height != rowView.frame.size.height) {
                return NO;
            }
            BOOL f = NO;
            for (UIView *firstRowView in firstRowCopy) {
                if (view.frame.origin.x == firstRowView.frame.origin.x) {
                    [firstRowCopy removeObject:firstRowView];
                    f = YES;
                    break;
                }
            }
            if (!f) {
                return NO;
            }
        }
    }
    
    // test other colums
    
    for (UIView *rowView in firstRow) {
        if (rowView == firstView) {
            continue;
        }
        NSSet *col = [self colForView:rowView];
        if (col.count != firstCol.count) {
            return NO;
        }
        
        NSMutableSet *firstColCopy = [firstCol mutableCopy];
        UIView *colView = nil;
        for (UIView *view in col) {
            if (!colView) {
                colView = view;
            } else if (view.frame.size.width != colView.frame.size.width) {
                return NO;
            }
            BOOL f = NO;
            for (UIView *firstColView in firstColCopy) {
                if (view.frame.origin.y == firstColView.frame.origin.y) {
                    [firstColCopy removeObject:firstColView];
                    f = YES;
                    break;
                }
            }
            if (!f) {
                return NO;
            }
        }
    }
    
    return YES;
}

#pragma mark -

- (CGSize)sizeOfViews:(NSSet *)views
{
    CGSize size = {0, 0};
    for (UIView * view in views) {
        size.width += view.frame.size.width;
        size.height += view.frame.size.height;
    }
    return size;
}

- (UIView *)firstView
{
    UIView *firstView = nil;
    for (UIView *view in self.viewsSet) {
        if (!firstView) {
            firstView = view;
            continue;
        }
        if (view.frame.origin.x < firstView.frame.origin.x || view.frame.origin.y < firstView.frame.origin.y) {
            firstView = view;
        }
    }
    return firstView;
}

#pragma mark - rows

- (NSSet *)rowForView:(UIView *)keyView
{
    NSMutableSet *r = [NSMutableSet set];
    for (UIView *view in self.viewsSet) {
        if (view.frame.origin.y == keyView.frame.origin.y) {
            [r addObject:view];
        }
    }
    return r;
}

- (NSSet *)viewsInTheRowToTheRightOf:(UIView *)keyView
{
    NSMutableSet *r = [NSMutableSet set];
    NSSet *row = [self rowForView:keyView];
    for (UIView *view in row) {
        if (view.frame.origin.x > keyView.frame.origin.x) {
            [r addObject:view];
        }
    }
    return r;
}

- (UIView *)viewNextToTheRightOf:(UIView *)keyView
{
    UIView *r = nil;
    NSSet *row = [self viewsInTheRowToTheRightOf:keyView];
    for (UIView *view in row) {
        if (!r) {
            r = view;
            continue;
        }
        if (view.frame.origin.x < r.frame.origin.x) {
            r = view;
        }
    }
    return r;
}

- (NSSet *)viewsInTheRowToTheLeftOf:(UIView *)keyView
{
    NSMutableSet *r = [NSMutableSet set];
    NSSet *row = [self rowForView:keyView];
    for (UIView *view in row) {
        if (view.frame.origin.x < keyView.frame.origin.x) {
            [r addObject:view];
        }
    }
    return r;
}

- (UIView *)viewNextToTheLeftOf:(UIView *)keyView
{
    UIView *r = nil;
    NSSet *row = [self viewsInTheRowToTheLeftOf:keyView];
    for (UIView *view in row) {
        if (!r) {
            r = view;
            continue;
        }
        if (view.frame.origin.x > r.frame.origin.x) {
            r = view;
        }
    }
    return r;
}

#pragma mark - cols

- (NSSet *)colForView:(UIView *)keyView
{
    NSMutableSet *r = [NSMutableSet set];
    for (UIView *view in self.viewsSet) {
        if (view.frame.origin.x == keyView.frame.origin.x) {
            [r addObject:view];
        }
    }
    return r;
}

- (NSSet *)viewsInTheColToTheBotOf:(UIView *)keyView
{
    NSMutableSet *r = [NSMutableSet set];
    NSSet *col = [self colForView:keyView];
    for (UIView *view in col) {
        if (view.frame.origin.y > keyView.frame.origin.y) {
            [r addObject:view];
        }
    }
    return r;
}

- (UIView *)viewNextToTheBotOf:(UIView *)keyView
{
    NSSet *col = [self viewsInTheColToTheBotOf:keyView];
    UIView *r = nil;
    for (UIView *view in col) {
        if (!r) {
            r = view;
            continue;
        }
        if (view.frame.origin.y < r.frame.origin.y) {
            r = view;
        }
    }
    return r;
}

- (NSSet *)viewsInTheRowToTheUpOf:(UIView *)keyView
{
    NSMutableSet *r = [NSMutableSet set];
    NSSet *col = [self colForView:keyView];
    for (UIView *view in col) {
        if (view.frame.origin.y < keyView.frame.origin.y) {
            [r addObject:view];
        }
    }
    return r;
}

- (UIView *)viewNextToTheTopOf:(UIView *)keyView
{
    UIView *r = nil;
    NSSet *col = [self viewsInTheRowToTheUpOf:keyView];
    for (UIView *view in col) {
        if (!r) {
            r = view;
            continue;
        }
        if (view.frame.origin.y > r.frame.origin.y) {
            r = view;
        }
    }
    return r;
}

#pragma mark - Alert Error -

- (void)showBadFieldAlert
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Bad Field"
                                                    message:@"Field isn't valid :(" "\n" "Fix and restart."
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    exit(0);
}

@end

