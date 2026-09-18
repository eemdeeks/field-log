//
//  FieldRecordLocalDataSource.swift
//  FieldLog
//
//  Created by 박승찬 on 9/17/26.
//

import Foundation

/// 로컬 저장소 DataSource 인터페이스.
/// Repository가 필요한 것을 정의하고, Persistence(Storage) 날개가 이를 구현한다.
/// Butterfly Architecture: Persistence → Repository (날개가 몸통을 의존)
@MainActor
protocol FieldRecordLocalDataSource {
    func create(_ record: FieldRecord) throws
    func fetchAll() throws -> [FieldRecord]
    func update(_ record: FieldRecord) throws
    func delete(id: UUID) throws
}
