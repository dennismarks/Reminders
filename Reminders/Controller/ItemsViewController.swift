//
//  ItemsViewController.swift
//  Reminders
//
//  Created by Dennis M on 2019-06-06.
//  Copyright © 2019 Dennis M. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications


protocol UpdateUIAfterGoBackDelegate {
    func updateUI()
}

class ItemsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AddNewItemDelegate, UIGestureRecognizerDelegate, UpdateUIAfterEditItemDelegate {
    
    @IBOutlet weak var itemTableView: UITableView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var backButtonBlurView: UIView!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var addButtonBlurView: UIView!
    
    @IBOutlet weak var tableViewFooter: UIView!
    @IBOutlet var addSomeRemindersLabel: [UILabel]?
    @IBOutlet var buttonConstraints: [NSLayoutConstraint]?
    
    var moveView = true
    
    
    var selectedCategory : Category? {
        // what should happen when a variable gets set with a new value
        didSet {
            load()
            self.title = self.selectedCategory?.name
        }
    }
    var tableViewColour : String = ""
    var delegate : UpdateUIAfterGoBackDelegate?
    var array = [Item]()
    var curIndexPath: IndexPath?
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var updateButtons = true
    var didBlur = false
    
    var curIndex = 0
    var from = 0
    var to = 0
    var curRow = 0
    
    let topSafeView = UIView()
    let bottomSafeView = UIView()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.itemTableView.backgroundColor = hexStringToUIColor(hex: tableViewColour)
        itemTableView.separatorStyle = .none
        
        bottomSafeView.layer.isHidden = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(400), execute: {
            UIView.animate(withDuration: 0.4, animations: {
                if self.array.count == 0 {
                    for label in self.addSomeRemindersLabel! {
                        label.layer.opacity = 1.0
                    }
                }
                self.backButton.layer.opacity = 1.0
                self.addButton.layer.opacity = 1.0
                self.addButtonBlurView.layer.opacity = 1.0
                self.backButtonBlurView.layer.opacity = 1.0
            })
        })
        
        for item in array {
            print(item.title!, item.position)
        }
        
        let origImage = UIImage(named: "back")
        let tintedImage = origImage?.withRenderingMode(.alwaysTemplate)
        backButton.setImage(tintedImage, for: .normal)
        backButton.tintColor = hexStringToUIColor(hex: (selectedCategory?.tintColour)!)
        
        let origImageAdd = UIImage(named: "add")
        let tintedImageAdd = origImageAdd?.withRenderingMode(.alwaysTemplate)
        addButton.setImage(tintedImageAdd, for: .normal)
        addButton.tintColor = hexStringToUIColor(hex: (selectedCategory?.tintColour)!)
        
        curIndex = array.count
        
        print("Height \(self.view.frame.height)")
        
        self.itemTableView.contentInset = UIEdgeInsets(top: -9, left: 0, bottom: 0, right: 0);
        
        
        
//        self.itemTableView?.frame = CGRect(x: 0, y: height, width: UIScreen.mainScreen.bounds.width, height: (UIScreen.mainScreen().bounds.height - height))
//
//        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(singleTapped))
//        singleTapGesture.numberOfTapsRequired = 1
//        view.addGestureRecognizer(singleTapGesture)
//
//        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
//        doubleTapGesture.numberOfTapsRequired = 2
//        doubleTapGesture.delegate = self
//        view.addGestureRecognizer(doubleTapGesture)
////
//        singleTapGesture.require(toFail: doubleTapGesture)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if moveView {
            if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                if self.view.frame.origin.y == 0 {
                    self.view.frame.origin.y = self.view.frame.origin.y - keyboardSize.height + self.bottomSafeView.frame.height
                }
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        print("Hide \(self.addButtonBlurView.frame.origin.y)")
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
        self.viewWillAppear(true)
//        self.bottomSafeView.layer.opacity = 1.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        self.view.addSubview(topSafeView)
        self.view.addSubview(bottomSafeView)
        
        bottomSafeView.translatesAutoresizingMaskIntoConstraints = false
        topSafeView.translatesAutoresizingMaskIntoConstraints = false
        let window = UIApplication.shared.windows[0]
        let safeFrame = window.safeAreaLayoutGuide.layoutFrame

        print(safeFrame.minY)

        bottomSafeView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        bottomSafeView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
        bottomSafeView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
        bottomSafeView.heightAnchor.constraint(equalToConstant: window.frame.maxY - safeFrame.maxY).isActive = true
        bottomSafeView.widthAnchor.constraint(equalToConstant: view.frame.width).isActive = true
        bottomSafeView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        bottomSafeView.frame.size.height = window.frame.maxY - safeFrame.maxY
        bottomSafeView.frame.size.width = view.frame.width
        
        topSafeView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        topSafeView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
        topSafeView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        topSafeView.heightAnchor.constraint(equalToConstant: safeFrame.minY + 26).isActive = true
        topSafeView.widthAnchor.constraint(equalToConstant: view.frame.width).isActive = true
        topSafeView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        // + 26
        topSafeView.frame.size.height = safeFrame.minY + 26
        topSafeView.frame.size.width = view.frame.width
        
        
        let visualEffectViewTop = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        visualEffectViewTop.frame = topSafeView.bounds
        
        let visualEffectViewBot = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        visualEffectViewBot.frame = bottomSafeView.bounds
        
        if !didBlur {
            topSafeView.addSubview(visualEffectViewTop)
            bottomSafeView.addSubview(visualEffectViewBot)
        }

        let label = UILabel()
        self.view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = (self.selectedCategory?.name)!
        label.frame.size.width = view.frame.width
        label.frame.size.height = 30
        label.font = UIFont(name: "SFProText-Semibold", size: 17.0)
        label.textAlignment = .center
        label.textColor = .black
        label.topAnchor.constraint(equalTo: view.topAnchor, constant: safeFrame.minY).isActive = true
        label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true

        tableViewFooter.backgroundColor = hexStringToUIColor(hex: (selectedCategory?.colour)!)
        
        itemTableView.estimatedRowHeight = 100
        itemTableView.rowHeight = UITableView.automaticDimension
        
        for label in addSomeRemindersLabel! {
            label.textColor = hexStringToUIColor(hex: (selectedCategory?.tintColour)!)
        }
        
        print(self.view.frame.height)
        if self.view.frame.height < 600 && updateButtons {
            for size in self.buttonConstraints! {
                size.constant *= 0.9
                addSomeRemindersLabel![0].font = addSomeRemindersLabel![0].font.withSize(32)
                addSomeRemindersLabel![1].font = addSomeRemindersLabel![1].font.withSize(25)
                print("BEEN HERE")
                self.view.layoutIfNeeded()
            }
        }
        
        if !didBlur {
            addButtonBlurView.layer.cornerRadius = addButtonBlurView.frame.height / 2
            let visualEffectAddButton = UIVisualEffectView(effect: UIBlurEffect(style: .light))
            visualEffectAddButton.frame = addButtonBlurView.bounds
            visualEffectAddButton.layer.cornerRadius = addButtonBlurView.frame.height / 2
            visualEffectAddButton.clipsToBounds = true
            addButtonBlurView.addSubview(visualEffectAddButton)
            addButtonBlurView.addSubview(addButton)
            
            backButtonBlurView.layer.cornerRadius = backButtonBlurView.frame.height / 2
            let visualEffectBackButton = UIVisualEffectView(effect: UIBlurEffect(style: .light))
            visualEffectBackButton.frame = backButtonBlurView.bounds
            visualEffectBackButton.layer.cornerRadius = backButtonBlurView.frame.height / 2
            visualEffectBackButton.clipsToBounds = true
            backButtonBlurView.addSubview(visualEffectBackButton)
            backButtonBlurView.addSubview(backButton)
        }
        
        didBlur = true
        updateButtons = false

//        print("button loc \(addButtonBlurView)")
        

//            addButtonBlurView.translatesAutoresizingMaskIntoConstraints = false
//            addButtonBlurView.heightAnchor.constraint(equalToConstant: 45).isActive = true
//            addButtonBlurView.widthAnchor.constraint(equalToConstant: 45).isActive = true
//            addButtonBlurView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 16).isActive = true
//            addButtonBlurView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
//            addButtonBlurView.frame.size.height = 45
//            addButtonBlurView.frame.size.width = 45
            
        
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data = array[indexPath.row] as Item
        let cell = Bundle.main.loadNibNamed("CustomItemCell", owner: self, options: nil)?.first as! CustomItemCell
        cell.titleLabel.text = data.title
        cell.titleLabel.font = UIFontMetrics.default.scaledFont(for: cell.titleLabel.font)
        cell.reminderLabel.text = data.reminder
        cell.reminderLabel.font = UIFontMetrics.default.scaledFont(for: cell.reminderLabel.font)
        
        if data.reminder == "" {
            cell.topSpace.isActive = false
            cell.bottomSpace.isActive = false
            cell.titleLabel.translatesAutoresizingMaskIntoConstraints = false
            cell.titleLabel.leadingAnchor.constraint(equalTo: cell.cellContentView.leadingAnchor, constant: 28).isActive = true
            cell.titleLabel.centerYAnchor.constraint(equalTo: cell.cellContentView.centerYAnchor).isActive = true
        }
        
        cell.backgroundColor = hexStringToUIColor(hex: (selectedCategory?.colour)!)
        cell.tintColor = .white
        cell.titleLabel.textColor = hexStringToUIColor(hex: (selectedCategory?.tintColour)!)
        cell.reminderLabel.textColor = hexStringToUIColor(hex: (selectedCategory?.tintColour)!)

        if (data.done) {
            cell.titleLabel.layer.opacity = 0.4
            cell.reminderLabel.layer.opacity = 0.4
        }

        cell.separationLine.backgroundColor = hexStringToUIColor(hex: (selectedCategory?.tintColour)!)
        
        cell.selectionStyle = .default
        
        let curDate = Date()
        if let time = data.reminderDateType {
            if time < curDate && !data.done {
                cell.reminderLabel.textColor = hexStringToUIColor(hex: "#F52500")
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
//        let cell = tableView.cellForRow(at: indexPath) as! CustomItemCell
//        cell.backgroundColor = cell.backgroundColor?.lighterColor
//        cell.titleLabel.font = cell.titleLabel.font.withSize(cell.titleLabel.font.pointSize + 0.3)
//        cell.reminderLabel.font = cell.titleLabel.font.withSize(cell.reminderLabel.font.pointSize + 0.3)
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
//        self.itemTableView.reloadData()
//        let cell = tableView.cellForRow(at: indexPath) as! CustomItemCell
//        cell.titleLabel.font = cell.titleLabel.font.withSize(cell.titleLabel.font.pointSize - 0.3)
//        cell.reminderLabel.font = cell.titleLabel.font.withSize(cell.reminderLabel.font.pointSize - 0.3)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return array.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if array[indexPath.row].done == false {
            var indexToInsert = array.count
            for i in 0...array.count - 1 {
                if array[i].done == true {
                    indexToInsert = i
                    break
                }
            }
            print("index to insert \(indexToInsert)")
            array[indexPath.row].done = !array[indexPath.row].done
            let itemToMove = array[indexPath.row]
            array.remove(at: indexPath.row)
            if indexToInsert > array.count {
                array.append(itemToMove)
            } else {
                array.insert(itemToMove, at: indexToInsert - 1)
            }
        } else {
            var indexToInsert = 0
            for i in 0...array.count - 1 {
                if array[i].done == true {
                    indexToInsert = i
                    break
                }
            }
            print("index to insert \(indexToInsert)")
            array[indexPath.row].done = !array[indexPath.row].done
            let itemToMove = array[indexPath.row]
            array.remove(at: indexPath.row)
            if indexToInsert == 0 {
                array.insert(itemToMove, at: 0)
            } else if indexToInsert > array.count {
                array.append(itemToMove)
            } else {
                array.insert(itemToMove, at: indexToInsert)
            }
        }
        
        for i in 0...array.count - 1 {
            array[i].position = Int16(i)
        }
        
        save()
        load()
        self.itemTableView.reloadData()
//        for item in array {
//            print(item.title)
//        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: .none) { (action, view, completion) in
            let index = indexPath.row
            self.context.delete(self.array[indexPath.row])
            self.array.remove(at: indexPath.row)
            self.itemTableView.deleteRows(at: [indexPath], with: .automatic)
            if self.array.count == 0 {
                UIView.animate(withDuration: 0.5) {
                    for label in self.addSomeRemindersLabel! {
                        label.layer.opacity = 1.0
                    }
                }
            }
            
            for item in self.array {
                if index < item.position {
                    item.position -= 1
                }
            }
            
            self.curIndex -= 1
            
            self.save()
            completion(true)
        }
        let editAction = UIContextualAction(style: .normal, title: .none) { (action, view, completion) in
            self.curIndexPath = indexPath
            self.performSegue(withIdentifier: "goToEditItem", sender: self)
            completion(true)
        }
//        let shareAction = UIContextualAction(style: .normal, title: .none) { (action, view, completion) in
//            let activityVC = UIActivityViewController(activityItems: ["Hello"], applicationActivities: nil)
//            self.present(activityVC, animated: true, completion: nil)
//            completion(true)
//        }

        deleteAction.image = UIImage(named: "delete")
        deleteAction.backgroundColor = hexStringToUIColor(hex: "#DE615F")
//        deleteAction.backgroundColor = .black

        editAction.image = UIImage(named: "edit")
        editAction.backgroundColor = hexStringToUIColor(hex: "#FBBB04")
//        editAction.backgroundColor = .black
        
//        shareAction.image = UIImage(named: "share")
//        shareAction.backgroundColor = hexStringToUIColor(hex: "#FBBB04")
        
        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    }
    
    @objc func singleTapped() {
        addButtonPressed(self.addButton)
    }
    
    @objc func doubleTapped() {
        backButtonPressed(self.backButton)
    }
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        print("Back pressed")
        UIView.animate(withDuration: 0.065) {
            self.addButton.layer.opacity = 0.0
            self.backButton.layer.opacity = 0.0
            self.addButtonBlurView.layer.opacity = 0.0
            self.backButtonBlurView.layer.opacity = 0.0
        }
        self.delegate?.updateUI()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addButtonPressed(_ sender: UIButton) {
        UIView.animate(withDuration: 0.8) {
            self.view.layer.opacity = 0.6
        }
        performSegue(withIdentifier: "goToAddItem", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToAddItem" {
            let destinationVC = segue.destination as! AddNewItemViewController
            destinationVC.delegate = self
            destinationVC.modalPresentationStyle = .popover
            let popOverVC = destinationVC.popoverPresentationController
            popOverVC?.delegate = self
            
//            popOverVC?.sourceView = self.addButtonBlurView
            
            popOverVC?.sourceView = self.addButtonBlurView
            print("Height \(self.view.frame.height)")
            if self.view.frame.height < 600 {
//                addSomeRemindersLabel![0].centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: -20).isActive = true
                self.view.layoutIfNeeded()
                popOverVC?.permittedArrowDirections = .init(rawValue: 0)
                popOverVC?.sourceRect = CGRect(x: self.view.bounds.maxX, y: self.view.bounds.maxY, width: 0, height: 0)
                destinationVC.preferredContentSize = CGSize(width: self.view.frame.width, height: self.view.frame.width * 0.5)
            } else {
                popOverVC?.sourceRect = CGRect(x: self.addButtonBlurView.bounds.midX, y: self.addButtonBlurView.bounds.minY, width: 0, height: 0)
                destinationVC.preferredContentSize = CGSize(width: self.view.frame.width, height: self.view.frame.width)
            }
            
        } else if segue.identifier == "goToEditItem" {
            moveView = false
            let destinationVC = segue.destination as! EditItemViewController
            let cell = self.itemTableView.cellForRow(at: curIndexPath!) as! CustomItemCell
            destinationVC.itemName = cell.titleLabel!.text!
            destinationVC.reminderDate = array[(curIndexPath?.row)!].reminderDateType
            destinationVC.delegate = self
            destinationVC.modalPresentationStyle = .popover
            let popOverVC = destinationVC.popoverPresentationController
            popOverVC?.delegate = self
            popOverVC?.permittedArrowDirections = UIPopoverArrowDirection(rawValue:0)
            popOverVC?.sourceView = self.itemTableView
            if cell.reminderLabel.text != "" {
                destinationVC.preferredContentSize = CGSize(width: self.view.frame.width, height: self.view.frame.width)
            } else {
                destinationVC.preferredContentSize = CGSize(width: self.view.frame.width, height: self.view.frame.width * 0.5)
            }
        }
    }
    
    func addNewItem(name: String) {
        let item = Item(context: self.context)
        item.title = name
        item.reminderDateType = nil
        item.reminder = ""
        item.done = false
        item.parentCategory = self.selectedCategory
        item.position = Int16(self.curIndex)
        curIndex += 1
        var indexOfFirstDone = -1
        for el in array {
            if el.done {
                indexOfFirstDone = Int(el.position)
                break
            }
        }
        if indexOfFirstDone == -1 {
            array.append(item)
        } else {
            array.insert(item, at: indexOfFirstDone)
        }
        
        for i in 0...array.count - 1 {
            array[i].position = Int16(i)
        }
        
        self.save()
        self.itemTableView.reloadData()
        if array.count > 0 {
            UIView.animate(withDuration: 0.5) {
                for label in self.addSomeRemindersLabel! {
                    label.layer.opacity = 0
                }
            }
        }
        print("Saved")
    }
    
    func addNewItem(name: String, reminder: UIDatePicker) {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEE, MMM d hh:mm aaa")
        let time = formatter.string(from: reminder.date)
        print(time)
        let item = Item(context: self.context)
        item.reminderDateType = reminder.date
        item.title = name
        item.reminder = time
        item.done = false
        item.parentCategory = self.selectedCategory
        item.position = Int16(self.curIndex)
        curIndex += 1
//        self.array.append(item)
        
        var indexOfFirstDone = -1
        for el in array {
            if el.done {
                indexOfFirstDone = Int(el.position)
                break
            }
        }
        if indexOfFirstDone == -1 {
            array.append(item)
        } else {
            array.insert(item, at: indexOfFirstDone)
        }
        
        for i in 0...array.count - 1 {
            array[i].position = Int16(i)
        }
        
        self.save()
        self.itemTableView.reloadData()
        if array.count > 0 {
            UIView.animate(withDuration: 0.5) {
                for label in self.addSomeRemindersLabel! {
                    label.layer.opacity = 0
                }
            }
        }
        
        
        // declare the content of the notification:
        let content = UNMutableNotificationContent()
        content.sound = UNNotificationSound.default
        content.title = selectedCategory!.name!
        content.body = item.title!
        
        // declaring the trigger
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.date)
        let calendarTrigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)

        // creating a request and add it to the notification center
        let request = UNNotificationRequest(identifier: name, content: content, trigger: calendarTrigger)
        UNUserNotificationCenter.current().add(request)
        
        self.save()
        self.itemTableView.reloadData()
        if array.count > 0 {
            UIView.animate(withDuration: 0.5) {
                for label in self.addSomeRemindersLabel! {
                    label.layer.opacity = 0
                }
            }
        }
    }
    
    func editItem(name: String) {
        self.moveView = true
        array[(curIndexPath?.row)!].setValue(nil, forKey: "reminderDateType")
        array[(curIndexPath?.row)!].setValue("", forKey: "reminder")
        array[(curIndexPath?.row)!].setValue(name, forKey: "title")
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { (notificationRequests) in
            var identifiers: [String] = []
            for notification:UNNotificationRequest in notificationRequests {
                if notification.identifier == name {
                    identifiers.append(notification.identifier)
                }
            }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        }
        save()
        self.itemTableView.reloadData()
    }
    
    func editItem(name: String, reminder: UIDatePicker) {
        self.moveView = true
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEE, MMM d hh:mm aaa")
        let time = formatter.string(from: reminder.date)
        array[(curIndexPath?.row)!].setValue(reminder.date, forKey: "reminderDateType")
        array[(curIndexPath?.row)!].setValue(time, forKey: "reminder")
        array[(curIndexPath?.row)!].setValue(name, forKey: "title")
        // declare the content of the notification:
        let content = UNMutableNotificationContent()
        content.sound = UNNotificationSound.default
        content.title = selectedCategory!.name!
        content.body = name
        
        // declaring the trigger
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.date)
        let calendarTrigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        
        // creating a request and add it to the notification center
        let request = UNNotificationRequest(identifier: name, content: content, trigger: calendarTrigger)
        
        UNUserNotificationCenter.current().add(request)
        save()
        self.itemTableView.reloadData()
    }
    
    func dismissEditView() {
        self.moveView = true
    }
    
    func dismissView() {
        self.moveView = true
        UIView.animate(withDuration: 0.5) {
            self.view.layer.opacity = 1.0
        }
        updateButtons = false
        didBlur = true
    }
    
    func save() {
        do {
            try self.context.save()
            for item in array {
                print(item.title!, item.position)
            }
            print("Cur index - \(curIndex)")
        } catch {
            print("Error saving context \(error)")
        }
    }
    
    func load(with request: NSFetchRequest<Item> = Item.fetchRequest(), with predicate: NSPredicate? = nil) {
        let categoryPredicate = NSPredicate(format: "parentCategory.name MATCHES %@", selectedCategory!.name!)
        let sort = NSSortDescriptor(key: "position", ascending: true)

        if let searchPredicate = predicate {
            let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [categoryPredicate, searchPredicate])
            request.predicate = compoundPredicate
        } else {
            request.predicate = categoryPredicate
        }
        
        request.sortDescriptors = [sort]
        do {
            array = try context.fetch(request)
        } catch {
            print("Error fetchin data from context \(error)")
        }
    }

}


extension ItemsViewController {
    
    func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
}


// This is we need to make it looks as a popup window on iPhone
extension ItemsViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}


extension UIView {
    
    // Using a function since `var image` might conflict with an existing variable
    // (like on `UIImageView`)
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}


extension UIColor {
    
    var lighterColor: UIColor {
        return lighterColor(removeSaturation: 0.5, resultAlpha: -1)
    }
    
    func lighterColor(removeSaturation val: CGFloat, resultAlpha alpha: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0
        var b: CGFloat = 0, a: CGFloat = 0
        
        guard getHue(&h, saturation: &s, brightness: &b, alpha: &a)
            else {return self}
        
        return UIColor(hue: h,
                       saturation: max(s - val, 0.0),
                       brightness: b,
                       alpha: alpha == -1 ? a : alpha)
    }
}
