//
//  WriteTransaction.swift
//  RealmManager
//
//  Created by SEUNGMIN OH on 2022/12/13.
//

import struct RealmSwift.Realm

public final class WriteTransaction {
    
    private let realm: Realm

    internal init(realm: Realm) {
        self.realm = realm
    }

    public func add<T: RealmCompatible>(
        _ value: T,
        update: Realm.UpdatePolicy = .modified
    ) {
        realm.add(value.realmModel(), update: update)
    }

    /// auto Increment를 지원하는 add
    public func add<T: RealmCompatible>(
        _ value: T,
        defaultIndex: Int = 0,
        update: Realm.UpdatePolicy = .modified
    ) where T.RealmModel: AutoIncrementable {
        let maxIndex = realm.objects(T.RealmModel.self)
            .map(\.autoIndex)
            .max() ?? defaultIndex

        var realmModel = value.realmModel()
        realmModel.autoIndex = maxIndex + 1
        realm.add(realmModel, update: update)
    }

    public func update<T: RealmCompatible>(
        _ type: T.Type,
        values: [T.PropertyValue]
    ) {
        var dictionary: [String: Any] = [:]
        values.forEach {
            let pair = $0.propertyValuePair
            dictionary[pair.name] = pair.value
        }

        realm.create(T.RealmModel.self, value: dictionary, update: .modified)
    }
}
