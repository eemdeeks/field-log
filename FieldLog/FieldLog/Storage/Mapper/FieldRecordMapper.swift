//
//  FieldRecordMapper.swift
//  FieldLog
//
//  Created by 박승찬 on 9/15/26.
//

import Foundation

/// Domain Entity ↔ SwiftData 모델 간 양방향 변환.
extension PhotoModel {
    func toDomain() -> Photo {
        let coordinate: Coordinate? = {
            guard let exifLatitude, let exifLongitude else { return nil }
            return Coordinate(latitude: exifLatitude, longitude: exifLongitude)
        }()
        return Photo(
            imageData: imageData,
            metadata: PhotoMetadata(coordinate: coordinate, capturedAt: capturedAt),
            thumbnailData: thumbnailData
        )
    }
}

extension Photo {
    func toModel() -> PhotoModel {
        PhotoModel(
            imageData: imageData,
            thumbnailData: thumbnailData,
            exifLatitude: metadata.coordinate?.latitude,
            exifLongitude: metadata.coordinate?.longitude,
            capturedAt: metadata.capturedAt
        )
    }
}

extension FieldRecordModel {
    func toDomain() -> FieldRecord {
        FieldRecord(
            id: id,
            coordinate: Coordinate(latitude: latitude, longitude: longitude),
            createdAt: createdAt,
            memo: memo,
            photo: photo.toDomain()
        )
    }
}

extension FieldRecord {
    func toModel() -> FieldRecordModel {
        FieldRecordModel(
            id: id,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            createdAt: createdAt,
            memo: memo,
            photo: photo.toModel()
        )
    }
}
