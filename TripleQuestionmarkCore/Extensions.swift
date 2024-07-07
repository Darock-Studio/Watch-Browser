//
//  Extensions.swift
//  WatchBrowser
//
//  Created by memz233 on 7/7/24.
//

import UIKit
import CoreTransferable

struct UIImageTransfer: Transferable {
    let image: UIImage
    enum TransferError: Error {
        case importFailed
    }
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            guard let uiImage = UIImage(data: data) else {
                throw TransferError.importFailed
            }
            return UIImageTransfer(image: uiImage)
        }
    }
}
