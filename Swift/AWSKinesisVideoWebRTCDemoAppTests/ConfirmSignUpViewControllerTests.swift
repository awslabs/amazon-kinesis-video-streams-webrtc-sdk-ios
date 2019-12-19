import XCTest
import UIKit
@testable import AWSKinesisVideoWebRTCDemoApp

class ConfirmSignUpViewControllerTests: XCTestCase {

    var confirmSignUpViewControllerTest: ConfirmSignUpViewController?

    override func setUp() {
        let storyboard = UIStoryboard(name: "Main",bundle: Bundle.main)
        confirmSignUpViewControllerTest = storyboard.instantiateViewController(identifier: "confirm-signup")
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = confirmSignUpViewControllerTest
        window.makeKeyAndVisible()
    }

    override func tearDown() {
    }

    func testConfirmSignUpViewControllerUIComponents() {
        XCTAssertNotNil(confirmSignUpViewControllerTest?.sentToLabel)
        XCTAssertNotNil(confirmSignUpViewControllerTest?.username)
        XCTAssertNotNil(confirmSignUpViewControllerTest?.code)
    }
    
    func testConfirmButtonAction() {
        confirmSignUpViewControllerTest?.confirm((confirmSignUpViewControllerTest)!)
        XCTAssertTrue(confirmSignUpViewControllerTest?.presentedViewController is UIAlertController)

    }
    
    func testResendAction() {
        confirmSignUpViewControllerTest?.resend((confirmSignUpViewControllerTest)!)
    }
    
    func testConfirmButtonWithValidValues() {
        confirmSignUpViewControllerTest?.sentToLabel.text = "+112345678900"
        confirmSignUpViewControllerTest?.code.text = "123456"
        confirmSignUpViewControllerTest?.username.text = testUsername
        confirmSignUpViewControllerTest?.confirm((confirmSignUpViewControllerTest)!)
        
        XCTAssertNotNil(confirmSignUpViewControllerTest?.sentToLabel.text)
        XCTAssertNotNil(confirmSignUpViewControllerTest?.username.text)
        XCTAssertNotNil(confirmSignUpViewControllerTest?.code.text)
    }
}
