import Foundation

final class FileCache {
    private(set) var items = [String: ToDoItem]()
    
    func add(item: ToDoItem) {
        items[item.id] = item
    }
    
    @discardableResult
    func remove(id: String) -> ToDoItem? {
        let deleted = items[id]
        items[id] = nil
        return deleted
    }
    
    //json
    func saveJson(toFileWithID file: String) throws {
        let arrayItems = items.map { $0.value }
        try saveItemsJson(items: arrayItems, to: file)
    }
    
    private func saveItemsJson(items: [ToDoItem], to file: String) throws {
        let fileManager = FileManager.default
        guard let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw FileCacheErrors.noSuchSystemDirectory
        }
        
        let path = directory.appendingPathComponent("\(file).json")
        let itemsJson = items.map { $0.json }
        let data = try JSONSerialization.data(withJSONObject: itemsJson, options: [])
        try data.write(to: path, options: .atomic)
    }
    
    func loadJson(from file: String) throws {
        self.items = try loadItemsJson(from: file).reduce(into: [:]) { result, item in
            result[item.id] = item
        }
    }
    
    private func loadItemsJson(from file: String) throws -> [ToDoItem] {
        let fileManager = FileManager.default
        guard let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw FileCacheErrors.noSuchSystemDirectory
        }
        
        let path = directory.appendingPathComponent("\(file).json")
        let data = try Data(contentsOf: path)
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        guard let json = json as? [Any] else {
            throw FileCacheErrors.unparsableData
        }
        let todoItems = json.compactMap { ToDoItem.parse(json: $0) }
        return todoItems
    }
}

enum FileCacheErrors: Error {
    case noSuchSystemDirectory
    case unparsableData
    case UTF8FormatError
}

extension FileCacheErrors: CustomStringConvertible {
    var description: String {
        switch self {
        case .noSuchSystemDirectory:
            return "Указанная системная дирректория отсутсвует"
        case .unparsableData:
            return "Невозможно распарсить данные"
        case .UTF8FormatError:
            return "Ошибка форматирования UTF-8"
        }
    }
}
