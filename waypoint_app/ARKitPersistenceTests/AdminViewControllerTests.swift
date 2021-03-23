//
//  AdminViewControllerTests.swift
//  ARKitPersistenceTests
//
//  Created by CATE YUK on 3/23/21.
//

import XCTest
@testable import ARKitPersistence

class AdminViewControllerTests: XCTestCase {
    var sut: AdminViewController!
    var navigationController: UINavigationController!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        // Create an instance of UIStoryboard
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // Instantiate UIViewController with Storyboard ID
        sut = storyboard.instantiateViewController(withIdentifier: "AdminViewController") as? AdminViewController
        
        // Make the viewDidLoad() execute.
        sut.loadViewIfNeeded()
        navigationController = UINavigationController(rootViewController: sut)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        sut = nil
        navigationController = nil
    }
    
    func testIfUILabelExists() throws {
        let logoutButton: UIButton = sut.logoutButton
        XCTAssertNotNil(logoutButton, "Admin View Controller does not have a UIButton property for Logout Button")
        let infoLabel: UILabel = sut.infoLabel
        XCTAssertNotNil(infoLabel, "Admin View Controller does not have a UILabel property for Info Label")
    }
    
    func testIfLogoutButtonExists() throws {
        let logoutButton: UIButton = sut.logoutButton
        XCTAssertNotNil(logoutButton, "Admin View Controller does not have a UIButton property for Logout Button")
    }
    
    func testIfLoadButtonHasActionAssigned() {
        let loadButton: UIButton = sut.loadButton
        XCTAssertNotNil(loadButton, "Admin View Controller does not have a UIButton property for Load Button")
        
        // Attempt Access UIButton Actions
        guard let loadButtonActions = loadButton.actions(forTarget: sut, forControlEvent: .touchUpInside) else {
            XCTFail("UIButton does not have actions assigned for Control Event .touchUpInside")
            return
        }
     
        // Assert UIButton has action with a method name
        XCTAssertTrue(loadButtonActions.contains("loadButtonAction:"))
    }
    
    func testIfResetButtonHasActionAssigned() {
        let resetButton: UIButton = sut.resetButton
        XCTAssertNotNil(resetButton, "Admin View Controller does not have a UIButton property for Reset Button")
        
        // Attempt Access UIButton Actions
        guard let resetButtonActions = resetButton.actions(forTarget: sut, forControlEvent: .touchUpInside) else {
            XCTFail("UIButton does not have actions assigned for Control Event .touchUpInside")
            return
        }
     
        // Assert UIButton has action with a method name
        XCTAssertTrue(resetButtonActions.contains("resetButtonAction:"))
    }
    
    func testIfSaveButtonHasActionAssigned() {
        let saveButton: UIButton = sut.saveButton
        XCTAssertNotNil(saveButton, "Admin View Controller does not have a UIButton property for Save Button")
        
        // Attempt Access UIButton Actions
        guard let saveButtonActions = saveButton.actions(forTarget: sut, forControlEvent: .touchUpInside) else {
            XCTFail("UIButton does not have actions assigned for Control Event .touchUpInside")
            return
        }
     
        // Assert UIButton has action with a method name
        XCTAssertTrue(saveButtonActions.contains("saveButtonAction:"))
    }
}
