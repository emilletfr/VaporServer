//
//  OutdoorTempServiceTests.swift
//  VaporApp
//
//  Created by Eric on 17/12/2016.
//
//

import XCTest
import RxSwift

class OutdoorTempServiceTests: XCTestCase {
    
    func testRetrieveTemp() {
        
            let expectation = self.expectation(description: "Handler called")
            let outdoorTempService = OutdoorTempService()
            _  = outdoorTempService.temperatureObserver.subscribe { (event) in
                print(event)
                XCTAssertNil(event.error)
                expectation.fulfill()
            }
            self.waitForExpectations(timeout: 10) { (error:Error?) in print(error as Any)}
    
    
    }
    
    
    
}