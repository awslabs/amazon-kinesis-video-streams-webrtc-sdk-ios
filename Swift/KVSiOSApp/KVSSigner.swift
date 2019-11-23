import CommonCrypto
import Foundation

let ALGORITHM_AWS4_HMAC_SHA_256 = "AWS4-HMAC-SHA256"
let AWS4_REQUEST_TYPE = "aws4_request"
let AWS_SERVICE = "kinesisvideo"
let X_AMZ_ALGORITHM = "X-Amz-Algorithm"
let X_AMZ_CREDENTIAL = "X-Amz-Credential"
let X_AMZ_DATE = "X-Amz-Date"
let X_AMZ_EXPIRES = "X-Amz-Expires"
let X_AMZ_SECURITY_TOKEN = "X-Amz-Security-Token"
let X_AMZ_SIGNATURE = "X-Amz-Signature"
let X_AMZ_SIGNED_HEADERS = "X-Amz-SignedHeaders"
let NEW_LINE_DELIMITER = "\n"
let SLASH_DELIMITER = "/"
let AWS_REGION = "us-west-2"
let REST_METHOD = "GET"
let UTC_DATE_FORMATTER = "yyyyMMdd'T'HHmmss'Z'"
let TIMEZONE = "UTC"

func iso8601() -> (fullDateTimestamp: String, shortDate: String) {
    let dateFormatter: DateFormatter = DateFormatter()
    dateFormatter.dateFormat = UTC_DATE_FORMATTER
    dateFormatter.timeZone = TimeZone(abbreviation: TIMEZONE)
    let date = Date()
    let dateString = dateFormatter.string(from: date)
    let index = dateString.index(dateString.startIndex, offsetBy: 8)
    let shortDate = dateString.substring(to: index)
    return (fullDateTimestamp: dateString, shortDate: shortDate)
}

private extension Data {
    func toHexString() -> String {
        let hexString = map { String(format: "%02x", $0) }.joined()
        return hexString
    }
    
    func bytes() -> [UInt8] {
        let array = [UInt8](self)
        return array
    }
}

extension String {
    func sha256() -> String {
        if let stringData = self.data(using: String.Encoding.utf8) {
            return hexStringFromData(input: digest(input: stringData as NSData))
        }
        return ""
    }
    
    private func digest(input: NSData) -> NSData {
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        var hash = [UInt8](repeating: 0, count: digestLength)
        CC_SHA256(input.bytes, UInt32(input.length), &hash)
        return NSData(bytes: hash, length: digestLength)
    }
    
    private func hexStringFromData(input: NSData) -> String {
        var bytes = [UInt8](repeating: 0, count: input.length)
        input.getBytes(&bytes, length: input.length)
        
        var hexString = ""
        for byte in bytes {
            hexString += String(format: "%02x", UInt8(byte))
        }
        
        return hexString
    }
    
    func hmac(keyString: String) -> Data {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), keyString, keyString.count, self, count, &digest)
        let data = Data(bytes: digest)
        return data
    }
    
    func hmac(keyData: Data) -> Data {
        let keyBytes = keyData.bytes()
        let data = cString(using: String.Encoding.utf8)
        let dataLen = Int(lengthOfBytes(using: String.Encoding.utf8))
        var result = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), keyBytes, keyData.count, data, dataLen, &result)
        
        return Data(bytes: result)
    }
}

/*
 DateKey              = HMAC-SHA256("AWS4"+"<SecretAccessKey>", "<YYYYMMDD>")
 DateRegionKey        = HMAC-SHA256(<DateKey>, "<aws-region>")
 DateRegionServiceKey = HMAC-SHA256(<DateRegionKey>, "<aws-service>")
 SigningKey           = HMAC-SHA256(<DateRegionServiceKey>, "aws4_request")
 */
private func signatureWith(stringToSign: String, secretAccessKey: String, shortDateString: String, awsRegion: String, serviceType: String) -> String? {
    
    let firstKey = "AWS4" + secretAccessKey
    let dateKey = shortDateString.hmac(keyString: firstKey)
    let dateRegionKey = awsRegion.hmac(keyData: dateKey)
    let dateRegionServiceKey = serviceType.hmac(keyData: dateRegionKey)
    let signingKey = AWS4_REQUEST_TYPE.hmac(keyData: dateRegionServiceKey)
    
    let signature = stringToSign.hmac(keyData: signingKey)
    return signature.toHexString()
}

class KVSSigner {
    static func sign(signRequest: URL, secretKey: String, accessKey: String, sessionToken: String,
                     wssRequest: URL, region: String) -> URL? {
        let signedRequest = signRequest
        
        let date = iso8601()
        guard let host = signedRequest.host
            else { return .none }
        
        var canonicalUri = signedRequest.path
        if (canonicalUri.isEmpty) {
            canonicalUri = SLASH_DELIMITER
        }
        let canonicalHeaders = "host:" + host + NEW_LINE_DELIMITER
        let signedHeaders = "host"
        
        let credentialArray = [date.shortDate, region, AWS_SERVICE, AWS4_REQUEST_TYPE]
        let credentialScope = credentialArray.joined(separator: SLASH_DELIMITER)
        
        var queryParamsBuilder = [URLQueryItem]()
        queryParamsBuilder.append(URLQueryItem(name: X_AMZ_ALGORITHM, value: ALGORITHM_AWS4_HMAC_SHA_256))
        queryParamsBuilder.append(URLQueryItem(name: X_AMZ_CREDENTIAL, value: (accessKey + "/" + credentialScope).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!))
        queryParamsBuilder.append(URLQueryItem(name: X_AMZ_DATE, value: date.fullDateTimestamp))
        queryParamsBuilder.append(URLQueryItem(name: X_AMZ_EXPIRES, value: "299"))
        queryParamsBuilder.append(URLQueryItem(name: X_AMZ_SIGNED_HEADERS, value: signedHeaders))
        
        var queryParamsBuilderDict: [String: String] = [
            X_AMZ_ALGORITHM: ALGORITHM_AWS4_HMAC_SHA_256,
            X_AMZ_CREDENTIAL: (accessKey + "/" + credentialScope).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!,
            X_AMZ_DATE: date.fullDateTimestamp,
            X_AMZ_EXPIRES: "299",
            X_AMZ_SIGNED_HEADERS: signedHeaders,
        ]
        
        if !sessionToken.isEmpty {
            queryParamsBuilder.append(URLQueryItem(name: X_AMZ_SECURITY_TOKEN, value: sessionToken.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!.replacingOccurrences(of: "+", with: "%2B").replacingOccurrences(of: "=", with: "%3D")))
            queryParamsBuilderDict.updateValue(sessionToken.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!.replacingOccurrences(of: "+", with: "%2B").replacingOccurrences(of: "=", with: "%3D"), forKey: X_AMZ_SECURITY_TOKEN)
        }
        
        if signRequest.query != nil {
            let queryParams = signRequest.query!
            let queryParamArray = queryParams.components(separatedBy: "&")
            
            for s in queryParamArray {
                if let index = s.firstIndex(of: "=") {
                    let nextIndex = s.index(after: index)
                    queryParamsBuilderDict.updateValue(String(s[nextIndex...]).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!, forKey: String(s[..<index]))
                    queryParamsBuilder.append(URLQueryItem(name: String(s[..<index].addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!), value: String(s[nextIndex...])))
                }
            }
        } else {
            print("Error: Missing channel ARN.")
        }
        
        let sortedKeys = queryParamsBuilderDict.keys.sorted()
        var canonicalQuerystring: String = ""
        
        for key in sortedKeys {
            canonicalQuerystring += key + "=" + queryParamsBuilderDict[key]! + "&"
        }
        
        let cleanedcanonicalQuerystring = String(canonicalQuerystring.dropLast())
        let emptyString = ""
        let payloadHash = emptyString.sha256()
        let canonicalRequest =
            REST_METHOD + NEW_LINE_DELIMITER +
                canonicalUri + NEW_LINE_DELIMITER +
                cleanedcanonicalQuerystring + NEW_LINE_DELIMITER +
                canonicalHeaders + NEW_LINE_DELIMITER +
                signedHeaders + NEW_LINE_DELIMITER + payloadHash
        
        let stringToSign = ALGORITHM_AWS4_HMAC_SHA_256 + NEW_LINE_DELIMITER +
            date.fullDateTimestamp + NEW_LINE_DELIMITER +
            credentialScope + NEW_LINE_DELIMITER +
            canonicalRequest.sha256()
        
        let signature = signatureWith(stringToSign: stringToSign, secretAccessKey: secretKey, shortDateString: date.shortDate, awsRegion: region, serviceType: AWS_SERVICE)
                
        var components = URLComponents()
        components.scheme = "wss"
        components.host = wssRequest.host
        components.path = canonicalUri
        queryParamsBuilder.sort {
            $0.name < $1.name
        }
        queryParamsBuilder.append(URLQueryItem(name: X_AMZ_SIGNATURE, value: signature!))
        
        if #available(iOS 11.0, *) {
            components.percentEncodedQueryItems = queryParamsBuilder
        } else {
            // Fallback on earlier versions
            // No fallback for now, because we do not intend to support less than iOS 11.0
        }
        print("Signed url", components.url!)
        return components.url
    }
}


