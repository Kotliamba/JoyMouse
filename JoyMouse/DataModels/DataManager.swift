//
//  DataManager.swift
//  JoyMouse
//
//  Created by magicien on 2019/07/14.
//  Copyright © 2019 DarkHorse. All rights reserved.
//

import CoreData
import JoyConSwift
import AppKit

enum StickType: String {
    case Mouse = "Mouse"
    case MouseWheel = "Mouse Wheel"
    case Key = "Key"
    case None = "None"
}

enum StickDirection: String {
    case Left = "Left"
    case Right = "Right"
    case Up = "Up"
    case Down = "Down"
}

class DataManager: NSObject {
    let container: NSPersistentContainer

    var undoManager: UndoManager? {
        return self.container.viewContext.undoManager
    }
    
    var controllers: [ControllerData] {
        let context = self.container.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ControllerData")
        
        do {
            let result = try context.fetch(request) as! [ControllerData]
            return result
        } catch {
            fatalError("Failed to fetch ControllerData: \(error)")
        }
    }
    
    init(completion: @escaping (DataManager?) -> Void) {
        self.container = NSPersistentContainer(name: "JoyMouse")
        super.init()
        
        self.container.loadPersistentStores { [weak self] (storeDescription, error) in
            if let error = error {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error)")
            }
            self?.container.viewContext.automaticallyMergesChangesFromParent = true
            self?.container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            
            completion(self)
        }
    }
    
    func save() -> Bool {
        let context = self.container.viewContext
         
        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
            return false
        }
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Customize this code block to include application-specific recovery steps.
                let nserror = error as NSError
                NSApplication.shared.presentError(nserror)

                return false
            }
        }
        
        return true
    }
    
    // MARK: - Import/Export data
    
    func createContext(for url: URL) -> NSManagedObjectContext? {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.container.managedObjectModel)
        do {
            // TODO: Set options
            try coordinator.addPersistentStore(ofType: NSBinaryStoreType, configurationName: nil, at: url, options: nil)
        } catch {
            let nserror = error as NSError
            NSApplication.shared.presentError(nserror)

            return nil
        }

        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        
        return context
    }
    
    func saveData(object: NSManagedObject, to url: URL) -> Bool {
        guard let context = self.createContext(for: url) else { return false }
        
        context.insert(object)
        if !context.commitEditing() {
            return false
        }
        
        do {
            try context.save()
        } catch {
            // Customize this code block to include application-specific recovery steps.
            let nserror = error as NSError
            NSApplication.shared.presentError(nserror)

            return false
        }
        
        return true
    }
    
    func loadData<T: NSManagedObject>(from url: URL) -> [T]? {
        guard let context = self.createContext(for: url) else { return nil }
        guard let entityName = T.entity().name else { return nil }
        
        let request = NSFetchRequest<T>(entityName: entityName)
        do {
            return try context.fetch(request)
        } catch {
            let nserror = error as NSError
            NSApplication.shared.presentError(nserror)
        }

        return nil
    }

    private func makeObject<T: NSManagedObject>(_ type: T.Type, entityName: String, insertInto context: NSManagedObjectContext?) -> T {
        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: self.container.viewContext) else {
            fatalError("Failed to create entity description for \(entityName)")
        }

        return T(entity: entity, insertInto: context)
    }

    private func createTransientControllerData(type: JoyCon.ControllerType) -> ControllerData {
        let controller = self.makeObject(ControllerData.self, entityName: "ControllerData", insertInto: nil)
        controller.appConfigs = []
        controller.defaultConfig = self.createTransientKeyConfig(type: type)

        return controller
    }

    private func createTransientKeyConfig(type: JoyCon.ControllerType) -> KeyConfig {
        let keyConfig = self.makeObject(KeyConfig.self, entityName: "KeyConfig", insertInto: nil)

        if type == .JoyConL || type == .ProController {
            keyConfig.leftStick = self.createTransientStickConfig()
        }
        if type == .JoyConR || type == .ProController {
            keyConfig.rightStick = self.createTransientStickConfig()
        }

        keyConfig.keyMaps = []

        return keyConfig
    }

    private func createTransientKeyMap() -> KeyMap {
        self.makeObject(KeyMap.self, entityName: "KeyMap", insertInto: nil)
    }

    private func createTransientStickConfig() -> StickConfig {
        let stickConfig = self.makeObject(StickConfig.self, entityName: "StickConfig", insertInto: nil)

        stickConfig.speed = 10.0
        stickConfig.type = StickType.None.rawValue

        let left = self.createTransientKeyMap()
        left.button = StickDirection.Left.rawValue
        stickConfig.addToKeyMaps(left)

        let right = self.createTransientKeyMap()
        right.button = StickDirection.Right.rawValue
        stickConfig.addToKeyMaps(right)

        let up = self.createTransientKeyMap()
        up.button = StickDirection.Up.rawValue
        stickConfig.addToKeyMaps(up)

        let down = self.createTransientKeyMap()
        down.button = StickDirection.Down.rawValue
        stickConfig.addToKeyMaps(down)

        return stickConfig
    }

    // MARK: - ControllerData
    
    func createControllerData(type: JoyCon.ControllerType) -> ControllerData {
        let controller = self.makeObject(ControllerData.self, entityName: "ControllerData", insertInto: self.container.viewContext)
        controller.appConfigs = []
        controller.defaultConfig = self.createKeyConfig(type: type)
        
        return controller
    }
    
    func getControllerData(controller: JoyConSwift.Controller) -> ControllerData {
        let serialID = controller.serialID
        if serialID.isEmpty {
            return self.createTransientControllerData(type: controller.type)
        }

        let context = self.container.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ControllerData")
        request.predicate = NSPredicate(format: "serialID == %@", serialID)

        do {
            let result = try context.fetch(request) as! [ControllerData]
            if result.count > 0 {
                return result[0]
            }
        } catch {
            fatalError("Failed to fetch ControllerData: \(error)")
        }

        let controller = self.createControllerData(type: controller.type)
        controller.serialID = serialID
        
        return controller
    }
    
    // MARK: - AppConfig
    
    func createAppConfig(type: JoyCon.ControllerType) -> AppConfig {
        let appConfig = self.makeObject(AppConfig.self, entityName: "AppConfig", insertInto: self.container.viewContext)
        appConfig.app = self.createAppData()
        appConfig.config = self.createKeyConfig(type: type)

        return appConfig
    }

    // MARK: - AppData

    func createAppData() -> AppData {
        let appData = self.makeObject(AppData.self, entityName: "AppData", insertInto: self.container.viewContext)

        return appData
    }

    // MARK: - KeyConfig

    func createKeyConfig(type: JoyCon.ControllerType) -> KeyConfig {
        let keyConfig = self.makeObject(KeyConfig.self, entityName: "KeyConfig", insertInto: self.container.viewContext)
        
        if type == .JoyConL || type == .ProController {
            keyConfig.leftStick = self.createStickConfig()
        }
        if type == .JoyConR || type == .ProController {
            keyConfig.rightStick = self.createStickConfig()
        }
        
        keyConfig.keyMaps = []
        
        return keyConfig
    }

    // MARK: - KeyMap

    func createKeyMap() -> KeyMap {
        let keyMap = self.makeObject(KeyMap.self, entityName: "KeyMap", insertInto: self.container.viewContext)
        
        return keyMap
    }
    
    // MARK: - StickConfig
    
    func createStickConfig() -> StickConfig {
        let stickConfig = self.makeObject(StickConfig.self, entityName: "StickConfig", insertInto: self.container.viewContext)

        stickConfig.speed = 10.0
        stickConfig.type = StickType.None.rawValue

        let left = self.createKeyMap()
        left.button = StickDirection.Left.rawValue
        stickConfig.addToKeyMaps(left)

        let right = self.createKeyMap()
        right.button = StickDirection.Right.rawValue
        stickConfig.addToKeyMaps(right)

        let up = self.createKeyMap()
        up.button = StickDirection.Up.rawValue
        stickConfig.addToKeyMaps(up)

        let down = self.createKeyMap()
        down.button = StickDirection.Down.rawValue
        stickConfig.addToKeyMaps(down)
        
        return stickConfig
    }
    
    // MARK: - Common
    
    func delete(_ object: NSManagedObject) {
        object.managedObjectContext?.delete(object)
    }
}
