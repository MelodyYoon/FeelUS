//
//  ImageAsset.swift
//  FeelUS (iOS)
//
//  Created by Alice Yoon on 09/02/22.
//

import SwiftUI
import PhotosUI

struct ImageAsset: Identifiable {
    var id: String = UUID().uuidString
    var asset: PHAsset
    var thumbnail: UIImage?
    var assetIndex: Int = -1
}
