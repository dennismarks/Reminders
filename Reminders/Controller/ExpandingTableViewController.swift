//
//  ExpandingTableViewController.swift
//  Reminders
//
//  Created by Dennis M on 2019-06-06.
//  Copyright © 2019 Dennis M. All rights reserved.
//


import UIKit
import CoreData
import UserNotifications

class ExpandingTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIViewControllerTransitioningDelegate, UpdateMainViewDelegate, UpdateUIAfterGoBackDelegate, UpdateUIAfterClosingEditCategoryDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var addButtonBlurView: UIView!
    @IBOutlet weak var welcomeLabelOne: UILabel!
    @IBOutlet weak var welcomeLabelTwo: UILabel!
    @IBOutlet var buttonConstraints: [NSLayoutConstraint]?

    
    
//    @IBOutlet weak var topSafeView: UIView!
//    @IBOutlet weak var bottomSafeView: UIView!
    
    var dragInitialIndexPath: IndexPath?
    var dragCellSnapshot: UIView?
    var hideCellAllowed: Bool!
    
    var array = [Category]()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var curIndexPath : IndexPath?
    
    var curIndex = 0
    var from = 0
    var to = 0
    var curRow = 0
    var moveView = true
    
    let topSafeView = UIView()
    let bottomSafeView = UIView()
    
    var lastClick: TimeInterval?
    var lastIndexPath: IndexPath?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureRecognized(gestureRecognizer:)))
        longPress.minimumPressDuration = 0.3 // optional
        tableView.addGestureRecognizer(longPress)
        
        self.tableView.separatorStyle = .none
        load()
        curIndex = self.array.count
        print("Current index -> \(curIndex)")
        self.view.layer.opacity = 1.0
        
        for item in array {
            print(item.name!, item.position)
        }
        
        print("\n")
        
        if array.count == 0 {
            UIView.animate(withDuration: 0.8, animations: {
                self.welcomeLabelOne.layer.opacity = 1.0
            }) { (true) in
                UIView.animate(withDuration: 0.8, animations: {
                    self.welcomeLabelTwo.layer.opacity = 1.0
                }) { (true) in
                    UIView.animate(withDuration: 0.5, animations: {
                        self.addButton.layer.opacity = 1.0
                    }) { (true) in
                        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (didAllow, error) in }
                    }
                }
            }
        } else {
            UIView.animate(withDuration: 0.3) {
                self.addButton.layer.opacity = 1.0
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if moveView {
            if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                if self.view.frame.origin.y == 0 {
                    self.view.frame.origin.y -= keyboardSize.height
                }
                self.bottomSafeView.layer.opacity = 0.0
            }
        }
        
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
        self.bottomSafeView.layer.opacity = 1.0
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        self.view.addSubview(topSafeView)
        self.view.addSubview(bottomSafeView)

        bottomSafeView.translatesAutoresizingMaskIntoConstraints = false
        topSafeView.translatesAutoresizingMaskIntoConstraints = false
        let window = UIApplication.shared.windows[0]
        let safeFrame = window.safeAreaLayoutGuide.layoutFrame
        
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
        topSafeView.heightAnchor.constraint(equalToConstant: safeFrame.minY).isActive = true
        topSafeView.widthAnchor.constraint(equalToConstant: view.frame.width).isActive = true
        topSafeView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        topSafeView.frame.size.height = safeFrame.minY
        topSafeView.frame.size.width = view.frame.width
        
        let visualEffectViewTop = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        visualEffectViewTop.frame = topSafeView.bounds

        let visualEffectViewBot = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        visualEffectViewBot.frame = bottomSafeView.bounds
        
        topSafeView.addSubview(visualEffectViewTop)
        bottomSafeView.addSubview(visualEffectViewBot)
        
        let origImage = UIImage(named: "add")
        let tintedImage = origImage?.withRenderingMode(.alwaysTemplate)
        addButton.setImage(tintedImage, for: .normal)
        addButton.tintColor = .black
        
        if self.view.frame.height < 600 {
            for size in buttonConstraints! {
                size.constant *= 0.95
                self.view.layoutIfNeeded()
            }
        }
        
        
        addButtonBlurView.layer.cornerRadius = addButtonBlurView.frame.height / 2
        let visualEffectAddButton = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        visualEffectAddButton.frame = addButtonBlurView.bounds
        visualEffectAddButton.layer.cornerRadius = addButtonBlurView.frame.height / 2
        visualEffectAddButton.clipsToBounds = true
        addButtonBlurView.addSubview(visualEffectAddButton)
        addButtonBlurView.addSubview(addButton)
        
    }
    
    var openingFrame: CGRect?
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let presentationAnimator = ExpandAnimator.animator
        presentationAnimator.openingFrame = openingFrame!
        presentationAnimator.transitionMode = .Present
        return presentationAnimator
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let presentationAnimator = ExpandAnimator.animator
        presentationAnimator.openingFrame = openingFrame!
        presentationAnimator.transitionMode = .Dismiss
        return presentationAnimator
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return array.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Bundle.main.loadNibNamed("CustomCategoryCell", owner: self, options: nil)?.first as! CustomCategoryCell
        cell.nameLabel.text = array[indexPath.row].name
        cell.nameLabel.font = UIFontMetrics.default.scaledFont(for: cell.nameLabel.font)
        cell.selectionStyle = .none
        cell.cellColourString = array[indexPath.row].colour!
        cell.backgroundColor = hexStringToUIColor(hex: array[indexPath.row].colour!)
        cell.nameLabel.textColor = hexStringToUIColor(hex: array[indexPath.row].tintColour!)
        if self.view.frame.height < 600 {
            cell.nameLabel.font = cell.nameLabel.font.withSize(31)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! CustomCategoryCell
        UIView.animate(withDuration: 0.5) {
            cell.nameLabel.font = cell.nameLabel.font.withSize(cell.nameLabel.font.pointSize + 8)
        }
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! CustomCategoryCell
        UIView.animate(withDuration: 0.5) {
            cell.nameLabel.font = cell.nameLabel.font.withSize(cell.nameLabel.font.pointSize - 8)
        }
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Set frame of cell
        let attributesFrame = tableView.cellForRow(at: indexPath)?.frame
        let frameToOpenFrom = tableView.convert(attributesFrame!, to: tableView.superview)
        openingFrame = frameToOpenFrom
        
        curRow = indexPath.row
        UIView.animate(withDuration: 0.065) {
            self.addButton.layer.opacity = 0.0
            self.addButtonBlurView.layer.opacity = 0.0
        }
        
        UIView.animate(withDuration: 1) {
            self.view.layer.opacity = 0.0
        }
        
        self.performSegue(withIdentifier: "goToItems", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToItems" {
            let destinationVC = segue.destination as! ItemsViewController
            destinationVC.transitioningDelegate = self
            destinationVC.delegate = self
            destinationVC.modalPresentationStyle = .custom
            destinationVC.selectedCategory = array[curRow]
            destinationVC.tableViewColour = array[curRow].colour!
//            destinationVC.tableViewColour = "#3D3D3D"
        }
        else if segue.identifier == "goToAddCategory" {
            let destinationVC = segue.destination as! AddNewCategoryViewController
            destinationVC.delegate = self
            destinationVC.modalPresentationStyle = .popover
            let popOverVC = destinationVC.popoverPresentationController
            popOverVC?.delegate = self
            popOverVC?.sourceView = self.addButton
            popOverVC?.sourceRect = CGRect(x: self.addButton.bounds.midX, y: self.addButton.bounds.minY + self.bottomSafeView.frame.height, width: 0, height: 0)
            destinationVC.preferredContentSize = CGSize(width: self.view.frame.width, height: self.view.frame.width)
        }
        else if segue.identifier == "goToEditCategory" {
            moveView = false
            let destinationVC = segue.destination as! EditCategoryViewController
            let cell = self.tableView.cellForRow(at: curIndexPath!) as! CustomCategoryCell
            destinationVC.categoryName = cell.nameLabel!.text!
            destinationVC.categoryColour = cell.cellColourString
            destinationVC.delegate = self
            destinationVC.modalPresentationStyle = .popover
            let popOverVC = destinationVC.popoverPresentationController
//            popOverVC?.sourceView?.layer.opacity = 0.1
            popOverVC?.delegate = self
            popOverVC?.permittedArrowDirections = UIPopoverArrowDirection(rawValue:0)
            popOverVC?.sourceView = self.topSafeView
            let screenWidth = UIScreen.main.bounds.width

            destinationVC.preferredContentSize = CGSize(width: screenWidth, height: screenWidth)
        }
    }
    
    func addNewCategory(name: String, colour: String, tint: String) {
        UIView.animate(withDuration: 0.5) {
            self.view.layer.opacity = 1.0
        }
        let category = Category(context: self.context)
        category.name = name
        category.position = Int16(self.curIndex)
        category.colour = colour
        category.tintColour = tint
        self.curIndex += 1
        self.array.append(category)
        if array.count != 0 {
            self.welcomeLabelOne.layer.opacity = 0.0
            self.welcomeLabelTwo.layer.opacity = 0.0
        }
        self.save()
        self.tableView.reloadData()
        print("Saved new category")
    }
    
    func editCategory(name: String, colour: String, tint: String) {
        self.moveView = true
        print(name, colour, tint)
        array[(curIndexPath?.row)!].setValue(name, forKey: "name")
        array[(curIndexPath?.row)!].setValue(colour, forKey: "colour")
        array[(curIndexPath?.row)!].setValue(tint, forKey: "tintColour")
        save()
        self.tableView.reloadData()
    }
    
    func dismissView() {
        UIView.animate(withDuration: 0.5) {
            self.view.layer.opacity = 1.0
        }
    }
    
    func dismissEditView() {
        self.moveView = true
    }
    
    func updateUI() {
        self.view.layer.opacity = 1.0
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200), execute: {
            UIView.animate(withDuration: 0.3, animations: {
                self.addButton.layer.opacity = 1.0
                self.addButtonBlurView.layer.opacity = 1.0
            })
        })
       
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.view.frame.height < 600 {
            return 90
        } else {
            return 100
        }
    }
    
    @IBAction func addButtonPressed(_ sender: UIButton) {
        UIView.animate(withDuration: 0.5) {
            self.view.layer.opacity = 0.6
        }
        performSegue(withIdentifier: "goToAddCategory", sender: self)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: .none) { (action, view, completion) in
            let index = indexPath.row
            self.context.delete(self.array[indexPath.row])
            self.array.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            
            for item in self.array {
                if index < item.position {
                    item.position -= 1
                }
            }
            
            self.curIndex -= 1
            
            if self.array.count == 0 {
                UIView.animate(withDuration: 0.8, animations: {
                    self.welcomeLabelOne.layer.opacity = 1.0
                }) { (true) in
                    UIView.animate(withDuration: 0.8, animations: {
                        self.welcomeLabelTwo.layer.opacity = 1.0
                    })
                }
            }
            
            self.save()
            completion(true)
        }
        let editAction = UIContextualAction(style: .normal, title: .none) { (action, view, completion) in
            self.curIndexPath = indexPath
            self.performSegue(withIdentifier: "goToEditCategory", sender: self)
            completion(true)
        }
        
        deleteAction.image = UIImage(named: "delete")
        deleteAction.backgroundColor = hexStringToUIColor(hex: "#DE615F")

        editAction.image = UIImage(named: "edit")
        editAction.backgroundColor = hexStringToUIColor(hex: "#FBBB04")

        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    }
    
    
    func save() {
        do {
            try self.context.save()
            print("Saved data")
            for item in array {
                print(item.name!, item.position)
            }
        } catch {
            print("Error saving context \(error)")
        }
    }
    
    func load(with request: NSFetchRequest<Category> = Category.fetchRequest()) {
        let sort = NSSortDescriptor(key: "position", ascending: true)
        request.sortDescriptors = [sort]
        do {
            array = try context.fetch(request)
        } catch {
            print("Error fetchin data from context \(error)")
        }
    }
    
    @objc func longPressGestureRecognized(gestureRecognizer: UIGestureRecognizer) {
        
        let longPress = gestureRecognizer as! UILongPressGestureRecognizer
        let state = longPress.state
        let locationInView = longPress.location(in: tableView)
        let indexPath = tableView.indexPathForRow(at: locationInView)
        struct My {
            static var cellSnapshot : UIView? = nil
            static var cellIsAnimating : Bool = false
            static var cellNeedToShow : Bool = false
        }
        struct Path {
            static var initialIndexPath : IndexPath? = nil
        }
        switch state {
        case UIGestureRecognizerState.began:
            if indexPath != nil {
                from = (indexPath?.row)!
                print(from)
                Path.initialIndexPath = indexPath
                let cell = tableView.cellForRow(at: indexPath!) as! CustomCategoryCell?
                My.cellSnapshot  = snapshotOfCell(cell!)
                var center = cell?.center
                My.cellSnapshot!.center = center!
                My.cellSnapshot!.alpha = 0.0
                tableView.addSubview(My.cellSnapshot!)
                UIView.animate(withDuration: 0.25, animations: { () -> Void in
                    center?.y = locationInView.y
                    My.cellIsAnimating = true
                    My.cellSnapshot!.center = center!
                    My.cellSnapshot!.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                    My.cellSnapshot!.alpha = 0.98
                    cell?.alpha = 0.0
                }, completion: { (finished) -> Void in
                    if finished {
                        My.cellIsAnimating = false
                        if My.cellNeedToShow {
                            My.cellNeedToShow = false
                            UIView.animate(withDuration: 0.25, animations: { () -> Void in
                                cell?.alpha = 1
                            })
                        } else {
                            cell?.isHidden = true
                        }
                    }
                })
            }
        case UIGestureRecognizerState.changed:
            if My.cellSnapshot != nil {
                var center = My.cellSnapshot!.center
                center.y = locationInView.y
                My.cellSnapshot!.center = center
                if ((indexPath != nil) && (indexPath != Path.initialIndexPath)) {
                    to = (indexPath?.row)!
                    print(to)
                    array.insert(array.remove(at: Path.initialIndexPath!.row), at: indexPath!.row)
                    tableView.moveRow(at: Path.initialIndexPath!, to: indexPath!)
                    Path.initialIndexPath = indexPath
                }
            }
        default:
            if Path.initialIndexPath != nil {
                let cell = tableView.cellForRow(at: Path.initialIndexPath!) as! CustomCategoryCell?
                if My.cellIsAnimating {
                    My.cellNeedToShow = true
                } else {
                    cell?.isHidden = false
                    cell?.alpha = 0.0
                }
                UIView.animate(withDuration: 0.25, animations: { () -> Void in
                    My.cellSnapshot!.center = (cell?.center)!
                    My.cellSnapshot!.transform = CGAffineTransform.identity
                    My.cellSnapshot!.alpha = 0.0
                    cell?.alpha = 1.0
                }, completion: { (finished) -> Void in
                    if finished {
                        Path.initialIndexPath = nil
                        My.cellSnapshot!.removeFromSuperview()
                        My.cellSnapshot = nil
                    }
                })
                
                for i in 0...array.count-1 {
                    array[i].position = Int16(i)
                }
                
                save()
            }
        }

    }
    
    func snapshotOfCell(_ inputView: UIView) -> UIView {
        UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, false, 0.0)
        inputView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()! as UIImage
        UIGraphicsEndImageContext()
        let cellSnapshot : UIView = UIImageView(image: image)
        cellSnapshot.layer.masksToBounds = false
        cellSnapshot.layer.cornerRadius = 0.0
        cellSnapshot.layer.shadowOffset = CGSize(width: -5.0, height: 0.0)
        cellSnapshot.layer.shadowRadius = 5.0
        cellSnapshot.layer.shadowOpacity = 0.4
        return cellSnapshot
    }
    
    struct My {
        static var cellSnapShot: UIView? = nil
    }
    
    struct Path {
        static var initialIndexPath: IndexPath? = nil
    }
    
}


extension ExpandingTableViewController {
    
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
extension ExpandingTableViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}


protocol MultiTappableDelegate: class {
    func singleTapDetected(in view: MultiTappable)
    func doubleTapDetected(in view: MultiTappable)
}

class ThreadSafeValue<T> {
    private var _value: T
    private lazy var semaphore = DispatchSemaphore(value: 1)
    init(value: T) { _value = value }
    var value: T {
        get {
            semaphore.signal(); defer { semaphore.wait() }
            return _value
        }
        set(value) {
            semaphore.signal(); defer { semaphore.wait() }
            _value = value
        }
    }
}

protocol MultiTappable: UIView {
    var multiTapDelegate: MultiTappableDelegate? { get set }
    var tapCounter: ThreadSafeValue<Int> { get set }
}

extension MultiTappable {
    func initMultiTap() {
        if let delegate = self as? MultiTappableDelegate { multiTapDelegate = delegate }
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIView.multitapActionHandler))
        addGestureRecognizer(tap)
    }
    
    func multitapAction() {
        if tapCounter.value == 0 {
            DispatchQueue.global(qos: .utility).async {
                usleep(250_000)
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    if self.tapCounter.value > 1 {
                        self.multiTapDelegate?.doubleTapDetected(in: self)
                    } else {
                        self.multiTapDelegate?.singleTapDetected(in: self)
                    }
                    self.tapCounter.value = 0
                }
            }
        }
        tapCounter.value += 1
    }
}

private extension UIView {
    @objc func multitapActionHandler() {
        if let tappable = self as? MultiTappable { tappable.multitapAction() }
    }
}


class MyView: UIView, MultiTappable {
    weak var multiTapDelegate: MultiTappableDelegate?
    lazy var tapCounter = ThreadSafeValue(value: 0)
    override func awakeFromNib() {
        super.awakeFromNib()
        initMultiTap()
    }
}
