import UIKit

class LoginViewController: UIViewController {
//    @IBOutlet weak var userLoginButton: UIButton!
//    @IBOutlet weak var adminLoginButton: UIButton!
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

