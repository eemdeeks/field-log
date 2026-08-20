//
//  POCTestView.swift
//  PoC-EXIF
//
//  Created by 박승찬 on 8/20/26.
//

import SwiftUI
import PhotosUI

struct PoCTestView: View {
    @State private var selectedItems: [PhotosPickerItem] = []

    var body: some View {
        VStack {
            PhotosPicker(selection: $selectedItems, matching: .images) {
                Text("사진 선택")
            }.onChange(of: selectedItems) { _, newItems in
                loadImages(newItems)
                loadAssetInfo(from: newItems)
            }
        }
        .padding()

    }

    private func loadImages(_ items: [PhotosPickerItem]) {
        for item in items {
            item.loadTransferable(type: Data.self) { result in
                switch result {
                case .success(let data):
                    if let data, let image = UIImage(data: data) {
                        print("이미지 로드 성공: \(image.size)")
                    }
                case .failure(let error):
                    print("실패: \(error)")
                }
            }
        }
    }

    private func loadAssetInfo(from items: [PhotosPickerItem]) {
        let identifiers = items.compactMap { $0.itemIdentifier }
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)

        fetchResult.enumerateObjects { asset, _, _ in
            print("위치:\(asset.location?.coordinate.latitude ?? 0),\(asset.location?.coordinate.longitude ?? 0)")
            print("촬영 시간:\(asset.creationDate?.description ?? "없음")")
        }
    }

}
