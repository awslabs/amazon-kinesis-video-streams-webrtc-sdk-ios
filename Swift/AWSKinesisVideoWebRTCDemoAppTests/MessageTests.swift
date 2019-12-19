import XCTest
import AWSKinesisVideoWebRTCDemoApp
import WebRTC

class MessageTests: XCTestCase {

    var testMessage: Message?

    override func setUp() {
    }

    override func tearDown() {
    }

    func testCreateAnswerMessage() {
        let actualMessage  = Message.createAnswerMessage(sdp: testsdp, testRecipientClientId)
        XCTAssertEqual(actualMessage.getAction(), answerAction)
        XCTAssertNotNil(actualMessage.getMessagePayload)
        XCTAssertNotNil(actualMessage.getRecipientClientId)
        XCTAssertEqual(actualMessage.getRecipientClientId(), testRecipientClientId)
    }
    
    func testCreateOfferMessage() {
        let actualMessage  = Message.createOfferMessage(sdp: testsdp, senderClientId: testSenderClientId)
        XCTAssertEqual(actualMessage.getAction(), offerAction)
        XCTAssertNotNil(actualMessage.getMessagePayload)
        XCTAssertNotNil(actualMessage.getSenderClientId)
        XCTAssertEqual(actualMessage.getSenderClientId(), testSenderClientId)
    }
    
    func testIceCandidates_isMaster() {
        let testRTCIceCandidate = RTCIceCandidate.init(sdp: testMessagePayload, sdpMLineIndex: 3, sdpMid: testMessagePayload)

        let actualMessage  = Message.createIceCandidateMessage(candidate: testRTCIceCandidate, true, recipientClientId: testRecipientClientId, senderClientId: testSenderClientId)
        XCTAssertEqual(actualMessage.getAction(), iceCandidateAction)
        XCTAssertNotNil(actualMessage.getMessagePayload)
        XCTAssertNotNil(actualMessage.getSenderClientId)
        XCTAssertEqual(actualMessage.getSenderClientId(), "") //senderClientId is empty when connected as master
        XCTAssertNotNil(actualMessage.getRecipientClientId)
        XCTAssertEqual(actualMessage.getRecipientClientId(), testRecipientClientId)
    }
    
    func testIceCandidates_isViewer() {
        let testRTCIceCandidate = RTCIceCandidate.init(sdp: testMessagePayload, sdpMLineIndex: 3, sdpMid: testMessagePayload)

        let actualMessage  = Message.createIceCandidateMessage(candidate: testRTCIceCandidate, false, recipientClientId: testRecipientClientId, senderClientId: testSenderClientId)
        XCTAssertEqual(actualMessage.getAction(), iceCandidateAction)
        XCTAssertNotNil(actualMessage.getMessagePayload)
        XCTAssertNotNil(actualMessage.getSenderClientId)
        XCTAssertEqual(actualMessage.getSenderClientId(), testSenderClientId)
        XCTAssertNotNil(actualMessage.getRecipientClientId)
        XCTAssertEqual(actualMessage.getRecipientClientId(), "") //recipientClient is empty when connected as viewer
    }
}
