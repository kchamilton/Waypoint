import Foundation
import UIKit

final class MapCoordinator: BaseCoordinator{
    weak var navigationController: UINavigationController?
    weak var delegate: MapToAppCoordinatorDelegate?
    
    override func start() {
        super.start()
        let storyboard = UIStoryboard(name: "Map", bundle: nil)
        if let container = storyboard.instantiateViewController(withIdentifier: "MapViewController") as? MapViewController {
            container.coordinatorDelegate = self
            navigationController?.pushViewController(container, animated: false)
        }
    }
    
    init(navigationController: UINavigationController?) {
        super.init()
        self.navigationController = navigationController
    }
}

protocol MapCoordinatorDelegate {
    func navigateToFlutter()
}

extension MapCoordinator: MapCoordinatorDelegate{
    func navigateToFlutter(){
        self.delegate?.navigateToFlutterViewController()
    }
}