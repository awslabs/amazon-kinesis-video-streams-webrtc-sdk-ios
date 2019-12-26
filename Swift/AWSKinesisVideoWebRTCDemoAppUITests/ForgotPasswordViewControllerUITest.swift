import XCTest

class ForgotPasswordViewControllerUITest: XCTestCase {

    override func setUp() {
        continueAfterFailure = true
        XCUIApplication().launch()
    }

    override func tearDown() {
    }

    func testInvalidUsernameForgotPassword() {
        
        let app = XCUIApplication()
        app.buttons[signInForgotPasswordButton].tap()
        let forgotpasswordusernametextfieldTextField = app.textFields[forgotPasswordUsernameTextFieldKey]
        forgotpasswordusernametextfieldTextField.tap()
        forgotpasswordusernametextfieldTextField.typeText("h")
        app.buttons[forgotPasswordViewForgotPasswordButton].tap()
        let userNotFoundAlert = app.alerts["UserNotFoundException"]
        let alertOKbutton = userNotFoundAlert.scrollViews.otherElements.buttons["Ok"]
        alertOKbutton.tap()
    }
    
    func testEmptyUsernameForgotPassword() {
        
        let app = XCUIApplication()
        app.buttons[signInForgotPasswordButton].tap()
        let forgotpasswordusernametextfieldTextField = app.textFields[forgotPasswordUsernameTextFieldKey]
        forgotpasswordusernametextfieldTextField.tap()
        app.buttons[forgotPasswordViewForgotPasswordButton].tap()
        let missingUsernameAlert = app.alerts["Missing UserName"]
        let alertOKbutton = missingUsernameAlert.scrollViews.otherElements.buttons["Ok"]
        XCTAssertTrue(alertOKbutton.exists)
        alertOKbutton.tap()
    }
    
    func testEmptyPassword() {
        
        let app = XCUIApplication()
        app.buttons[signInForgotPasswordButton].tap()
        let forgotpasswordusernametextfieldTextField = app.textFields[forgotPasswordUsernameTextFieldKey]
        forgotpasswordusernametextfieldTextField.tap()
        forgotpasswordusernametextfieldTextField.typeText(testUsername)
        
        app.buttons[forgotPasswordViewForgotPasswordButton].tap()
        app.textFields[confirmForgotPasswordCodeConfirmationTextFieldKey].tap()
        let newPasswordSecureTextField = app.secureTextFields[confirmForgotPasswordNewPasswordTextFieldKey]
        newPasswordSecureTextField.tap()
        app.buttons["Update Password"].tap()
        app.alerts["Password Field Empty"].scrollViews.otherElements.buttons["Ok"].tap()
        app.navigationBars["AWSKinesisVideoWebRTCDemoApp.ConfirmForgotPasswordView"].buttons["Back"].tap()
    }
    
    func testInvalidPassword() {
        
        let app = XCUIApplication()
        app.buttons[signInForgotPasswordButton].tap()
        let forgotpasswordusernametextfieldTextField = app.textFields[forgotPasswordUsernameTextFieldKey]
        forgotpasswordusernametextfieldTextField.tap()
        forgotpasswordusernametextfieldTextField.typeText(testUsername)
        
        app.buttons[forgotPasswordViewForgotPasswordButton].tap()
        let confirmationCodeTextfield = app.textFields[confirmForgotPasswordCodeConfirmationTextFieldKey]
        confirmationCodeTextfield.tap()
        confirmationCodeTextfield.typeText("1233")
        let newPasswordSecureTextField = app.secureTextFields[confirmForgotPasswordNewPasswordTextFieldKey]
        newPasswordSecureTextField.tap()
        newPasswordSecureTextField.typeText("abcd")
        app.buttons["Update Password"].tap()
        app.alerts["InvalidParameterException"].scrollViews.otherElements.buttons["Ok"].tap()
        app.navigationBars["AWSKinesisVideoWebRTCDemoApp.ConfirmForgotPasswordView"].buttons["Back"].tap()
    }

}
