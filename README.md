<div align="center">

<h1>Amazon Kinesis Video iOS WebRTC Sample</h1>

[![Build Status](https://img.shields.io/github/actions/workflow/status/awslabs/amazon-kinesis-video-streams-webrtc-sdk-ios/ci.yml)](https://img.shields.io/github/actions/workflow/status/awslabs/amazon-kinesis-video-streams-webrtc-sdk-ios/ci.yml)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

[//]: # (Todo: re-enable this once code cov is setup)
[//]: # (&#40;[![Coverage Status]&#40;https://codecov.io/gh/awslabs/amazon-kinesis-video-streams-webrtc-sdk-ios/branch/master/graph/badge.svg&#41;]&#40;https://codecov.io/gh/awslabs/amazon-kinesis-video-streams-webrtc-sdk-ios&#41;&#41;)

</div>

This sample demonstrates the Amazon Kinesis Video Streams and Kinesis Video Signaling framework found in the [AWS Mobile SDK for iOS](https://github.com/aws-amplify/aws-sdk-ios) with [Google WebRTC](https://webrtc.github.io/webrtc-org/native-code/ios/).

For more information, see [What Is Amazon Kinesis Video Streams with WebRTC](https://docs.aws.amazon.com/kinesisvideostreams-webrtc-dg/latest/devguide/what-is-kvswebrtc.html) and [WebRTC SDK for iOS](https://docs.aws.amazon.com/kinesisvideostreams-webrtc-dg/latest/devguide/kvswebrtc-sdk-ios.html). You can learn more about Google WebRTC's native API's [here](https://webrtc.github.io/webrtc-org/native-code/native-apis/).

## Requirements

* See [ci.yml](.github/workflows/ci.yml) for supported iOS and XCode versions.

#### Download the WebRTC SDK in iOS
To download the WebRTC SDK in iOS, run the following command:

```bash
git clone https://github.com/awslabs/amazon-kinesis-video-streams-webrtc-sdk-ios.git
```

#### Using XCode to build the project

0. Install XCode. You can install XCode from https://developer.apple.com/download/all/

1. The [AWS Mobile SDK for iOS](https://github.com/aws-amplify/aws-sdk-ios) is available through [CocoaPods](http://cocoapods.org). If CocoaPods is not installed, install it using the following command. Note that Ruby will also be installed, as it is a dependency of Cocoapods.
   ```bash
   brew install cocoapods
   pod setup
   ```

2. The following cocoa pod dependencies are included in the [Podfile](Swift/Podfile) and need to be `pod install`'ed:

   * Starscream
   * Common Crytpo
   * WebRTC.framework: this is the GoogleWebRTC module framework package (bit code disabled).
   * AWSMobileClient
   * AWSCognito
   * AWSKinesisVideo
   * AWSKinesisVideoSignaling

   Change directories to the directory containing the [Podfile](Swift/Podfile) and run the `install` command:
   ```bash
   cd amazon-kinesis-video-streams-webrtc-sdk-ios/Swift
   pod cache clean --all
   pod install --repo-update
   ```

3. Create an [Amazon Cognito User Pool](https://docs.aws.amazon.com/cognito/latest/developerguide/what-is-amazon-cognito.html). Follow steps 2-3 in the [AWS KVS Android WebRTC Repo](https://github.com/awslabs/amazon-kinesis-video-streams-webrtc-sdk-android).

4. To open the project, you can choose between these two methods:

   1. Open XCode, select "Open a project or file", and choose [AWSKinesisVideoWebRTCDemoApp.**xcworkspace**](Swift/AWSKinesisVideoWebRTCDemoApp.xcworkspace), **OR**
   2. Run the following command from the [Swift](Swift) folder.
    ```bash
    xed .
    ```

5. Open [KvsiOSApp/Constants.swift](Swift/KVSiOSApp/Constants.swift). Set `CognitoIdentityUserPoolRegion`, `CognitoIdentityUserPoolId`, `CognitoIdentityUserPoolAppClientId`, `CognitoIdentityUserPoolAppClientSecret` and `CognitoIdentityPoolId` to the values obtained in step 3.

   <details>
       <summary><strong>Example Constants.swift</strong></summary>

      ```swift
      let cognitoIdentityUserPoolRegion = AWSRegionType.USWest2
      let cognitoIdentityUserPoolId = "us-west-2_qRsTuVwXy"
      let cognitoIdentityUserPoolAppClientId = "0123456789abcdefghijklmnop"
      let cognitoIdentityUserPoolAppClientSecret = "abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmno"
      let cognitoIdentityPoolId = "us-west-2:01234567-89ab-cdef-0123-456789abcdef"
      ```

   </details>

   Open [KvsiOSApp/awsconfiguration.json](Swift/KVSiOSApp/awsconfiguration.json) and replace the "REPLACEME" values with the values obtained earlier.

   <details>
       <summary><strong>Example awsconfiguration.json</strong></summary>

   ```json
   {
     "Version": "1.0",
     "CredentialsProvider": {
       "CognitoIdentity": {
         "Default": {
           "PoolId": "us-west-2:01234567-89ab-cdef-0123-456789abcdef",
           "Region": "us-west-2"
         }
       }
     },
     "IdentityManager": {
       "Default": {}
     },
     "CognitoUserPool": {
       "Default": {
         "AppClientSecret": "abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmno",
         "AppClientId": "0123456789abcdefghijklmnop",
         "PoolId": "us-west-2_qRsTuVwXy",
         "Region": "us-west-2"
       }
     }
   }
   ```

   </details>

6. To build and run, click the play button at the top of the XCode UI.

#### Run the iOS Sample Application
Building the iOS sample application installs the AWSKinesisVideoWebRTCDemoApp on your iOS device. Using this app, you can verify live audio/video streaming between mobile, web and IoT device clients (camera). The procedure below describes some of these scenarios.

Complete the following steps:

1.    On your iOS device, open AWSKinesisVideoWebRTCDemoApp and login using the AWS user credentials from Set Up an AWS Account and Create an Administrator. (Note: Cognito settings can be tuned through your Cognito User Pool in the AWS management Console)
2.    On successful sign-in, the channel configuration view is displayed where the **channel-name, client-id (optional) and region-name** have to be configured.

#### Run the Integration Tests
1.   To run the integration tests, the test user has to be created with the appropriate test password as in the [AWSKinesisVideoWebRTCDemoAppUITests/TestConstants.swift](Swift/AWSKinesisVideoWebRTCDemoAppUITests/TestConstants.swift) file.


##### Note
*    Ensure that in all the cases described below, both the client applications use the same signaling channel name, region, viewer-id/client-id and the AWS account id.
*    Please note that a master should be started first before the viewer connects to it.

#####    Peer to Peer Streaming between two iOS devices: master and viewer:
*    Start one iOS device in master mode for starting a new session using a channel name (e.g. demo). Remote peer will be joining as viewer to this master.
*    Currently, there can be only one master for a channel at any given time.
*    Use another iOS device to connect to the same channel name (started up in the above step set up as a master) in viewer mode. This will connect to an existing session (channel) where a master was connected previously.

#####    Peer to Peer Streaming between [Embedded SDK](https://github.com/awslabs/amazon-kinesis-video-streams-webrtc-sdk-c) master and iOS device:
*    Run KVS WebRTC embedded SDK (in C) in master mode on a camera device.
*    Start the iOS device in viewer mode – you should be able to see the local video preview in the lower right side of the screen and also the larger part of the screen should stream the remote video view.

#####    Peer to Peer Streaming between iOS device as master and Web browser as viewer:
*    Start one iOS device in master mode for starting a new session using a channel name (e.g. demo)
*    Start the Web Browser using the Javascript SDK (JS with audio selected) and start it as viewer.
*    Verify media showing up from the iOS device and also from the browser.

##### Note

* _This sample application has been tested in Simulator (iPhone 16e) and iPhone SE 2nd Generation._


#### Using user-provided AWS credentials directly instead of Cognito integration

> [!IMPORTANT]
> This is not recommended for production use.

In the `Constants.swift`, set variables `awsAccessKey` and `awsSecretKey` (optional: `awsSessionToken`) with your values.
In this mode, your `awsconfiguration.json` does not need to be modified, and neither do the `REPLACEME` values
in the `Constants.swift`.

Those user-provided credentials will be used to interact with KVS APIs instead of using credentials fetched from AWS Cognito Service.

## Troubleshooting

<details>
  <summary><code>Scripting Bridge could not launch application /Applications/Xcode.app</code></summary>

Check that `XCode.app` is in your `Applications` folder.

</details>

<br>

<details>
  <summary><code>No such module 'AWSCognitoIdentityProvider'</code></summary>

Open the project by selecting the `.xcworkspace` file or using the `xed .` command, not the `.xcodeproj` file.

</details>

<br>

<details>
  <summary><code>Could not build module 'UIKit'</code></summary>

Try reinstalling XCode, restarting your MAC, and reinstalling the Pods. Run the following commands from the same directory containing the [Podfile](Swift).

   ```
   rm -rf ~/Library/Caches/CocoaPods
   rm -rf Pods
   rm -rf ~/Library/Developer/Xcode/DerivedData
   pod deintegrate
   rm -f Podfile.lock
   pod setup
   pod install --repo-update
   ```

Then, run a clean build in XCode by going to `Product > Clean Build Folder` (or using ⌘+⇧+K) before clicking the play button.

</details>

<br>

<details>
  <summary><code>Could not find module 'AWSMobileClient' for target 'arm64-apple-ios-simulator'; found: x86_64-apple-ios-simulator</code></summary>

Open Build settings.
* In XCode, switch to the file viewer, scroll down and double-click on the Pods with the XCode symbol next to it. At the top, switch the tab to `Build settings`, and check that `All` and `Combined` are selected.

In the `Architectures > Architectures` setting, add `x86_64`.

Alternatively, you can try enabling Rosetta: `Finder > Applications > XCode > Get Info > ✓ Enable Rosetta`

</details>

<br>

<details>
  <summary><code>Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'Invalid region type.'</code></summary>

Double check that [Constants.swift](Swift/KVSiOSApp/Constants.swift) contains a valid region. See [AWSRegionType](https://aws-amplify.github.io/aws-sdk-ios/docs/reference/AWSCore/Enums/AWSRegionType.html) for more info.

</details>

<br>

<details>
  <summary><code><strong>Unable to create channel</strong>. Please validate all the input fields</code></summary>

Check that the values in `Constants.swift` and  `awsconfiguration.json` are set correctly. See the examples above to ensure your values match the same format.
Additionally, check that the IAM role has the appropriate `kinesisvideo` permissions.

</details>

## License
This library is licensed under the [Apache 2.0 License](https://github.com/awslabs/amazon-kinesis-video-streams-webrtc-sdk-ios/blob/master/LICENSE).
