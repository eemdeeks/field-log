
//  ExtractPhotoMetadataUseCase.swift
//  FieldLog

import Foundation

/// 이미지 Data 한 장에서 PhotoMetadata를 추출한다.
/// 다중 선택의 부분 실패 정책(한 장 실패 시 나머지 유지)은 호출자(ViewModel)가 담당.
struct ExtractPhotoMetadataUseCase {
    let extractor: any PhotoMetadataExtracting

    func callAsFunction(_ imageData: Data) async throws -> PhotoMetadata {
        try await extractor.extract(from: imageData)
    }
}
