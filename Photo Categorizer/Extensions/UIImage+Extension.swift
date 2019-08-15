//
//  UIImage+Extension.swift
//  Photo_Categorizer
//
//  Created by Ismael Zavala on 8/14/19.
//  Copyright © 2019 Johansson. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    public func resizeImage(newWidth: CGFloat) -> UIImage {
        let scale = newWidth / self.size.width
        let newHeight = self.size.height * scale

        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))

        self.draw(in: CGRect(x: 0, y: 0,width: newWidth, height: newHeight))
        guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else {
            print("Unable to get new image")
            return UIImage()
        }
        UIGraphicsEndImageContext()

        return newImage
    }
}
