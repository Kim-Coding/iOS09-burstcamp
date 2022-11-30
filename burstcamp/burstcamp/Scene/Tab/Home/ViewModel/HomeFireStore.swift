//
//  HomeFireStore.swift
//  burstcamp
//
//  Created by youtak on 2022/11/29.
//

import Combine
import Foundation

import FirebaseFirestore

protocol HomeFireStore {
    func fetchFeed() -> AnyPublisher<[Feed], Error>
}

final class HomeFireStoreService: HomeFireStore {
    
    private let database = Firestore.firestore()
    private var cancelBag = Set<AnyCancellable>()
    
    func fetchFeed() -> AnyPublisher<[Feed], Error> {
        Future<[Feed], Error> { [weak self] promise in
            guard let self = self else { return }
            
            var result = [Feed]()
            var count = 1
            
            let feeds = self.database
                .collection("Feed")
                .order(by: "pubDate", descending: false)
                .limit(to: 20)
            
            feeds.getDocuments { querySnapshot, _ in
                guard let querySnapshot = querySnapshot else { return }
                querySnapshot.documents.forEach { queryDocumentSnapshot in
                    let data = queryDocumentSnapshot.data()
                    let feedDTO = FeedDTO(data: data)
                    var feed = Feed()
                    self.fetchWriter(userUUID: feedDTO.writerUUID)
                        .sink { completion in
                            switch completion {
                            case .finished:
                                if count >= querySnapshot.documents.count {
                                    promise(.success(result))
                                } else {
                                    count += 1
                                }
                            case .failure(let error):
                                promise(.failure(error))
                            }
                        } receiveValue: { feedWriter in
                            feed = Feed(feedDTO: feedDTO, feedWriter: feedWriter)
                            result.append(feed)
                        }
                        .store(in: &self.cancelBag)
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func fetchWriter(userUUID: String) -> AnyPublisher<FeedWriter, Error> {
        Future<FeedWriter, Error> { [weak self] promise in
            self?.database
                .collection("User")
                .document(userUUID)
                .getDocument { documentSnapShot, error in
                    if let documentSnapShot = documentSnapShot,
                       let userData = documentSnapShot.data() {
                        let feedWriter = FeedWriter(data: userData)
                        promise(.success(feedWriter))
                    } else if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.failure(FirebaseError.fetchUserError))
                    }
                }
        }
        .eraseToAnyPublisher()
    }
}
