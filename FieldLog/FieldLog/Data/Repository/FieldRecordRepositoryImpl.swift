//
//  FieldRecordRepositoryImpl.swift
//  FieldLog
//
//  Created by 박승찬 on 9/15/26.
//

import Foundation
import SwiftData

/// SwiftData 기반 FieldRecordRepository 구현체.
/// @MainActor: ModelContext는 메인 스레드 전용이므로 클래스 전체에 적용한다.
@MainActor
final class FieldRecordRepositoryImpl: FieldRecordRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func create(_ record: FieldRecord) async throws {
        context.insert(record.toModel())
        try context.save()
    }

    func fetchAll() async throws -> [FieldRecord] {
        let descriptor = FetchDescriptor<FieldRecordModel>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    /// id 기준으로 레코드를 찾아 memo를 갱신한다.
    /// 위치·시간은 기록 시점 불변으로 간주하므로 수정하지 않는다.
    func update(_ record: FieldRecord) async throws {
        let id = record.id
        var descriptor = FetchDescriptor<FieldRecordModel>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        guard let model = try context.fetch(descriptor).first else { return }
        model.memo = record.memo
        try context.save()
    }

    func delete(id: UUID) async throws {
        var descriptor = FetchDescriptor<FieldRecordModel>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        guard let model = try context.fetch(descriptor).first else { return }
        context.delete(model)
        try context.save()
    }
}
