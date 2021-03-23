//
//  UserViewControllerTests.swift
//  ARKitPersistenceTests
//
//  Created by CATE YUK on 3/23/21.
//

import XCTest
@testable import ARKitPersistence

class UserViewControllerTests: XCTestCase {
    var sut: UserViewController!
    var navigationController: UINavigationController!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        // Create an instance of UIStoryboard
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // Instantiate UIViewController with Storyboard ID
        sut = storyboard.instantiateViewController(withIdentifier: "UserViewController") as? UserViewController
        
        // Make the viewDidLoad() execute.
        sut.loadViewIfNeeded()
        navigationController = UINavigationController(rootViewController: sut)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        sut = nil
        navigationController = nil
    }
    
    func testIfUILabelsExist() throws {
        let distanceLabel: UILabel = sut.distanceLabel
        XCTAssertNotNil(distanceLabel, "User View Controller does not have a UILabel property for Distance Label")
        let infoLabel: UILabel = sut.infoLabel
        XCTAssertNotNil(infoLabel, "User View Controller does not have a UILabel property for Info Label")
    }
    
    func testIfLogoutButtonExists() throws {
        let logoutButton: UIButton = sut.logoutButton
        XCTAssertNotNil(logoutButton, "User View Controller does not have a UIButton property for Logout Button")
    }
    
    func testIfLoadButtonHasActionAssigned() {
        let loadButton: UIButton = sut.loadButton
        XCTAssertNotNil(loadButton, "User View Controller does not have a UIButton property for Load Button")
        
        // Attempt Access UIButton Actions
        guard let loadButtonActions = loadButton.actions(forTarget: sut, forControlEvent: .touchUpInside) else {
            XCTFail("UIButton does not have actions assigned for Control Event .touchUpInside")
            return
        }
     
        // Assert UIButton has action with a method name
        XCTAssertTrue(loadButtonActions.contains("loadButtonAction:"))
    }
    
    func testIfSearchButtonHasActionAssigned() {
        let searchButton: UIButton = sut.searchButton
        XCTAssertNotNil(searchButton, "User View Controller does not have a UIButton property for Search Button")
        
        // Attempt Access UIButton Actions
        guard let searchButtonActions = searchButton.actions(forTarget: sut, forControlEvent: .touchUpInside) else {
            XCTFail("UIButton does not have actions assigned for Control Event .touchUpInside")
            return
        }
     
        // Assert UIButton has action with a method name
        XCTAssertTrue(searchButtonActions.contains("searchButtonAction:"))
    }

}
