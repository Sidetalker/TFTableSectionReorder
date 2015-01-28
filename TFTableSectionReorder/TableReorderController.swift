//
//  ViewController.swift
//  TFTableSectionReorder
//
//  Created by Kevin Sullivan on 1/28/15.
//  Copyright (c) 2015 SideApps. All rights reserved.
//

import UIKit

struct cellData {
    // The absolute location of the cell in the tableview (which only has one section)
    var trueIndex = -1
    // The location of the cell with respect to its section (-1 when isSection = true)
    var sectionLocalIndex = -1
    // Section or row
    var isSection = false
    // Student count (either 1 for a student or # of students in a trip)
    var studentCount = 0
}

// This class feeds the tableView datasource
class reorderData {
    var cells = [cellData]()

    init() {

    }

    func addRandomData(stops: Int, studentsPer: Int) {
        var curStopIndex = 0


        for stop in 0...stops - 1 {
            cells.append(cellData(trueIndex: curStopIndex, sectionLocalIndex: -1, isSection: true, studentCount: studentsPer))

            for student in 0...studentsPer - 1 {
                cells.append(cellData(trueIndex: curStopIndex + student + 1, sectionLocalIndex: curStopIndex, isSection: false, studentCount: 1))
            }

            curStopIndex++
        }
    }
}

class TableReorderController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
}

