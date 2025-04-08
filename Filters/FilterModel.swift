import Foundation

struct FilterModel: Decodable {
    let name: String
    let category: String
    let settings: FilterSettings?
}

struct FilterSettings: Decodable {
    let brightness: Double
    let contrast: Double
    let saturation: Double
}
