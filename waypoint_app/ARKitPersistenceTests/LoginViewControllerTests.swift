////
////  LoginViewControllerTests.swift
////  ARKitPersistenceTests
////
////  Created by CATE YUK on 3/23/21.
////
//
//import XCTest
//@testable import ARKitPersistence
//
//class LoginViewControllerTests: XCTestCase {
//    var sut: LoginViewController!
//    var navigationController: UINavigationController!
//
//    override func setUpWithError() throws {
//        // Put setup code here. This method is called before the invocation of each test method in the class.
//        // Create an instance of UIStoryboard
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        
//        // Instantiate UIViewController with Storyboard ID
//        sut = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController
//        
//        // Make the viewDidLoad() execute.
//        sut.loadViewIfNeeded()
//        navigationController = UINavigationController(rootViewController: sut)
//    }
//
//    override func tearDownWithError() throws {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//        sut = nil
//        navigationController = nil
//    }
//    
//    func testIfLoginButtondExist() {
//        // Check if Login View Controller has UIButton properties
//        let loginAdminButton: UIButton = sut.adminLoginButton
//        let loginUserButton: UIButton = sut.userLoginButton
//        XCTAssertNotNil(loginAdminButton, "Login View Controller does not have a UIButton property for Login Admin")
//        XCTAssertNotNil(loginUserButton, "Login View Controller does not have a UIButton property for Login User")
//    }
//    
//    func testAdminLoginButton_WhenTapped_AdminViewControllerIsPushed() throws {
//        // Create a Predicate to evaluate if the TopViewController is AdminViewController
//        let myPredicate = NSPredicate { input, _ in
//            return (input as? UINavigationController)?.topViewController is AdminViewController
//        }
//        
//        // Create Expectation for a Predicate.
//        // This will make our unit test method, continously evalulate the
//        // predicate until it matches or expectation times out.
//        self.expectation(for: myPredicate, evaluatedWith: navigationController)
//        
//        // Act
//        sut.adminLoginButton.sendActions(for: .touchUpInside)
//        
//        waitForExpectations(timeout: 2)
//    }
//    
//    func testUserLoginButton_WhenTapped_UserViewControllerIsPushed() throws {
//        // Create a Predicate to evaluate if the TopViewController is UserViewController
//        let myPredicate = NSPredicate { input, _ in
//            return (input as? UINavigationController)?.topViewController is UserViewController
//        }
//        
//        // Create Expectation for a Predicate.
//        // This will make our unit test method, continously evalulate the
//        // predicate until it matches or expectation times out.
//        self.expectation(for: myPredicate, evaluatedWith: navigationController)
//        
//        // Act
//        sut.userLoginButton.sendActions(for: .touchUpInside)
//        
//        waitForExpectations(timeout: 2)
//    }
//
//}
