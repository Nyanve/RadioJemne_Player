//
//  CoreDataManager.swift
//  RadioJemne
//
//  Created by Samuel Brezoňák on 06/02/2024.
//

import Foundation
import CoreData

class CoreDataManager {
    
    static let shared = CoreDataManager()
       
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "RadioJemne")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
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
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    func saveSongsIntoCoreData(_ songs: [Song]) {
        print("saving data")
        let context = CoreDataManager.shared.persistentContainer.newBackgroundContext()
        context.performAndWait {
            deleteAllSongs(context: context)
            
            for songData in songs {
                let songObject = SongHistory(context: context)
                songObject.songArtist = songData.artist
                songObject.songTitle = songData.title
                songObject.date = songData.date
            }
            
            do {
                try context.save()
                print("Songs inserted into Core Data successfully.", songs )
            } catch {
                print("Error saving songs to Core Data: \(error)")
            }
        }
    }
    
    func deleteAllSongs(context: NSManagedObjectContext) {
        print("deleting ")
        context.performAndWait {
            do {
                let fetchRequest = SongHistory.fetchRequest()
                let songs = try context.fetch(fetchRequest)
                
                for song in songs {
                    context.delete(song)
                }
            } catch {
                debugPrint("delete", error)
            }
        }
    }
}
