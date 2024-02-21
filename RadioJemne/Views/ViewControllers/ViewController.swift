//
//  ViewController.swift
//  RadioJemne
//
//  Created by Samuel Brezoňák on 29/01/2024.
//

import UIKit
import MessageUI
import AVKit
import MediaPlayer
import CoreData

class ViewController: UIViewController {
    
    @IBOutlet var mainView: UIView!
    @IBOutlet weak var musicSlideView: UIStackView!
    @IBOutlet weak var cornerButtonsView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var musicViewBottomAnchor: NSLayoutConstraint!
    @IBOutlet weak var InfoSlidingViewTopAnchor: NSLayoutConstraint!
    @IBOutlet weak var cornerButtonsViewTopAnchor: NSLayoutConstraint!
    @IBOutlet weak var historyViewBottomAnchor: NSLayoutConstraint!
    @IBOutlet weak var closeHistoryButtonTopAnchor: NSLayoutConstraint!
    @IBOutlet weak var RJLogoTopAnchor: NSLayoutConstraint!
    
    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var volumeSlider: UISlider!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var closeHistoryButton: UIButton!
    
    private let mPhoneNumber = "1111111111"
    private var isPlayButtonOn: Bool = false
    private var isHistoryOn: Bool = false
    
    private let stream = StreamMusic()
    private let networkManager = NetworkManager()
    private var viewContext = CoreDataManager.shared.persistentContainer.viewContext
    private let swipeGesture = UISwipeGestureRecognizer()
    
    lazy var fetchedResultsController: NSFetchedResultsController<SongHistory> = {
        let fetchRequest: NSFetchRequest<SongHistory> = SongHistory.fetchRequest()

        let dateSort = NSSortDescriptor(key: #keyPath(SongHistory.date), ascending: false)
        fetchRequest.sortDescriptors = [dateSort]
        fetchRequest.fetchLimit = 7
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: viewContext, sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultsController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        swipeGesture.direction = .down
        swipeGesture.addTarget(self, action: #selector(swipeHappened(_:)))
        self.view.addGestureRecognizer(swipeGesture)
        
        stream.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        tableView.dataSource = self
    
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            debugPrint("Fetch", error)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    @IBAction func showHistoryButton(_ sender: Any) {
        updateAndLoadHistoryData()
        showHistoryView()
    }
    
    @IBAction func closeHistoryButton(_ sender: Any) {
        hideHistoryView()
    }

    @IBAction func shareButton(_ sender: Any) {
        shareLink()
    }
    
    @IBAction func CallButton(_ sender: Any) {
        callToRadio()
    }
    
    @IBAction func messageButton(_ sender: Any) {
        messageToRadio()
    }

    @IBAction func mailButton(_ sender: Any) {
        choseMailActionSheet()
    }
    
    @IBAction func infoButton(_ sender: Any) {
        swipeGesture.direction = .down
        animatedSwipe()
    }
    
    @IBAction func volumeSlider(_ slider: UISlider) {
        stream.player?.volume = slider.value
    }
    
    @IBAction func playPauseButton(_ sender: Any) {
        isPlayButtonOn.toggle()
        if isPlayButtonOn {
            stream.play()
            playPauseButton.setImage(UIImage(resource: .pauseIcon), for: .normal)
        } else {
            stream.pause()
            playPauseButton.setImage(UIImage(resource: .playIcon), for: .normal)
        }
    }
    
    @objc func applicationWillEnterForeground(_ application: UIApplication) {
        if !(stream.player?.rate != 0 && stream.player?.error == nil) {
            isPlayButtonOn.toggle()
            playPauseButton.setImage(UIImage(resource: .playIcon), for: .normal)
        }
    }
    
    @objc private func swipeHappened(_ swiperRecognizers: UISwipeGestureRecognizer) {
        if swiperRecognizers.state == .ended {
            animatedSwipe()
        }
    }
    
    private func updateAndLoadHistoryData() {
        Task {
            do {
                let songs = try await networkManager.getSongHistory()
                CoreDataManager.shared.saveSongsIntoCoreData(songs)
            } catch {
                debugPrint("Load playlist songs error", error)
            }
        }
    }

    private func shareLink() {
        guard let url = URL(string: "https://www.radiomelody.sk/stream/") else {
            basicError(message: "Nieje možné zdieľat stream. Prosím skúste neskôr")
            return
        }
        
        let items = [url]
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(activityViewController, animated: true)
    }
    
    private func showHistoryView() {
        isHistoryOn = true
        
        UIView.animate(withDuration: 0.3) {
            self.cornerButtonsView.alpha = 0
            self.cornerButtonsViewTopAnchor.constant = -70
            self.closeHistoryButtonTopAnchor.constant = 75
            self.closeHistoryButton.alpha = 1
            self.historyViewBottomAnchor.constant = 0
            self.RJLogoTopAnchor.constant = 40
            self.view.layoutIfNeeded()
        }
    }
    
    private func hideHistoryView() {
        isHistoryOn = false
        
        UIView.animate(withDuration: 0.3){
            self.cornerButtonsView.alpha = 1
            self.cornerButtonsViewTopAnchor.constant = 0
            self.closeHistoryButtonTopAnchor.constant = 170
            self.closeHistoryButton.alpha = 0
            self.historyViewBottomAnchor.constant = -600
            self.RJLogoTopAnchor.constant = 180
            self.view.layoutIfNeeded()
        }
    }
    
    private func animatedSwipe() {
        if !isHistoryOn {
            if swipeGesture.direction == .down {
                swipeGesture.direction = .up
                
                UIView.animate(withDuration: 0.22) {
                    self.cornerButtonsView.alpha = 0
                    self.cornerButtonsViewTopAnchor.constant = 70
                    self.musicViewBottomAnchor.constant = -112
                    self.InfoSlidingViewTopAnchor.constant = 0
                    self.view.layoutIfNeeded()
                }
            } else {
                swipeGesture.direction = .down
                
                UIView.animate(withDuration: 0.22){
                    self.cornerButtonsView.alpha = 1
                    self.cornerButtonsViewTopAnchor.constant = 0
                    self.musicViewBottomAnchor.constant = 54
                    self.InfoSlidingViewTopAnchor.constant = -170
                    self.view.layoutIfNeeded()
                }
            }
        }
    }
    
    private func callToRadio() {
        if let phoneCallURL = URL(string: "telprompt://\(mPhoneNumber)") {
            let application:UIApplication = UIApplication.shared
            guard application.canOpenURL(phoneCallURL) else {
                basicError(message: "Neieje možné spustit hovor. Prosím skúste neskôr")
                return
            }
            
            application.open(phoneCallURL, options: [:], completionHandler: nil)
        }
    }
    
    private func messageToRadio() {
        guard MFMessageComposeViewController.canSendText() else {
            basicError(message: "Nieje možné poslať správu. Prosím skúste neskôr")
            return
        }
        
        let controller = MFMessageComposeViewController()
        controller.body = ""
        controller.recipients = [mPhoneNumber]
        controller.messageComposeDelegate = self
        self.present(controller, animated: true, completion: nil)
    }
    
    private func sendEmail(address: String) {
        guard MFMailComposeViewController.canSendMail() else {
            basicError(message: "Nieje možné poslať e-mail. Prosím skúste neskôr")
            return
        }
        
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients([address])
            mail.setMessageBody("Ste užasný!", isHTML: true)
            present(mail, animated: true)
    }
    
    private func choseMailActionSheet() {
        let studio = "studio@radiomelody.sk"
        let radio = "radiomelody@radiomelody.sk"
        
        let alert = UIAlertController(title: "Zvoľte adresu", message: "Prosím zvoľte adresu prijímateľa", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: studio, style: .default, handler: { (_) in
            self.sendEmail(address: studio)
        }))
        alert.addAction(UIAlertAction(title: radio, style: .default, handler: { (_) in
            self.sendEmail(address: radio)
        }))
        alert.addAction(UIAlertAction(title: "Zrušit", style: .cancel, handler: { (_) in
        }))
    
        self.present(alert, animated: true, completion: {
        })
    }
    
    private func basicError(message: String) {
        let error = UIAlertController(title: "Naskytol sa error", message: message, preferredStyle: .alert)
        error.addAction(UIAlertAction(title: "Ok", style: .cancel))
        
        self.present(error, animated: true)
    }
}

extension ViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}

extension ViewController: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true)
    }
}

extension ViewController: StreamMusicDelegate {
    func playerFailed(_ streamMusic: StreamMusic) {
        isPlayButtonOn.toggle()
    
        let stringWithImage = NSMutableAttributedString(string: "Nebolo možné spustit prehrávač. Prosím skúste znova")
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = UIImage(resource: .varningIcon)
        let completeImageString = NSAttributedString(attachment: imageAttachment)
        
        stringWithImage.insert(completeImageString, at: 0)
        artistLabel.attributedText = stringWithImage
        songNameLabel.text = ""
        playPauseButton.setImage(UIImage(resource: .revindIcon), for: .normal)
    }
    
    func sendSongData(_ streamMusic: StreamMusic, songTitle: String, songArtist: String) {
        DispatchQueue.main.async {
            self.songNameLabel.text = songTitle
            self.artistLabel.text = songArtist
            self.updateAndLoadHistoryData()
        }
        return
    }
    
    func sendVolumeValue(_ streamMusic: StreamMusic, volumeChangedTo: Float) {
        volumeSlider.value = volumeChangedTo
        return
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SongTableViewCell", for: indexPath) as! SongTableViewCell
        let song = fetchedResultsController.object(at: indexPath)
        configure(cell: cell, with: song, indexPath: indexPath)
        return cell
    }
    
    private func configure(cell: SongTableViewCell, with song: SongHistory, indexPath: IndexPath) {
        cell.songNameLabel.text = song.songTitle
        cell.authorLabel.text = song.songArtist
        if indexPath.row == 0 {
            cell.nowPlayingImage.isHidden = false
            cell.songNameLabelLeadingConstraint.constant = 50
        } else {
            cell.nowPlayingImage.isHidden = true
        }
    }
}

extension ViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
            
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
            
        case .update:
            let cell = tableView.cellForRow(at: indexPath!) as! SongTableViewCell
            let song = fetchedResultsController.object(at: newIndexPath!)
            configure(cell: cell, with: song, indexPath: newIndexPath!)
            
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
            
        @unknown default:
            debugPrint("Unexpected NSFetchedResultsChangeType")
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let indexSet = IndexSet(integer: sectionIndex)
        
        switch type {
        case .insert:
            tableView.insertSections(indexSet, with: .automatic)
        case .delete:
            tableView.deleteSections(indexSet, with: .automatic)
        default: 
            break
        }
    }
}
