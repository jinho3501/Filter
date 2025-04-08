import Foundation

class FilterManager {
    static func loadFilters() -> [FilterModel] {
        guard let url = Bundle.main.url(forResource: "filters", withExtension: "json") else {
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let filters = try JSONDecoder().decode([FilterModel].self, from: data)
            return filters
        } catch {
            return []
        }
    }
}
