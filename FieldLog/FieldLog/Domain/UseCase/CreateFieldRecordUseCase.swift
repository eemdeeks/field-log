//
//  CreateFieldRecordUseCase.swift
//  FieldLog
//
//  Created by 박승찬 on 9/15/26.
//

import Foundation

/// 현장 기록 생성.
/// 저장 전 thumbnailGenerator로 썸네일을 생성해 Photo에 첨부한다.
/// 썸네일은 영속화되는 파생 데이터이므로 저장 경로 단일화를 위해 UseCase가 책임진다.
struct CreateFieldRecordUseCase {
    let repository: any FieldRecordRepository
    let thumbnailGenerator: any ThumbnailGenerating

    func callAsFunction(_ record: FieldRecord) async throws {
        let thumbData = thumbnailGenerator.thumbnail(
            from: record.photo.imageData,
            targetSize: 80
        )
        let photoWithThumb = Photo(
            imageData: record.photo.imageData,
            metadata: record.photo.metadata,
            thumbnailData: thumbData
        )
        let recordToSave = FieldRecord(
            id: record.id,
            coordinate: record.coordinate,
            createdAt: record.createdAt,
            memo: record.memo,
            photo: photoWithThumb
        )
        try await repository.create(recordToSave)
    }
}
