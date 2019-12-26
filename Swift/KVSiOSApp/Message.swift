import WebRTC

public class Message: Codable {
    private var action: String
    private var recipientClientId: String?
    private var senderClientId: String?
    private var messagePayload: String

    public init(_ action: String, _ senderClientId: String, _ messagePayload: String) {
        self.action = action
        recipientClientId = nil
        self.senderClientId = senderClientId
        self.messagePayload = messagePayload
    }

    public init(_ action: String, _ recipientClientId: String, _ senderClientId: String, _ messagePayload: String) {
        self.action = action
        self.recipientClientId = recipientClientId
        self.senderClientId = senderClientId
        self.messagePayload = messagePayload
    }

    public func getAction() -> String {
        return action
    }

    public func setAction(action: String) {
        self.action = action
    }

    public func getRecipientClientId() -> String {
        if recipientClientId != nil {
            return recipientClientId!
        } else { return "" }
    }

    public func setRecipientClientId(recipientClientId: String) {
        self.recipientClientId = recipientClientId
    }

    public func getSenderClientId() -> String {
        if senderClientId != nil {
            return senderClientId!
        } else { return "" }
    }

    public func setSenderClientId(senderClientId: String) {
        self.senderClientId = senderClientId
    }

    public func getMessagePayload() -> String {
        return messagePayload
    }

    public func setMessagePayload(messagePayload: String) {
        self.messagePayload = messagePayload
    }

    /**
     * @param sdp: session description sdp (answer)
     * @param recipientClientId: set the remote senderClientId as recipientClientId for answering
     * @return SDP answer message to be sent to signaling service
     */
    public class func createAnswerMessage(sdp: String, _ recipientClientId: String) -> Message {
        let answerPayload: String = "{\"type\":\"answer\",\"sdp\":\"" +
            sdp.replacingOccurrences(of: "\r\n", with: "\\r\\n") + "\"}"
        let encodedAnswer: String = answerPayload.data(using: .utf8)!.base64EncodedString()
        // recipientClientId is remote's senderclientId
        // senderClient id is not required
        return Message("SDP_ANSWER", recipientClientId, "", encodedAnswer)
    }

    /**
     * @param session description sdp (offer)
     * @param senderClientId: set the local senderClientId when sending offer
     * @return SDP offer message to be sent to signaling service
     */
    public class func createOfferMessage(sdp: String, senderClientId: String) -> Message {
        let offerPayload: String = "{\"type\":\"offer\",\"sdp\":\"" +
            sdp.replacingOccurrences(of: "\r\n", with: "\\r\\n") + "\"}"
        let encodedOffer: String = offerPayload.data(using: .utf8)!.base64EncodedString()

        // recipientClientId is not applicable as we are sending offer to master
        // senderClientId is local client id
        return Message("SDP_OFFER", "", senderClientId, encodedOffer)
    }

    /**
     * @param candidate: ice candidate to be sent to the remote peer
     * @param master: true if local is set as the master
     * @param recipientClientId: set the remote senderClientId as recipientClientId in master mode
     * @param senderClientId: set the local senderClientId in viewer mode
     * @return ICE candidate message to be sent to signaling service
     */
    public class func createIceCandidateMessage(candidate: RTCIceCandidate, _ master: Bool,
                                                recipientClientId: String,
                                                senderClientId: String) -> Message {
        let sdpMid: String = candidate.sdpMid!
        let sdpMLineIndex: Int32 = candidate.sdpMLineIndex
        let sdp: String = candidate.sdp

        let messagePayload: String =
            "{\"candidate\":\"" + sdp + "\",\"sdpMid\":\"" + sdpMid
                + "\",\"sdpMLineIndex\":" + String(sdpMLineIndex) + "}"

        if master {
            print("Master mode Ice candidate")
            // recipientclientid is remote senderclientId
            // senderClientId is not required for master mode
            // e.g Message("ICE_CANDIDATE",  "ConsumerViewerJS", "", messagePayload.data(using: .utf8)!.base64EncodedString())
            return Message("ICE_CANDIDATE", recipientClientId, "",
                           messagePayload.data(using: .utf8)!.base64EncodedString())

        } else {
            print("Viewer mode Ice candidate")
            // recipientclientid is nil as we are sending to master
            // senderClientId is local client id
            // e.g Message("ICE_CANDIDATE", "ConsumerViewer2", messagePayload.data(using: .utf8)!.base64EncodedString())
            return Message("ICE_CANDIDATE", senderClientId, messagePayload.data(using: .utf8)!.base64EncodedString())
        }
    }
}
