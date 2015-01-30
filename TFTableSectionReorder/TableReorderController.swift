//
//  ViewController.swift
//  TFTableSectionReorder
//
//  Created by Kevin Sullivan on 1/28/15.
//  Copyright (c) 2015 SideApps. All rights reserved.
//

import UIKit

let stopCount = 5
let studentCount = 4

struct studentData {
    var name = "Knobby"
}

struct stopData {
    var name = "Bobby"
}

struct cellData {
    // The absolute location of the cell in the tableview (which only has one section)
    var trueIndex = -1
    // Student: The location of the cell with respect to its section (maybe unused)
    // Stop: The index of the stop in an array of all stops
    var sectionIndex = -1
    // Section or row
    var isSection = false
    // Student count (either 1 for a student or # of students in a trip)
    var studentCount = 0
    // Student metadata is populated for student cells or nil for stops
    var studentMeta: studentData?
    // Stop metadata is populated for stop cells or nil for students
    var stopMeta: stopData?

    mutating func updateTrueIndex(index: Int) {
        trueIndex = index
    }

    mutating func updateSectionIndex(index: Int) {
        sectionIndex = index
    }
}

// Stop cell protocol for delegate callbacks upon touch recognitions
protocol StopCellDelegate {
    func startReorder(cell: StopCell, touchPoint: CGPoint)
}

// This class provides editing touch recognition for the stop cell
class StopCell: UITableViewCell {
    var delegate: StopCellDelegate?
    var indexPath = NSIndexPath()

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Identify the frame for the reorder control as defined by the superclass
        for view: UIView in self.subviews as [UIView] {
            let classString = NSStringFromClass(view.classForCoder)

            if classString == "UITableViewCellReorderControl" {
                let curRecognizerCount = view.gestureRecognizers?.count

                if curRecognizerCount == nil || curRecognizerCount == 0 {
                    let gesture = UILongPressGestureRecognizer(target: self, action: "reorderLongPress:")
                    gesture.cancelsTouchesInView = false
                    gesture.minimumPressDuration = 0.150

                    view.addGestureRecognizer(gesture)
                }
            }
        }
    }

    func reorderLongPress(gestureRecognizer: UIGestureRecognizer) {
        switch (gestureRecognizer.state) {
        case .Possible:
            break;
        case .Began:
            let touchPoint = gestureRecognizer.valueForKey("_startPointScreen")!.CGPointValue()
            println("Starting a reorder operation at location \(touchPoint)")
            delegate?.startReorder(self, touchPoint: touchPoint)
            break;
        case .Changed:
            break;
        case .Ended:
            println("Ending a reorder operation")
            break;
        case .Cancelled:
            break;
        case .Failed:
            break;
        default:
            break;
        }
    }
}

// This class maintains the tableView datasource
class DataManager {
    var tableView: UITableView!
    var cellHistory = [cellData]()
    var cells = [cellData]()
    var cellsCollapsed = [cellData]()
    var movingStop = false

    init(tableView: UITableView) {
        self.tableView = tableView
        addRandomData(stopCount, studentsPer: studentCount)
    }

    func addRandomData(stops: Int, studentsPer: Int) {
        var studentOffset = 0

        println("Populating \(stopCount) stops with \(studentCount) students each")

        let alphabet = ["a", "b", "c", "d", "e"]

        for stop in 0...stops - 1 {
            let stopMeta = stopData(name: "Stop \(stop + 1)")
            var cellMeta = cellData(trueIndex: stop + studentOffset, sectionIndex: stop, isSection: true, studentCount: studentCount, studentMeta: nil, stopMeta: stopMeta)

            cells.append(cellMeta)
            println("\(stopMeta.name) @ row \(stop + studentOffset)")

            for student in 0...studentsPer - 1 {
                let studentMeta = studentData(name: "Student \(stop + 1)-\(student + 1)\(alphabet[stop])")
                var cellMeta = cellData(trueIndex: stop + studentOffset + 1, sectionIndex: stop, isSection: false, studentCount: 1, studentMeta: studentMeta, stopMeta: nil)

                println("\(studentMeta.name) @ row \(stop + studentOffset + 1)")

                cells.append(cellMeta)

                studentOffset++
            }
        }
    }

    func getRows() -> Int {
        if movingStop {
            return cellsCollapsed.count
        }
        else {
            return cells.count
        }
    }

    func cellID(indexPath: NSIndexPath) -> String {
        var curCells = [cellData]()

        if movingStop {
            curCells = cellsCollapsed
        }
        else {
            curCells = cells
        }

        if curCells[indexPath.row].isSection {
            return "cellStop"
        }

        return "cellStudent"
    }

    func cellText(indexPath: NSIndexPath) -> String {
        var curCells = [cellData]()

        if movingStop {
            curCells = cellsCollapsed
        }
        else {
            curCells = cells
        }

        if let stopName = curCells[indexPath.row].stopMeta?.name {
            return stopName
        }
        else if let studentName = curCells[indexPath.row].studentMeta?.name {
            return studentName
        }

        return "--ERROR--"
    }

    func cellIndex(indexPath: NSIndexPath) -> Int {
        var curCells = [cellData]()

        if movingStop {
            curCells = cellsCollapsed
        }
        else {
            curCells = cells
        }

        return curCells[indexPath.row].trueIndex
    }

    func prepareForMove(indexPath: NSIndexPath, touchPoint: CGPoint) {
        cellHistory = cells

        let tappedCell = tableView.cellForRowAtIndexPath(indexPath)

        if cells[indexPath.row].isSection {

            cellsCollapsed = [cellData]()
            var animationIndices = [NSIndexPath]()

            for i in 0...cells.count - 1 {
                if cells[i].isSection {
                    cellsCollapsed.append(cells[i])
                }
                else {
                    animationIndices.append(NSIndexPath(forRow: cells[i].trueIndex, inSection: 0))
                }
            }

            let originalFrame = tappedCell!.frame

            tableView.beginUpdates()
            movingStop = true

            tableView.deleteRowsAtIndexPaths(animationIndices, withRowAnimation: UITableViewRowAnimation.Top)

            tableView.endUpdates()

            for cell in tableView.visibleCells() {
                if cell as StopCell == tappedCell! {
                    var cellYLoc = originalFrame.origin.y
                    let oldSize = self.tableView.frame.size

                    for more in tableView.visibleCells() {
                        let curCell = more as UITableViewCell

                        if tableView.indexPathForCell(curCell)!.row < tableView.indexPathForCell(cell as UITableViewCell)!.row {
                            cellYLoc -= curCell.frame.height
                        }
                    }

                    let newPoint = CGPoint(x: 0, y: cellYLoc)
                    let newSize = CGSize(width: oldSize.width, height: oldSize.height - cellYLoc)
                    
                    UIView.animateWithDuration(0.3, animations: {
                        self.tableView.frame = CGRect(origin: newPoint, size: newSize)
                    })
                }
            }
        }
    }

    func completeMove(origin: NSIndexPath, destination: NSIndexPath) {
        if movingStop {
            // Prepare animation container
            var animationIndices = [NSIndexPath]()

            // Get all the easy data
            var cellData = cellsCollapsed[origin.row]
            let cellStartIndex = cellData.trueIndex
            let oldSection = cells[cellStartIndex].sectionIndex
            let newSection = destination.row
            
            // Calculate the absolute index of the new section location
            
            // Determine direction of the move
            let movedUp = origin.row > destination.row ? true : false

            // Update the cellMetadata with the modified trueIndex
            if movedUp {
                var newSectionIndex = -1
                
                for (var i = 0; i < cells.count; i++) {
                    if cells[i].sectionIndex == newSection && cells[i].isSection {
                        newSectionIndex = i
                    }
                }
                
                if newSectionIndex == -1 {
                    println("ERRORRRRY")
                }
                
                
                
                
                // Calculate the end index of the cell and offset by children
                var cellEndIndex = 0
                var modA = 0
                var modB = 0

                for i in 0...cells.count - 1 {
                    if cells[i].sectionIndex > destination.row && cells[i].sectionIndex < origin.row {
                        modA++
                    }
                }

                // Update true indices
                for i in 0...cells.count - 1 {

                }


                for i in cellEndIndex + cells[cellEndIndex].studentCount + 1...cellStartIndex - 2 {
                    if cells[i].sectionIndex == origin.row && cells[i].isSection {
                        modA = 0

                        let newTrueIndex = cells[i].trueIndex + modB
                        cells[i].updateTrueIndex(newTrueIndex)
                    }
                    else if modA != 0 {
                        let newTrueIndex = cells[i].trueIndex - modA
                        cells[i].updateTrueIndex(newTrueIndex)
                        modB++
                    }
                }
            }

            // Populate animation container with all student cell locations
            for cell in cells {
                if !cell.isSection {
                    animationIndices.append(NSIndexPath(forRow: cell.trueIndex, inSection: 0))
                }
            }

            tableView.beginUpdates()
            movingStop = false

            tableView.insertRowsAtIndexPaths(animationIndices, withRowAnimation: UITableViewRowAnimation.Top)

            tableView.endUpdates()

            UIView.animateWithDuration(0.3, animations: {
                self.tableView.frame = UIScreen.mainScreen().bounds
            })

            tableView.reloadData()
        }
        else {

        }
    }
}

class TableReorderController: UITableViewController, UITableViewDataSource, UITableViewDelegate, StopCellDelegate {
    var data: DataManager!

    @IBOutlet weak var btnEditDone: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        data = DataManager(tableView: self.tableView)
        var something = UIView.appearance()
//        something.backgroundColor = UIColor.groupTableViewBackgroundColor()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    @IBAction func touchEdit(sender: AnyObject) {
        if tableView.editing {
            tableView.setEditing(false, animated: true)
            btnEditDone.title = "Edit"
            return
        }

        tableView.setEditing(true, animated: true)
        btnEditDone.title = "Done"
    }

    func startReorder(cell: StopCell, touchPoint: CGPoint) {
        data.prepareForMove(cell.indexPath, touchPoint: touchPoint)
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.getRows()
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellText = data.cellText(indexPath)
        let cellID = data.cellID(indexPath)
        let cellIndex = data.cellIndex(indexPath)

        if cellID == "cellStop" {
            var cell = tableView.dequeueReusableCellWithIdentifier(cellID) as StopCell
            cell.textLabel?.text = "(\(cellIndex)) \(cellText)"
            cell.indexPath = indexPath
            cell.delegate = self

            return cell
        }
        else if cellID == "cellStudent" {
            var cell = tableView.dequeueReusableCellWithIdentifier(cellID) as UITableViewCell
            cell.textLabel?.text = "(\(cellIndex)) \(cellText)"

            return cell
        }
        
        return UITableViewCell()
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.None
    }
    
    override func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        data.completeMove(sourceIndexPath, destination: destinationIndexPath)
        println("Moving row \(sourceIndexPath.row) to row \(destinationIndexPath.row)")
    }
}

