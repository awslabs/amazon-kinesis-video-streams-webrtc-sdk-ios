import Foundation
import Starscream
import WebRTC

// interface for remote connectivity events
protocol SignalClientDelegate: class {
    func signalClientDidConnect(_ signalClient: SignalingClient)
    func signalClientDidDisconnect(_ signalClient: SignalingClient)
    func signalClient(_ signalClient: SignalingClient, senderClientId: String, didReceiveRemoteSdp sdp: RTCSessionDescription)
    func signalClient(_ signalClient: SignalingClient, senderClientId: String, didReceiveCandidate candidate: RTCIceCandidate)
}

final class SignalingClient {
    private let socket: WebSocket
    private let encoder = JSONEncoder()
    weak var delegate: SignalClientDelegate?

    init(serverUrl: URL) {
        socket = WebSocket(url: serverUrl)
    }

    func connect() {
        socket.delegate = self
        socket.connect()
    }
    
    func disconnect() {
        socket.disconnect()
    }

    func sendOffer(rtcSdp: RTCSessionDescription, senderClientid: String) {
        debugPrint("Sending SDP offer \(rtcSdp)")

        let message: Message = Message.createOfferMessage(sdp: rtcSdp.sdp, senderClientId: senderClientid)
        let data = try! encoder.encode(message)
        let msg = String(data: data, encoding: .utf8)!

        socket.write(string: msg)
        print("Sent SDP offer message over to signaling:", msg)
    }

    func sendAnswer(rtcSdp: RTCSessionDescription, recipientClientId: String) {
        debugPrint("Sending SDP answer\(rtcSdp)")

        let message: Message = Message.createAnswerMessage(sdp: rtcSdp.sdp, recipientClientId)
        let data = try! encoder.encode(message)
        let msg = String(data: data, encoding: .utf8)!

        socket.write(string: msg)
        print("Sent SDP answer message over to signaling:", msg)
    }

    func sendIceCandidate(rtcIceCandidate: RTCIceCandidate, master: Bool,
                          recipientClientId: String,
                          senderClientId: String) {
        debugPrint("Sending ICE candidate \(rtcIceCandidate)")

        let message: Message = Message.createIceCandidateMessage(candidate: rtcIceCandidate,
                                                                 master,
                                                                 recipientClientId: recipientClientId,
                                                                 senderClientId: senderClientId)
        let data = try! encoder.encode(message)
        let msg = String(data: data, encoding: .utf8)!

        socket.write(string: msg)
        print("Sent ICE candidate message over to signaling:", msg)
    }
}

// Mark: Websocket
extension SignalingClient: WebSocketDelegate {
    func websocketDidConnect(socket _: WebSocketClient) {
        delegate?.signalClientDidConnect(self)
        debugPrint("Connection to signaling success.")
    }

    func websocketDidDisconnect(socket _: WebSocketClient, error: Error?) {
        delegate?.signalClientDidDisconnect(self)
        debugPrint("Disconnected from signaling. \(error!)")
    }

    func websocketDidReceiveData(socket _: WebSocketClient, data: Data) {
        debugPrint("Additional signaling data (not supported) \(data)")
    }

    func websocketDidReceiveMessage(socket _: WebSocketClient, text: String) {
        debugPrint("Additional signaling messages \(text)")
        var parsedMessage: Message?

        parsedMessage = Event.parseEvent(event: text)

        if parsedMessage != nil {
            let messagePayload = parsedMessage?.getMessagePayload()

            let messageType = parsedMessage?.getAction()
            let senderClientId = parsedMessage?.getSenderClientId()
            let message: String = String(messagePayload!.base64Decoded()!)

            do {
                let jsonObject = try message.trim().convertToDictionary()
                if jsonObject.count != 0 {
                    if messageType == "SDP_OFFER" {
                        let sdp: String = jsonObject["sdp"] as! String
                        let rcSessionDescription: RTCSessionDescription = RTCSessionDescription(type: .offer, sdp: sdp)
                        delegate?.signalClient(self, senderClientId: senderClientId!, didReceiveRemoteSdp: rcSessionDescription)
                        debugPrint("SDP offer received from signaling \(sdp)")
                    } else if messageType == "SDP_ANSWER" {
                        let sdp: String = jsonObject["sdp"] as! String
                        let rcSessionDescription: RTCSessionDescription = RTCSessionDescription(type: .answer, sdp: sdp)
                        delegate?.signalClient(self, senderClientId: "", didReceiveRemoteSdp: rcSessionDescription)
                        debugPrint("SDP answer received from signaling \(sdp)")
                    } else if messageType == "ICE_CANDIDATE" {
                        let iceCandidate: String = jsonObject["candidate"] as! String
                        let sdpMid: String = jsonObject["sdpMid"] as! String
                        let sdpMLineIndex: Int32 = jsonObject["sdpMLineIndex"] as! Int32
                        let rtcIceCandidate: RTCIceCandidate = RTCIceCandidate(sdp: iceCandidate, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
                        delegate?.signalClient(self, senderClientId: senderClientId!, didReceiveCandidate: rtcIceCandidate)
                        debugPrint("ICE candidate received from signaling \(iceCandidate)")
                    }
                } else {
                    dump(jsonObject)
                }
            } catch {
                print("payLoad parsing Error \(error)")
            }
        }
    }
}

extension String {
    func convertToDictionary() throws -> [String: Any] {
        let data = Data(utf8)

        if let anyResult = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            return anyResult
        } else {
            return [:]
        }
    }
}
