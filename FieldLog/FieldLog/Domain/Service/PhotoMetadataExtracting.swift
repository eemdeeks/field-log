
//  PhotoMetadataExtracting.swift
//  FieldLog

import Foundation

/// 이미지 Data에서 PhotoMetadata를 추출하는 서비스 인터페이스.
/// 저장소(Repository)가 아닌 순수 변환이므로 Service 폴더에 위치.
/// async: ImageIO 파싱을 오프-메인에서 실행할 경계를 열어둠.
protocol PhotoMetadataExtracting: Sendable {
    func extract(from imageData: Data) async throws -> PhotoMetadata
}
