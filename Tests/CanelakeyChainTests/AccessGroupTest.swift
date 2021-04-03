//
//  AccessGroupTest.swift
//  
//
//  Created by Andres Felipe Ocampo Eljaiek on 03/04/2021.
//

import XCTest
@testable import CanelakeyChain

final class AccessGroupTest: XCTestCase {
    
    var obj: CanelakeyChain!
    
    override func setUp() {
      super.setUp()
      
      obj = CanelakeyChain()
      obj.clear()
      obj.lastQueryParameters = nil
      obj.accessGroup = nil
    }
    
    func test_AddAccessGroup() {
        let items: [String: Any] = [
          "one": "two"
        ]
        
        obj.accessGroup = "123.my.test.group"
        let result = obj.addAccessGroupWhenPresent(items)
        
        XCTAssertEqual(2, result.count)
        XCTAssertEqual("two", result["one"] as! String)
        XCTAssertEqual("123.my.test.group", result["agrp"] as! String)
    }
    
    func test_AddAccessGroup_nil() {
      let items: [String: Any] = [
        "one": "two"
      ]
      
      let result = obj.addAccessGroupWhenPresent(items)
      
      XCTAssertEqual(1, result.count)
      XCTAssertEqual("two", result["one"] as! String)
    }
    
    func test_Set() {
      obj.accessGroup = "123.my.test.group"
      obj.setValueString("hello :)", forKey: "key 1")
      XCTAssertEqual("123.my.test.group", obj.lastQueryParameters?["agrp"] as! String)
    }
    
    func test_Get() {
      obj.accessGroup = "123.my.test.group"
      _ = obj.getString("key 1")
      XCTAssertEqual("123.my.test.group", obj.lastQueryParameters?["agrp"] as! String)
    }
    
    func test_Delete() {
      obj.accessGroup = "123.my.test.group"
      obj.delete("key 1")
      XCTAssertEqual("123.my.test.group", obj.lastQueryParameters?["agrp"] as! String)
    }
    
    func test_Clear() {
      obj.accessGroup = "123.my.test.group"
      obj.clear()
      XCTAssertEqual("123.my.test.group", obj.lastQueryParameters?["agrp"] as! String)
    }
    
}
