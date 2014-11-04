//
//  BTSelectorItem.swift
//  BTDetectionModeller
//
//  Created by David Brian Sinex on 2014-11-03.
//  Copyright (c) 2014 David Brian Sinex. All rights reserved.
//

import UIKit

func == (lhs: BTSelectorItem, rhs: BTSelectorItem) -> Bool {
    
    
    return lhs==rhs
}

class BTSelectorItem: NSObject,Equatable {
    var displayValue:String
    var selectValue:String
    var imageURL:String?
    var image:UIImage?
    var selected:Bool!
    
    // Init with a simple value and no image
    init(displayVal: String){
        displayValue = displayVal
        selectValue = displayVal
        selected = false
    }
    
    // Init with a display value that is different from actual value and with optional image
    init(displayVal: String, selectVal: String, imageURL: UIImage){
        displayValue = displayVal
        selectValue = selectVal
        image = imageURL
        selected = false
    }
    
    init(displayVal: String, selectVal: String, image: String){
        displayValue = displayVal
        selectValue = selectVal
        imageURL = image
        selected = false
    }
    func compareByDisplayValue(other:BTSelectorItem) -> NSComparisonResult{
    
        return NSComparisonResult.OrderedAscending
    }
}
