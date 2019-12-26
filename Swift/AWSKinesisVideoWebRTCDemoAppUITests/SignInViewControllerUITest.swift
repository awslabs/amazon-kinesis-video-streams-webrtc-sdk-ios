import XCTest

class SignInViewControllerUITest: XCTestCase {

    var app: XCUIApplication!
    
    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() {
    }

    func testSignInFlow() {
        app.launch()
        
        let app = XCUIApplication()
        
        let usernametextfieldTextField = app.textFields[signInUserNameTextFieldKey]
        usernametextfieldTextField.tap()
        usernametextfieldTextField.typeText(testUsername)
        
        let passwordtextfieldSecureTextField = app.secureTextFields[signInPasswordTextFieldKey]
        passwordtextfieldSecureTextField.tap()
        passwordtextfieldSecureTextField.typeText(testPassword)
        
        app.buttons[signInButtonKey].tap()
        
        // Tapping sign out should re-direct to sign-in
        app.toolbars[testToolbarKey].buttons[signOutButtonKey].tap()
        
        // presence of signin view buttons
        XCTAssertTrue(usernametextfieldTextField.exists)
        XCTAssertTrue(passwordtextfieldSecureTextField.exists)
    }
    
    func testSignInWithInvalidValues() {
        
        app.launch()
        let app = XCUIApplication()
        
        // Empty strings for username and password and tap signin button
        app.textFields[signInUserNameTextFieldKey].tap()
        app.secureTextFields[signInPasswordTextFieldKey].tap()
        app.buttons[signInButtonKey].tap()
        
        // verify if alert shows
        let loginAlert = app.alerts["Login Error"]
        XCTAssertNotNil(loginAlert)

        let alertOkButton = loginAlert.scrollViews.otherElements.buttons[OKButtonKey]
        XCTAssertNotNil(alertOkButton)
        
        alertOkButton.tap()
    }
}
