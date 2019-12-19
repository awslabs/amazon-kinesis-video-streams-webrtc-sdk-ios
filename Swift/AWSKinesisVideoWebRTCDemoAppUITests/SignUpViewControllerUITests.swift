import XCTest

class SignUpViewControllerUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = true
        XCUIApplication().launch()
    }

    override func tearDown() {
    }

    func testSignUpWithInvalidInput() {
        
        let app = XCUIApplication()
        let signUp = app.buttons[signUpButton]
        signUp.tap()
        
        let usernameTextField = app.textFields[signUpUserNameTextFieldKey]
        usernameTextField.tap()
        
        let passwordTextField = app.secureTextFields[signUpPasswordTextFieldKey]
        passwordTextField.tap()
        
        let phoneNumberTextField = app.textFields[signUpPhoneNumberTextFieldKey]
        phoneNumberTextField.tap()
        
        let emailTextField = app.textFields[signUpEmailTextFieldKey]
        emailTextField.tap()
        
        let signUpButton = app.buttons[signUpConfirmButton]
        signUpButton.tap()
        
        // verify if alert shows
        let signUpAlert = app.alerts["Missing Required Fields"]
        XCTAssertNotNil(signUpAlert)

        let alertOkButton = signUpAlert.scrollViews.otherElements.buttons[OKButtonKey]
        XCTAssertNotNil(alertOkButton)
        
        signUpAlert.tap()
    }

}
