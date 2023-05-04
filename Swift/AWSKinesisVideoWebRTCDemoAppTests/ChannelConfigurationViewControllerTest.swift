import XCTest
import UIKit
@testable import AWSKinesisVideoWebRTCDemoApp

class ChannelConfigurationViewControllerTest: XCTestCase {

    var channelVC: ChannelConfigurationViewController?
    
    override func setUp() {
        let storyboard = UIStoryboard(name: "Main",bundle: Bundle.main)
        channelVC = storyboard.instantiateViewController(identifier: "channelvc")
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = channelVC
        window.makeKeyAndVisible()
    }

    override func tearDown() {
    }

    func testChannelConfigButtons() {
        XCTAssertNotNil(channelVC?.connectAsMasterButton)
        XCTAssertNotNil(channelVC?.connectAsViewerButton)
        XCTAssertNotNil(channelVC?.connectedLabel)
        
        XCTAssertTrue((channelVC?.sendAudioEnabled)!)
    }
    
    func testUpdateConnectionLabel() {
        XCTAssertNotNil(channelVC?.connectedLabel)
        
        XCTAssertFalse(channelVC!.signalingConnected)
        channelVC?.updateConnectionLabel()
        XCTAssertEqual(channelVC?.connectedLabel.text, "Not Connected")
        XCTAssertTrue(channelVC?.connectedLabel.textColor == .red)


        channelVC?.signalingConnected = true
        channelVC?.updateConnectionLabel()
        XCTAssertEqual(channelVC?.connectedLabel.text, "Connected")
        XCTAssertTrue(channelVC?.connectedLabel.textColor == .green)
    }
    
    func testConnectAsMaster() {
        XCTAssertNotNil(channelVC?.connectAsMasterButton)
        XCTAssertNotNil(channelVC?.connectAsViewerButton)
        XCTAssertNotNil(channelVC?.connectedLabel)

        channelVC?.connectAsMaster(channelVC!)
        XCTAssertTrue((channelVC?.isMaster)!)
    }
    
    func testConnectAsMasterChannelEmptyRegionEmpty() {
        XCTAssertNotNil(channelVC?.connectAsMasterButton)
        XCTAssertNotNil(channelVC?.connectAsViewerButton)
        XCTAssertNotNil(channelVC?.connectedLabel)
        
        channelVC?.connectAsMaster(channelVC!)
        XCTAssertTrue((channelVC?.isMaster)!)

        // Channel name and region name are empty
        channelVC?.isMaster = true
        channelVC?.connectAsRole()
        XCTAssertTrue(channelVC?.presentedViewController is UIAlertController)
        XCTAssertEqual(channelVC?.presentedViewController?.title, "Missing Required Fields")
        
    }
    
    func testConnectAsMasterValidChannelNameEmptyRegion() {
        
        XCTAssertNotNil(channelVC?.connectAsMasterButton)
        XCTAssertNotNil(channelVC?.connectAsViewerButton)
        XCTAssertNotNil(channelVC?.connectedLabel)
        
        channelVC?.connectAsMaster(channelVC!)
        XCTAssertTrue((channelVC?.isMaster)!)

        // Channel name is set to `test`
        // Region is empty
        channelVC?.channelName.text = "test"
        channelVC?.isMaster = true
        channelVC?.connectAsRole()
        XCTAssertTrue(channelVC?.presentedViewController is UIAlertController)
        XCTAssertEqual(channelVC?.presentedViewController?.title, "Missing Required Fields")
        
    }
    func testConnectAsMasterInvalidRegion() {
        XCTAssertNotNil(channelVC?.connectAsMasterButton)
        XCTAssertNotNil(channelVC?.connectAsViewerButton)
        XCTAssertNotNil(channelVC?.connectedLabel)
        
        channelVC?.connectAsMaster(channelVC!)
        XCTAssertTrue((channelVC?.isMaster)!)

        // Channel name is set to `test`
        // Region Name is invalid and set to `us-west-3`
        channelVC?.channelName.text = "test-123"
        channelVC?.regionName.text = "us-west-3"
        channelVC?.isMaster = true
        channelVC?.connectAsRole()
        XCTAssertTrue(channelVC?.presentedViewController is UIAlertController)
        XCTAssertEqual(channelVC?.presentedViewController?.title, "Missing Required Fields")
    }
    
    func testConnectAsViewer() {
        channelVC?.connectAsViewer(_sender: channelVC!)
        XCTAssertFalse(channelVC!.isMaster)
    }
    
    func testRetrieveChannelARN() {
        XCTAssertNil(channelVC?.retrieveChannelARN(channelName: ""))
    }
    
    func testGetSingleMasterChannelEndpointRoleWithMasterRole() {
        let masterRole = channelVC?.getSingleMasterChannelEndpointRole(isMaster: true)
        XCTAssertEqual(masterRole, .master)
    }
    
    func testGetSingleMasterChannelEndpointRoleWithViewerRole() {
        let viewerRole = channelVC?.getSingleMasterChannelEndpointRole(isMaster: false)
        XCTAssertEqual(viewerRole, .viewer)
    }
    
    func testAudioStateChanged() {
        XCTAssertTrue((channelVC?.sendAudioEnabled)!)
        
        channelVC?.isAudioEnabled.isOn = true
        channelVC?.audioStateChanged(sender: channelVC?.isAudioEnabled)
        XCTAssertTrue((channelVC?.sendAudioEnabled)!)

        channelVC?.isAudioEnabled.isOn = false
        channelVC?.audioStateChanged(sender: channelVC?.isAudioEnabled)
        XCTAssertFalse((channelVC?.sendAudioEnabled)!)

    }
}
