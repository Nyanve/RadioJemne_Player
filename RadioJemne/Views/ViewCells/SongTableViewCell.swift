//
//  SongTableViewCell.swift
//  RadioJemne
//
//  Created by Samuel Brezoňák on 07/02/2024.
//

import UIKit

class SongTableViewCell: UITableViewCell {

    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var nowPlayingImage: UIImageView!
    
    @IBOutlet weak var songNameLabelLeadingConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
