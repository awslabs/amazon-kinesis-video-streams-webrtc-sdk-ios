import Foundation
import WebRTC

public class Event {
    public class func parseEvent(event: String) -> Message? {
        do {
            print("Event = \(event)")

            let payLoad = try event.convertToDictionaryValueAsString()

            if payLoad.count >= 2 {
                print(payLoad)

                let messageType: String = payLoad["messageType"]! as! String
                let messagePayload: String = payLoad["messagePayload"]! as! String
                if let senderClientId = payLoad["senderClientId"] {
                    print("senderClientId : \(senderClientId)")
                    return Message(messageType, "", senderClientId as! String, messagePayload)
                } else {
                    return Message(messageType, "", "", messagePayload)
                }
            }

        } catch {
            print("payload Error \(error)")
        }
        return nil
    }
}

extension String {
    public func base64Encoded() -> String? {
        return data(using: .utf8)?.base64EncodedString()
    }

    public func base64Decoded() -> String? {
        print("decode base64")

        var localData: Data?
        localData = Data(base64Encoded: self)
        var temp: String = self
        if localData == nil {
            temp = self + "=="
        }
        guard let data = Data(base64Encoded: temp, options: Data.Base64DecodingOptions(rawValue: 0)) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    public func convertToDictionaryValueAsString() throws -> [String: Any] {
        let data = Data(utf8)

        if let anyResult = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            return anyResult
        } else {
            return [:]
        }
    }
}

