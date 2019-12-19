import UIKit
import AWSCognitoIdentityProvider
import AWSMobileClient

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var signInViewController: SignInViewController?
    var channelConfigViewController: ChannelConfigurationViewController?
    var navigationController: UINavigationController?
    var storyboard: UIStoryboard?
    var rememberDeviceCompletionSource: AWSTaskCompletionSource<NSNumber>?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        // Warn user if configuration not updated
        if (cognitoIdentityUserPoolId == "REPLACEME") {
            let alertController = UIAlertController(title: "Invalid Configuration",
                                                    message: "Please configure user pool constants in Constants.swift and in the awsconfiguration.json file.",
                                                    preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(okAction)

            self.window?.rootViewController!.present(alertController, animated: true, completion: nil)
        }
        // setup logging
        AWSDDLog.sharedInstance.logLevel = .verbose

        // setup service configuration
        let serviceConfiguration = AWSServiceConfiguration(region: cognitoIdentityUserPoolRegion, credentialsProvider: nil)

        // create pool configuration
        let poolConfiguration = AWSCognitoIdentityUserPoolConfiguration(clientId: cognitoIdentityUserPoolAppClientId,
                                                                        clientSecret: cognitoIdentityUserPoolAppClientSecret,
                                                                        poolId: cognitoIdentityUserPoolId)

        // initialize user pool client
        AWSCognitoIdentityUserPool.register(with: serviceConfiguration, userPoolConfiguration: poolConfiguration, forKey: awsCognitoUserPoolsSignInProviderKey)

        AWSMobileClient.default().initialize { (userState, error) in
            if let error = error {
                print("error: \(error.localizedDescription)")

                return
            }

            guard let userState = userState else {
                return
            }
            print("The user is \(userState.rawValue).")
            self.storyboard = UIStoryboard(name: "Main", bundle: nil)

            switch userState {
            case .signedIn:
                self.navigationController = self.storyboard?.instantiateViewController(withIdentifier: "channelConfig") as? UINavigationController
                self.channelConfigViewController = self.navigationController?.viewControllers[0] as? ChannelConfigurationViewController
                DispatchQueue.main.async {
                    self.navigationController!.popToRootViewController(animated: true)
                    if (!self.navigationController!.isViewLoaded
                        || self.navigationController!.view.window == nil) {
                        self.window?.rootViewController?.present(self.navigationController!,
                                                                 animated: true,
                                                                 completion: nil)
                    }
                }
                break
            default:
                self.navigationController = self.storyboard?.instantiateViewController(withIdentifier: "signinController") as? UINavigationController
                self.signInViewController = self.navigationController?.viewControllers[0] as? SignInViewController
                DispatchQueue.main.async {
                    self.navigationController!.popToRootViewController(animated: true)
                    if (!self.navigationController!.isViewLoaded
                        || self.navigationController!.view.window == nil) {
                        self.window?.rootViewController?.present(self.navigationController!,
                                                                 animated: true,
                                                                 completion: nil)
                    }
                }
            }
        }
        return true
    }

    var orientationLock = UIInterfaceOrientationMask.all

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.orientationLock
    }
    struct AppUtility {
        static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
            if let delegate = UIApplication.shared.delegate as? AppDelegate {
                delegate.orientationLock = orientation
            }
        }

        static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation: UIInterfaceOrientation) {
            self.lockOrientation(orientation)
            UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
        }
    }
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state.
        // This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message)
        // or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers,
        // and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:
    }

}
