
//  ThumbnailGenerating.swift
//  FieldLog

import Foundation

/// 이미지 Data에서 썸네일 Data를 생성하는 서비스 인터페이스.
/// 저장소(Repository)가 아닌 순수 변환이므로 Service 폴더에 위치.
/// PhotoMetadataExtracting과 대칭하는 3계층 패턴.
///
/// - 실패는 nil로 표현한다. 썸네일 생성 실패를 저장 실패로 올리지 않는다.
/// - targetSize는 Int(픽셀 수). Domain은 import Foundation만 허용하며
///   그래픽/UI 좌표계 타입(CGFloat 등)을 들이지 않는다.
protocol ThumbnailGenerating: Sendable {
    func thumbnail(from imageData: Data, targetSize: Int) -> Data?
}
