//
//  FieldRecordRepository.swift
//  FieldLog
//
//  Created by 박승찬 on 9/15/26.
//

import Foundation

/// 현장 기록 저장소 인터페이스.
/// Data 레이어가 구현하고, Presentation은 이 protocol에만 의존한다.
/// async throws: Repository는 I/O 경계이므로 지금 SwiftData가 동기라도 경계를 async로 두어 추후 Network 구현체를 수용한다.
protocol FieldRecordRepository: Sendable {
    func create(_ record: FieldRecord) async throws
    func fetchAll() async throws -> [FieldRecord]
    func update(_ record: FieldRecord) async throws
    func delete(id: UUID) async throws
}
