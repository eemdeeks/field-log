
//  FieldRecordFixtures.swift
//  FieldLogTests

import Foundation
@testable import FieldLog

extension FieldRecord {
    static func make(
        id: UUID = UUID(),
        coordinate: Coordinate = Coordinate(latitude: 37.5, longitude: 127.0),
        createdAt: Date = .now,
        memo: String? = nil,
        address: String? = nil
    ) -> FieldRecord {
        let photo = Photo(
            imageData: Data([0xFF, 0xD8]),
            metadata: PhotoMetadata(coordinate: coordinate, capturedAt: nil)
        )
        return FieldRecord(id: id, coordinate: coordinate, createdAt: createdAt, memo: memo, address: address, photo: photo)
    }
}
