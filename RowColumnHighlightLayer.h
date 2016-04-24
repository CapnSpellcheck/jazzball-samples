//
//  RowColumnHighlightLayer.h
//  JazzBall
//
//  Created by Julez on 1/28/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NoActionLayer.h"

typedef enum {
    HighlightDirectionRow,
    HighlightDirectionColumn
} RowColumnHighlightDirection;


@interface RowColumnHighlightLayer : NoActionLayer {
    RowColumnHighlightDirection direction;
    CGFloat midpoint;
    CGFloat* redColor, * blueColor;
}

@property (nonatomic, assign) RowColumnHighlightDirection direction;
@property (nonatomic, assign) CGFloat midpoint;


@end
