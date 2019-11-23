## CommonCrypto, wrapped in module

It is currently impossible to import CommonCrypto headers from Swift because they aren't modular. You can find several solutions to this issue on [StackOverflow](http://stackoverflow.com/a/29189873/1607485), however they require some effort to implement. 

This repo's goal is to provide a modular wrapper to the CommonCrypto, so that it can be imported to Swift without any additional work.

### Example

```swift
import CommonCryptoModule

extension Data {

    public func md5() -> Data {
        var result = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        _ = result.withUnsafeMutableBytes { resultBytes in
            self.withUnsafeBytes { originBytes in
                CC_MD5(originBytes, CC_LONG(count), resultBytes)
            }
        }
        return result
    }
}
```

### Installation

Intallable manually or via Cocoapods:

```ruby
pod 'CommonCryptoModule', '~> 1.0.1'

```
