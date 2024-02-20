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
        
        let container = NSPersistentContainer(name: "RadioJemne")
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    func saveSongsIntoCoreData(_ songs: [Song]) {
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
                debugPrint("Songs inserted into Core Data successfully.")
            } catch {
                debugPrint("Error saving songs to Core Data: \(error)")
            }
        }
    }
    
    func deleteAllSongs(context: NSManagedObjectContext) {
        context.performAndWait {
            do {
                let fetchRequest = SongHistory.fetchRequest()
                let songs = try context.fetch(fetchRequest)
                
                for song in songs {
                    context.delete(song)
                }
            } catch {
                debugPrint("Deleting failed", error)
            }
        }
    }
    
    func saveNewsIntoCoreData(_ news: [News]) {
        let context = CoreDataManager.shared.persistentContainer.newBackgroundContext()
        context.performAndWait {
            deleteAllNews(context: context)
            
            for newsData in news {
                let newsObject = NewsList(context: context)
                newsObject.newsTitle = newsData.title
                newsObject.newsSummary = newsData.summary
                newsObject.newsUrl = newsData.url
                newsObject.thumbnailUrl = newsData.thumbnailURL
                newsObject.datePublished = newsData.datePublished
            }
            
            do {
                try context.save()
                debugPrint("News inserted into Core Data successfully.")
            } catch {
                debugPrint("Error saving songs to Core Data: \(error)")
            }
        }
    }
    
    func deleteAllNews(context: NSManagedObjectContext) {
        context.performAndWait {
            do {
                let fetchRequest = NewsList.fetchRequest()
                let songs = try context.fetch(fetchRequest)
                
                for song in songs {
                    context.delete(song)
                }
            } catch {
                debugPrint("Deleting failed", error)
            }
        }
    }
}
