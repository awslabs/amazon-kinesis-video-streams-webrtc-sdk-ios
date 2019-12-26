import XCTest

class ChannelConfigurationUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() {
    }
    
    func testChannelConfigFlow() {
        
        app.launch()
            
        var usernametextfieldTextField = app.textFields[signInUserNameTextFieldKey]
        usernametextfieldTextField.tap()
        usernametextfieldTextField.typeText(testUsername)
        
        var passwordtextfieldSecureTextField = app.secureTextFields[signInPasswordTextFieldKey]
        passwordtextfieldSecureTextField.tap()
        passwordtextfieldSecureTextField.typeText(testPassword)
        
        app.buttons[signInButtonKey].tap()
        
        XCUIDevice.shared.orientation = .portrait
        
        let channelNameTextField = app.textFields[channelNameTextFieldKey]
        channelNameTextField.tap()
        channelNameTextField.typeText(testChannelName)
        
        let regionTextField = app.textFields[regionTextFieldKey]
        regionTextField.tap()
        regionTextField.typeText(testRegionName)
        app.buttons[returnButtonKey].tap()
        
        let connectAsMasterButton = app.buttons[connectAsMasterButtonKey]
        connectAsMasterButton.tap()
        
        app.staticTexts[BackButtonKey].tap()
        
        channelNameTextField.tap()
        app.buttons[returnButtonKey].tap()

        app.toolbars[testToolbarKey].buttons[signOutButtonKey].tap()

        usernametextfieldTextField = app.textFields[signInUserNameTextFieldKey]
        passwordtextfieldSecureTextField = app.secureTextFields[signInPasswordTextFieldKey]
        
        XCTAssertTrue(usernametextfieldTextField.exists)
        XCTAssertTrue(passwordtextfieldSecureTextField.exists)
    }
    
    func testChannelConfigInvalid() {
        
        app.launch()
            
        let usernametextfieldTextField = app.textFields[signInUserNameTextFieldKey]
        usernametextfieldTextField.tap()
        usernametextfieldTextField.typeText(testUsername)
        
        let passwordtextfieldSecureTextField = app.secureTextFields[signInPasswordTextFieldKey]
        passwordtextfieldSecureTextField.tap()
        passwordtextfieldSecureTextField.typeText(testPassword)
        
        app.buttons[signInButtonKey].tap()
        
        XCUIDevice.shared.orientation = .portrait
        
        let channelNameTextField = app.textFields[channelNameTextFieldKey]
        channelNameTextField.tap()
        channelNameTextField.typeText(emptyChannelName)
        
        let regionTextField = app.textFields[regionTextFieldKey]
        regionTextField.tap()
        regionTextField.typeText(emptyRegionName)
        app.buttons[returnButtonKey].tap()
        
        let connectAsMasterButton = app.buttons[connectAsMasterButtonKey]
        connectAsMasterButton.tap()
        
        var okButton = app.alerts["Missing Required Fields"].scrollViews.otherElements.buttons["Ok"]
        XCTAssertNotNil(okButton)
        XCTAssertTrue(okButton.exists)
        
        okButton.tap()
        
        let connectAsViewerButton = app.buttons[connectAsViewerButtonKey]
        connectAsViewerButton.tap()
        
        okButton = app.alerts["Missing Required Fields"].scrollViews.otherElements.buttons["Ok"]
        XCTAssertNotNil(okButton)
        XCTAssertTrue(okButton.exists)
        okButton.tap()
        
        app.toolbars[testToolbarKey].buttons[signOutButtonKey].tap()
    }

}
