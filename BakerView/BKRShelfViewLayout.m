//
//  BKRShelfViewLayout.m
//  Baker
//
//  Created by Tobias Strebitzer on 10/11/14.
//
//

#import "BKRShelfViewLayout.h"

@implementation BKRShelfViewLayout

- (id)initWithSticky:(BOOL)sticky stretch:(BOOL)stretch {
    
    self = [super init];
    if (self) {
        _isSticky = sticky;
        _isStretch = stretch;
    }

    return self;
}

- (NSArray *) layoutAttributesForElementsInRect:(CGRect)rect {
    
    // Get attributes
    NSMutableArray *attributes = [[super layoutAttributesForElementsInRect:rect] mutableCopy];

    // Sticky header
    if(_isSticky) {
        NSMutableIndexSet *missingSections = [NSMutableIndexSet indexSet];
        for (NSUInteger idx=0; idx<[attributes count]; idx++) {
            UICollectionViewLayoutAttributes *layoutAttributes = attributes[idx];
            
            if (layoutAttributes.representedElementCategory == UICollectionElementCategoryCell) {
                [missingSections addIndex:layoutAttributes.indexPath.section];
            }
            if ([layoutAttributes.representedElementKind isEqualToString:UICollectionElementKindSectionHeader]) {
                [attributes removeObjectAtIndex:idx];
                idx--;
            }
        }
        
        // layout all headers needed for the rect
        [missingSections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:idx];
            UICollectionViewLayoutAttributes *layoutAttributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:indexPath];
            if (layoutAttributes != nil) {
                [attributes addObject:layoutAttributes];
            }
        }];
    }

    // Stretch header
    if(_isStretch) {
        // Calculate offset
        UICollectionView *collectionView = [self collectionView];
        UIEdgeInsets insets = [collectionView contentInset];
        CGPoint offset = [collectionView contentOffset];
        CGFloat minY = -insets.top;
        
        // Check if we've pulled below past the lowest position
        if (offset.y < minY) {
            
            // Figure out how much we've pulled down
            CGFloat deltaY = fabsf(offset.y - minY);
            
            for (UICollectionViewLayoutAttributes *attrs in attributes) {
                
                // Locate the header attributes
                NSString *kind = [attrs representedElementKind];
                if (kind == UICollectionElementKindSectionHeader) {
                    
                    // Adjust the header's height and y based on how much the user
                    // has pulled down.
                    CGSize headerSize = [self headerReferenceSize];
                    CGRect headerRect = [attrs frame];
                    headerRect.size.height = MAX(minY, headerSize.height + deltaY);
                    headerRect.origin.y = headerRect.origin.y - deltaY;
                    [attrs setFrame:headerRect];
                    break;
                }
            }
        }
    }
    
    return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForSupplementaryViewOfKind:kind atIndexPath:indexPath];
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        UICollectionView * const cv = self.collectionView;
        CGPoint const contentOffset = cv.contentOffset;
        CGPoint nextHeaderOrigin = CGPointMake(INFINITY, INFINITY);
        
        if (indexPath.section+1 < [cv numberOfSections]) {
            UICollectionViewLayoutAttributes *nextHeaderAttributes = [super layoutAttributesForSupplementaryViewOfKind:kind atIndexPath:[NSIndexPath indexPathForItem:0 inSection:indexPath.section+1]];
            nextHeaderOrigin = nextHeaderAttributes.frame.origin;
        }
        
        CGRect frame = attributes.frame;
        if (self.scrollDirection == UICollectionViewScrollDirectionVertical) {
            frame.origin.y = MIN(MAX(contentOffset.y, frame.origin.y), nextHeaderOrigin.y - CGRectGetHeight(frame));
        }
        else { // UICollectionViewScrollDirectionHorizontal
            frame.origin.x = MIN(MAX(contentOffset.x, frame.origin.x), nextHeaderOrigin.x - CGRectGetWidth(frame));
        }
        attributes.zIndex = 1024;
        attributes.frame = frame;
    }
    return attributes;
}
 
- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForSupplementaryViewOfKind:kind atIndexPath:indexPath];
    return attributes;
}
- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForSupplementaryViewOfKind:kind atIndexPath:indexPath];
    return attributes;
}

- (BOOL) shouldInvalidateLayoutForBoundsChange:(CGRect)newBound {
    return YES;
}

- (UICollectionViewScrollDirection)scrollDirection {
    return UICollectionViewScrollDirectionVertical;
}

@end
