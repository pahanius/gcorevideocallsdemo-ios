
import UIKit

struct Avatars {
    static var randomImage: UIImage? {
        let imageName = [
            "icons8-batman",
            "icons8-cheburashka",
            "icons8-futurama-bender",
            "icons8-futurama-fry",
            "icons8-homer-simpson",
            "icons8-house-stark",
            "icons8-predator",
            "icons8-rick-sanchez",
            "icons8-stormtrooper"
        ].randomElement()
        
        return UIImage(named: imageName!)
    }
    
    static var name: String {
        [
            "Набира",
            "Тугарин",
            "Апо",
            "Пико",
            "Брутто",
            "Рембо",
            "Удача",
            "Отлет",
            "Вака"
        ].randomElement()!
    }
}
