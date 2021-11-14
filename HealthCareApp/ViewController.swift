//
//  ViewController.swift
//  HealthCareApp
//
//  Created by 伴地慶介 on 2021/11/12.
//

import UIKit
import HealthKit
import Charts

class ViewController: UIViewController {

    @IBOutlet weak var lineChartView: LineChartView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // check HealthKit is available or not
        guard HKHealthStore.isHealthDataAvailable() else { return print("HealthKit is not available") }
        // authentication
        let dataTypes = Set([HKObjectType.quantityType(forIdentifier: .stepCount)!])
        HKHealthStore().requestAuthorization(toShare: nil, read: dataTypes) { success, Error in
            if success {
                print("success?:", success)
                // if authentication success
                self.getSteps{ doubleArray in
                    print(doubleArray)
                    DispatchQueue.main.async {
                        self.setLineGraph(sampleArray: doubleArray)
                    }
                }
            }
        }
    }
    
    func getSteps(completion: @escaping ([Double]) -> (Void)) {
        var sampleArray: [Double] = []
        let sevenDaysAgo = Calendar.current.date(byAdding: DateComponents(day: -7), to: Date())!
        let startDate = Calendar.current.startOfDay(for: sevenDaysAgo)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: [])
        let query = HKStatisticsCollectionQuery(quantityType: HKQuantityType.quantityType(forIdentifier: .stepCount)!, quantitySamplePredicate: predicate, options: .cumulativeSum, anchorDate: startDate, intervalComponents: DateComponents(day: 1))
        
        query.initialResultsHandler = {_, result, _ in
            guard let statsCollection = result else { return }
            statsCollection.enumerateStatistics(from: startDate, to: Date()) {
                statistics, _ in
                if let quantity = statistics.sumQuantity() {
                    let stepValue = quantity.doubleValue(for: HKUnit.count())
                    sampleArray.append(floor(stepValue))
                } else {
                    sampleArray.append(0.0)
                }
            }
            completion(sampleArray)
        }
        HKHealthStore().execute(query)
    }
    
    func setLineGraph(sampleArray: [Double]) {
        var entry = [ChartDataEntry]()
        for (i, d) in sampleArray.enumerated() {
            entry.append(ChartDataEntry(x: Double(i), y: d))
        }
        
        let dataSet = LineChartDataSet(entries: entry, label: "Step Count")
        lineChartView.data = LineChartData(dataSet: dataSet)
        lineChartView.chartDescription?.text = "Daily Steps Count Chart"
        print("LineGraph is READY!")
    }


}

