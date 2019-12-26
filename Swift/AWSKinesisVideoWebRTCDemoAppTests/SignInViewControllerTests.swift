import XCTest
import UIKit
@testable import AWSKinesisVideoWebRTCDemoApp

class SignInViewControllerTests: XCTestCase {

    var signInVC: SignInViewController?

    override func setUp() {
        let storyboard = UIStoryboard(name: "Main",bundle: Bundle.main)
        signInVC = storyboard.instantiateViewController(identifier: "signinvc")
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = signInVC
        window.makeKeyAndVisible()
    }

    override func tearDown() {
    }

    func testSignInViewControllerButtons() {
        XCTAssertNotNil(signInVC?.username)
        XCTAssertNotNil(signInVC?.password)

        XCTAssertNotNil(signInVC?.signInButton)
        XCTAssertNotNil(signInVC?.signUpButton)
        XCTAssertNotNil(signInVC?.forgotPasswordButton)
    }
}
