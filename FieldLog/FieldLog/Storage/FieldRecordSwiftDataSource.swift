//
//  FieldRecordSwiftDataSource.swift
//  FieldLog
//
//  Created by 박승찬 on 9/17/26.
//

import Foundation
import SwiftData

/// FieldRecordLocalDataSource의 SwiftData 구현체.
/// ModelContext를 직접 다루는 유일한 타입.
@MainActor
final class FieldRecordSwiftDataSource: FieldRecordLocalDataSource {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func create(_ record: FieldRecord) throws {
        context.insert(record.toModel())
        try context.save()
    }

    func fetchAll() throws -> [FieldRecord] {
        let descriptor = FetchDescriptor<FieldRecordModel>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    /// memo만 갱신한다. 위치·시간은 기록 시점 불변.
    func update(_ record: FieldRecord) throws {
        let id = record.id
        var descriptor = FetchDescriptor<FieldRecordModel>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        guard let model = try context.fetch(descriptor).first else { return }
        model.memo = record.memo
        try context.save()
    }

    func delete(id: UUID) throws {
        try context.delete(model: FieldRecordModel.self, where: #Predicate { $0.id == id })
        try context.save()
    }
}
