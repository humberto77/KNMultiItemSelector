//
//  BTMultiItemSelector.swift
//  BTDetectionModeller
//
//  Created by David Brian Sinex on 2014-11-03.
//  Copyright (c) 2014 David Brian Sinex. All rights reserved.
//

import UIKit

enum BTSelectorMode{
    case Normal
    case Search
    case Selected
    case Mode
}

protocol BTMultiSelectorDelegate{
    func selectorDidCancelSelection()
    func selector(selector: BTMultiItemSelector, didFinishSelectionWithItems selectedItems: [BTSelectorItem])
    func selectorSelect(selector: BTMultiItemSelector, didSelectItem selectedItems: BTSelectorItem)
    func selectorDeselect(selector: BTMultiItemSelector, didDeselectItem deselectedItem: BTSelectorItem)
}

//class BTMultiItemSelector: UIViewController{

class BTMultiItemSelector: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    // interface
    var items:[BTSelectorItem]?
    var filteredItems:[BTSelectorItem]?
    var recentItems:[BTSelectorItem]!
    var indices:[String:[BTSelectorItem]]!
    
    var normalModeButton: UIButton!
    var selectedModeButton: UIButton!
    var modeIndicatorImageView: UIImageView!
    var textFieldWrapper: UIView!
    
    var maximumItemsSelected: Int?
    var tag: Int?
    
    var selectorMode = BTSelectorMode.Normal
    var delegate: BTMultiSelectorDelegate?
    
    // public properties
    var tableView: UITableView!
    var searchTextField: UITextField!
    var selectedItems:[BTSelectorItem]{get{
        if items==nil{
            return [BTSelectorItem]()
        }else{
            return items!.filter({$0.selected! == true})
        }
        }}
//    private var _selectedItems:[BTSelectorItem]?
    
    // Turn on/off table index for items, default to NO
    var useTableIndex: Bool!
    
    // Turn on/off search field at the top of the list, default to NO, only recommend for large list
    var allowSearchControl: Bool!
    
    // Turn on/off mode buttons and tip view at the bottom, default to YES
    var allowModeButtons: Bool!
    
    // Turn on/off displaying and storing of recent selected items.
    // recentItemStorageKey   : If you have multiple selectors in your app, you need to set different storage key for each of the selectors.
    // maxNumberOfRecentItems : Defaults to 5.
    var useRecentItems: Bool!
    var recentItemsStorageKey: String!
    var maxNumberOfRecentItems: Int!
    
    private var placeholderText: String!
    
    convenience init(items: [BTSelectorItem], delegate: BTMultiSelectorDelegate){
        self.init(items: items, preselectedItems: nil, title: "Select items", placeholderText: "Search by keywords", delegate: delegate)
        
    }
    
    convenience init(items itemsin: [BTSelectorItem], preselectedItems preselectitems: [BTSelectorItem]?, title titlein: String, placeholderText placeholder: String, delegate delegateObject:BTMultiSelectorDelegate){
        self.init()
    
        
        delegate = delegateObject
        title = titlein
        maxNumberOfRecentItems = 5
        useRecentItems = false
        recentItemsStorageKey = "recent_selected_items"
        allowModeButtons = true
        allowSearchControl = true
        useTableIndex = false
        
        placeholderText = placeholder
        
        // Initialize item arrays
        items = itemsin
        
        if let auxitems = preselectitems{
            for item in itemsin{
                if contains(auxitems, item){
                    item.selected = true
                }
            }
        }
        
        // Recent selected items section
        recentItems = [BTSelectorItem]()
        let rArr = NSUserDefaults.standardUserDefaults().objectForKey(recentItemsStorageKey) as? [String]
            // Preparing indices and Recent items
            indices = [String:[BTSelectorItem]]()
            for item in itemsin{
                
                let letter = (item.displayValue as NSString).substringFromIndex(1)

                if (indices[letter] == nil){
                    indices[letter] = [BTSelectorItem]()
                }
                
                if rArr != nil{
                if contains(rArr!, item.selectValue){
                    recentItems.append(item)
                }
                }
                indices[letter]!.append(item)
            }
    }
    
    override func loadView() {
        //
        view = UIView(frame: CGRect.zeroRect)
        view.backgroundColor = UIColor.whiteColor()
        
        // Initialize tableView
        tableView = UITableView(frame: CGRect.zeroRect, style: UITableViewStyle.Plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
        view.addSubview(tableView)
        
        //Initialize search text field
        textFieldWrapper = UIView(frame: CGRect.zeroRect)
        textFieldWrapper.autoresizesSubviews = true
        textFieldWrapper.backgroundColor = UIColor.whiteColor()
        textFieldWrapper.layer.shadowColor = UIColor.blackColor().CGColor
        textFieldWrapper.layer.shadowOffset = CGSizeMake(0, 1)
        textFieldWrapper.layer.shadowRadius = 5.0
        textFieldWrapper.layer.shadowOpacity = 0.2
        searchTextField = UITextField(frame: CGRect.zeroRect)
        searchTextField.backgroundColor = UIColor.whiteColor()
        searchTextField.clipsToBounds = false
        searchTextField.keyboardType = UIKeyboardType.ASCIICapable
        searchTextField.autocorrectionType = UITextAutocorrectionType.No
        searchTextField.autocapitalizationType = UITextAutocapitalizationType.None
        searchTextField.returnKeyType = UIReturnKeyType.Done
        searchTextField.clearButtonMode = UITextFieldViewMode.Always
        searchTextField.autoresizingMask = UIViewAutoresizing.FlexibleWidth
        searchTextField.delegate = self
        searchTextField.leftView = UIImageView(image: UIImage(named: "KNZoomIcon"))
        searchTextField.leftViewMode = UITextFieldViewMode.Always
        searchTextField.placeholder = placeholderText
        searchTextField.contentVerticalAlignment = UIControlContentVerticalAlignment.Center
        textFieldWrapper.addSubview(searchTextField)
        view.addSubview(textFieldWrapper)
        
        // Image indicator
        modeIndicatorImageView = UIImageView(image: UIImage(named: "KNSelectorTip"))
        modeIndicatorImageView.autoresizingMask = UIViewAutoresizing.FlexibleTopMargin | UIViewAutoresizing.FlexibleWidth
        modeIndicatorImageView.contentMode = UIViewContentMode.Center
        view.addSubview(modeIndicatorImageView)
        
        // Two mode buttons
        normalModeButton = UIButton.buttonWithType(UIButtonType.Custom) as UIButton
        selectedModeButton = UIButton.buttonWithType(UIButtonType.Custom) as UIButton
        normalModeButton.setTitle("All", forState: UIControlState.Normal)
        normalModeButton.setTitleColor(UIColor.grayColor(), forState: UIControlState.Normal)
        selectedModeButton.setTitleColor(UIColor.grayColor(), forState: UIControlState.Normal)
        
        normalModeButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Selected)
        selectedModeButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Selected)
        normalModeButton.addTarget(self, action: Selector("modeButtonDidTouch:"), forControlEvents: UIControlEvents.TouchUpInside)
        selectedModeButton.addTarget(self, action: Selector("modeButtonDidTouch:"), forControlEvents: UIControlEvents.TouchUpInside)
        normalModeButton.titleLabel?.font = UIFont.boldSystemFontOfSize(13)
        selectedModeButton.titleLabel?.font = UIFont.boldSystemFontOfSize(13)
        normalModeButton.autoresizingMask = UIViewAutoresizing.FlexibleTopMargin
        selectedModeButton.autoresizingMask = UIViewAutoresizing.FlexibleTopMargin
        normalModeButton.selected  = true
        view.addSubview(normalModeButton)
        view.addSubview(selectedModeButton)
        updateSelectedCount()
        
        // Nav bar button
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: Selector("didFinish"))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: Selector("didCancel"))
        
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Layout UI elements
        var f = view.frame
        textFieldWrapper.frame = CGRectMake(0, 0, f.size.width, 44)
        searchTextField.frame = CGRectMake(6, 6, f.size.width-12, 32)
        
        // Show or hide search control
        
        textFieldWrapper.hidden = !allowSearchControl!
        if textFieldWrapper.hidden{
            tableView.frame = CGRectMake(0, 0, f.size.width, f.size.height - 40)
        }else{
            tableView.frame = CGRectMake(0, textFieldWrapper.frame.size.height, f.size.width, f.size.height  - textFieldWrapper.frame.size.height - 40)
        }
        
        let ver_float = NSString(string: UIDevice.currentDevice().systemVersion).floatValue
        if ver_float >= 7.0{
            navigationController?.navigationBar.translucent = false
        }
        
        normalModeButton.frame = CGRectMake(f.size.width/2 - 90, f.size.height - 44, 90, 44)
        selectedModeButton.frame = CGRectMake(f.size.width/2, f.size.height-44, 90, 44)
        modeIndicatorImageView.center = CGPointMake(normalModeButton.center.x, f.size.height - 44 + modeIndicatorImageView.frame.size.height/2)
        showHideModeButtons()
    }
    func showHideModeButtons(){
        normalModeButton.hidden = !allowModeButtons
        selectedModeButton.hidden = !allowModeButtons
        modeIndicatorImageView.hidden = !allowModeButtons
        var tableFrame = tableView.frame
        
        if allowModeButtons!{
            tableFrame.size.height = CGRectGetMinY(modeIndicatorImageView.frame) - CGRectGetMinY(tableFrame)
        }else{
            tableFrame.size.height = CGRectGetHeight(view.bounds) - CGRectGetMinY(tableFrame)
        }
        
        tableView.frame = tableFrame
    }
    func setAllowModeButtons(allow:Bool){
        allowModeButtons = allow
        showHideModeButtons()
    }
    func updateSelectedCount(){
        let cnt = selectedItems.count
        if cnt == 0{
            selectedModeButton?.setTitle("Selected (0)", forState: UIControlState.Normal)
        }else{
            selectedModeButton?.setTitle("Selected (\(cnt))", forState: UIControlState.Normal)
        }
    }
    
    // MARK: UITableView Datasource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if selectorMode == BTSelectorMode.Normal{
            var noSec:Int
            if useTableIndex!{
                noSec = sortedIndices().count
            }else{
                noSec = 1
            }
            if (useRecentItems! && (recentItems.count > 0)){
                return noSec + 1
            }else{
                return noSec
            }
        }else{
            return 1
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var auxsection = section
        if selectorMode == BTSelectorMode.Search{
            return filteredItems!.count
        }else if selectorMode == BTSelectorMode.Normal{
            
            if (useRecentItems! && section==0 && (recentItems.count > 0)){
                return recentItems.count
            }else if useTableIndex!{
                if (useRecentItems! && (recentItems.count > 0)) {
                    auxsection -= 1
                }
                
                let aux = sortedIndices()
                let rows = indices[aux[auxsection]]
                return rows!.count
            }else{
                return items!.count
            }
            
        }else{
            return selectedItems.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //
        let cellIdentifier = "BTSelectorItemCell"
        
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as? UITableViewCell
        if (cell == nil){
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: cellIdentifier)
        }
        
        // Which item?
        let item = itemAtIndexPath(indexPath) as BTSelectorItem
        
        // Change the cell appearance
        cell!.textLabel.text = item.displayValue
        if item.imageURL != nil{
            
//            [cell.imageView setImageWithURL:[NSURL URLWithString:item.imageUrl] placeholderImage:[UIImage imageNamed:@"KNDefaultImage"]];
            
            let url = NSURL(fileURLWithPath: item.imageURL!, isDirectory: false)
            cell!.imageView.image = UIImage(CIImage: CIImage(contentsOfURL: url))
        }
        
        if item.image != nil{
            cell!.imageView.image = item.image
        }
//        cell!.accessoryType = item.selected ? UITableViewCellAccessoryType.Checkmark : UITableViewCellAccessoryType.None
        if item.selected!{
            cell!.accessoryType = UITableViewCellAccessoryType.Checkmark
        }else{
            cell!.accessoryType = UITableViewCellAccessoryType.None
        }
        
        
        return cell!
    }
    
    
    // MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if (maximumItemsSelected > 0 && (selectedItems.count >= maximumItemsSelected && itemAtIndexPath(indexPath).selected == false)){
            let alertview = UIAlertView(title: "Hint", message: "You've reached the maximum number of selectable items", delegate: nil, cancelButtonTitle: "OK")
        }else{
            //Which item?
            let item = itemAtIndexPath(indexPath)
            item.selected = !item.selected
            
            // Recount selected items
            updateSelectedCount()
            
            // Update UI
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            
            if item.selected!{
                tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.Checkmark
            }else{
                tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.None
            }
            
            if searchTextField.isFirstResponder(){
                searchTextField.tag = 1
                searchTextField.resignFirstResponder()
            }
            
            // Delegate callback
            if item.selected!{
                delegate?.selectorSelect(self, didSelectItem: item)
            }else{
                delegate?.selectorDeselect(self, didDeselectItem: item)
                if selectorMode == BTSelectorMode.Selected{
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                }
            }
        }
    }
    
    // MARK: UITextField Delegate & Filtering
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        var searchString = NSString(string: textField.text).stringByReplacingCharactersInRange(range, withString: string)
        
        if countElements(searchString) > 0{
            selectorMode = BTSelectorMode.Search
//            let str2 = NSString(format: "*%@*", searchString)
//            let pred = NSPredicate(format: "displayValue LIKE[cd] %@ OR displayValue LIKE[cd] %@", NSString(string: searchString).stringByAppendingString("*"),str2)
            let pred = NSPredicate(format: "displayValue CONTAINS[cd] %@",searchString)
            
            filteredItems = (items! as NSArray).filteredArrayUsingPredicate(pred!) as? [BTSelectorItem]
        }else{
            selectorMode = BTSelectorMode.Normal
        }
        tableView.reloadData()
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    func textFieldShouldClear(textField: UITextField) -> Bool {
        selectorMode = BTSelectorMode.Normal
        tableView?.reloadData()
        return true
    }
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        if searchTextField?.tag == 1{
            searchTextField?.tag = 0
            searchTextField?.text = ""
        }
        return true
    }
    
    
    // MARK: Custom getters/setters
    
//    func selectedItems() -> [BTSelectorItem]{
////        let pred = NSPredicate(format: "selected = %@", true)
//        return items?.filter($0.selected == true)
//    }
    func sortedIndices() -> [String]{
        let aux = indices!.keys
        var ar = aux.array as [String]
        
        return ar.sorted({$0 < $1})
    }
    
    // MARK: Helpers
    func itemAtIndexPath(indexPath: NSIndexPath) -> BTSelectorItem{
        // Determine the correct item at different settings
        
        let r = indexPath.row
        var s = indexPath.section
        
        if selectorMode == BTSelectorMode.Search{
            if (useRecentItems! && (recentItems.count > 0) && s==0){
                return recentItems[r]
            }
            if useTableIndex!{
                if (useRecentItems! && (recentItems.count > 0)){
                    s -= 1
                }
                let rows = indices[sortedIndices()[s]]
                return rows![r]
            }
        }
        
        if selectorMode == BTSelectorMode.Selected{
            return selectedItems[r]
        }
        return items![r]
    }
    
    
    // MARK: Cancel or Done button event
    func didCancel(){
        //Clear all selections
        println("selected items: \(selectedItems)")
        let aux = selectedItems
        for item in aux{
            item.selected = false
        }
        
        delegate?.selectorDidCancelSelection()
    }
    
    func didFinish(){
        // Delegate callback
        delegate?.selector(self, didFinishSelectionWithItems: selectedItems)
        
        // Store recent items FIFO
        if (useRecentItems! && maxNumberOfRecentItems < items!.count){
            let defaults = NSUserDefaults.standardUserDefaults()
            var array = defaults.objectForKey(recentItemsStorageKey) as? [String]
            if array == nil{
                array = [String]()
            }
            
            for item in selectedItems{
                array!.insert(item.selectValue, atIndex: 0)
            }
            while (array!.count > maxNumberOfRecentItems){
                array!.removeLast()
            }
            defaults.setObject(array, forKey: recentItemsStorageKey)
            defaults.synchronize()
            
        }
        //
    }
    
    // MARK: Handle mode switching UI
    func modeButtonDidTouch(sender: AnyObject){
        let s = sender as UIButton
        
        if s.selected{
            return
        }
        
        if s == normalModeButton{
            
            if countElements(searchTextField!.text) > 0{
                selectorMode = BTSelectorMode.Search
            }else{
                selectorMode = BTSelectorMode.Normal
            }
            
            normalModeButton?.selected = true
            selectedModeButton?.selected = false
            tableView!.reloadData()
            UIView.animateWithDuration(0.3, animations: {
                if !self.textFieldWrapper!.hidden{
                    var f = self.tableView!.frame
                    f.origin.y = self.textFieldWrapper!.frame.size.height
                    f.size.height -= f.origin.y
                    self.tableView!.frame = f
                    self.textFieldWrapper!.alpha = 1
                }
                self.modeIndicatorImageView!.center = CGPointMake(self.normalModeButton!.center.x, self.modeIndicatorImageView!.center.y)
            })
        }else{
            selectorMode = BTSelectorMode.Selected
            normalModeButton?.selected = false
            selectedModeButton?.selected = true
            tableView!.reloadData()
            UIView.animateWithDuration(0.3, animations: {
                if !self.textFieldWrapper.hidden{
                    var f = self.tableView!.frame
                    f.origin.y = 0
                    f.size.height += self.textFieldWrapper!.frame.size.height
                    self.tableView!.frame = f
                    self.textFieldWrapper!.alpha = 0
                }
                self.modeIndicatorImageView!.center = CGPointMake(self.selectedModeButton!.center.x, self.modeIndicatorImageView!.center.y)
            })
        }
        
    }
    
    // MARK: Table indices
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        //
        var auxsection = section
        if selectorMode == BTSelectorMode.Normal{
            if (useRecentItems! && (recentItems.count > 0)){
                if section == 0{
                    return "Recent"
                }
                if !useTableIndex{
                    return " "
                }
            }
            
            if useTableIndex!{
                if (useRecentItems! && (recentItems.count > 0)){
                    auxsection -= 1
                }
                return sortedIndices()[auxsection]
            }
        }
        return nil
    }
    
    func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject]! {
        if (selectorMode == BTSelectorMode.Normal && useTableIndex!){
            
            if (useRecentItems! && (recentItems.count > 0)){
                var iArr = sortedIndices()
                iArr[0] = "*"
                return iArr
            }else{
                return sortedIndices()
            }
        }
        return nil
    }
    func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        return index
    }
}






