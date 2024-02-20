//
//  NewsViewController.swift
//  RadioJemne
//
//  Created by Samuel Brezoňák on 16/02/2024.
//

import UIKit
import CoreData
import SDWebImage


class NewsViewController: UIViewController {
    
    @IBOutlet weak var newsTableView: UITableView!
    
    let networkManager = NetworkManager()
    var viewContext = CoreDataManager.shared.persistentContainer.viewContext
    
    lazy var fetchedResultsController: NSFetchedResultsController<NewsList> = {
        let fetchRequest: NSFetchRequest<NewsList> = NewsList.fetchRequest()

        let dateSort = NSSortDescriptor(key: #keyPath(NewsList.datePublished), ascending: false)
        fetchRequest.sortDescriptors = [dateSort]

        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: viewContext, sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultsController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getNewsShowIt()
        
        newsTableView.delegate = self
        newsTableView.dataSource = self
    
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            debugPrint("fetch", error)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    private func getNewsShowIt() {
        Task {
            do {
                let news = try await networkManager.getNews()
                CoreDataManager.shared.saveNewsIntoCoreData(news)
                
            } catch {
                debugPrint("Load news articles error", error)
            }
        }
    }
}

extension NewsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let article = fetchedResultsController.object(at: indexPath)
        let url: String! = article.newsUrl
        showWebViewController(with: url)
    }

    func showWebViewController(with url: String) {
        guard let webVC = storyboard?.instantiateViewController(withIdentifier: "WebViewController") as? WebViewController else {
            return
        }
        webVC.urlString = url
        navigationController?.pushViewController(webVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewsTableViewCell", for: indexPath) as! NewsTableViewCell
        let article = fetchedResultsController.object(at: indexPath)
        configure(cell: cell, with: article, indexPath: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
    
    private func configure(cell: NewsTableViewCell, with article: NewsList, indexPath: IndexPath) {
        cell.titleLabel.text = article.newsTitle
        cell.summaryLabel.text = article.newsSummary
        cell.dateLabel.text = article.datePublished?.formatted(date: .numeric, time: .omitted)
        cell.thumbnail.sd_setImage(with: URL(string: article.thumbnailUrl! ), placeholderImage: UIImage(resource: .placeholderImg))
    }
}

extension NewsViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        newsTableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            newsTableView.insertRows(at: [newIndexPath!], with: .automatic)
            
        case .delete:
            newsTableView.deleteRows(at: [indexPath!], with: .automatic)
            
        case .update:
            let cell = newsTableView.cellForRow(at: indexPath!) as! NewsTableViewCell
            let article = fetchedResultsController.object(at: newIndexPath!)
            configure(cell: cell, with: article, indexPath: newIndexPath!)
            
        case .move:
            newsTableView.deleteRows(at: [indexPath!], with: .automatic)
            newsTableView.insertRows(at: [newIndexPath!], with: .automatic)
            
        @unknown default:
            debugPrint("Unexpected NSFetchedResultsChangeType")
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        newsTableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let indexSet = IndexSet(integer: sectionIndex)
        
        switch type {
        case .insert:
            newsTableView.insertSections(indexSet, with: .automatic)
        case .delete:
            newsTableView.deleteSections(indexSet, with: .automatic)
        default:
            break
        }
    }
}
