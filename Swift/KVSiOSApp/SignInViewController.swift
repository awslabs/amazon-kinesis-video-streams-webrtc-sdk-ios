import Foundation
import AWSCognitoIdentityProvider
import AWSKinesisVideo
import AWSMobileClient

class SignInViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    
    var passwordAuthenticationCompletion: AWSTaskCompletionSource<AWSCognitoIdentityPasswordAuthenticationDetails>?
    var usernameText: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.username.delegate = self
        self.password.delegate = self
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.password.text = nil
        self.username.text = usernameText
    }
    override func viewDidAppear(_ animated: Bool) {
        NSLog("SignIn : viewDidAppear")
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }

    @IBAction func signInPressed(_ sender: AnyObject) {
        if let username = self.username.text, let password = self.password.text {
            AWSMobileClient.default().signIn(username: username, password: password) { (signInResult, error) in

                DispatchQueue.main.async {
                    if let error = error {
                        self.showError(error: error)
                    } else if let signInResult = signInResult {
                        switch (signInResult.signInState) {
                        case .signedIn:
                            self.showSignInError(signInResult: signInResult)
                        default:
                            self.showSignInError(signInResult: signInResult)
                        }
                    }
                }
            }
        }
    }

    func showError(error: Error) {
        let alertController = UIAlertController(title: "Login Error", message: "There was an error with your login: " + error.localizedDescription, preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))

        self.present(alertController, animated: true, completion: nil)
    }

    func showSignInError(signInResult: SignInResult) {
        switch (signInResult.signInState) {
        case .signedIn:
            self.dismiss(animated: true, completion: nil)
        default:
            let alertController = UIAlertController(title: "Login Error", message: "There was an error with your login, please contact user support", preferredStyle: .alert)

            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))

            self.present(alertController, animated: true, completion: nil)
        }
    }
}
