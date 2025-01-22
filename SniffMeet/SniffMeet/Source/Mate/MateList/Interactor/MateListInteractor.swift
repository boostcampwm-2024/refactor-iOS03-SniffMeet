//
//  MateListPresentable.swift
//  SniffMeet
//
//  Created by Kelly Chui on 11/21/24.
//

import Foundation

protocol MateListInteractable: AnyObject {
    var presenter: (any MateListPresentable)? { get set }

    func requestMateList(page: Int, pageSize: Int) async throws -> [Mate]
    func requestProfileImages(mates: [Mate]) async -> [(mateID: UUID, imageData: Data)]
}

final class MateListInteractor: MateListInteractable {
    weak var presenter: (any MateListPresentable)?
    private let requestMateListUseCase: any RequestMateListUseCase
    private let requestProfileImageUseCase: any RequestProfileImageUseCase
    init(
        presenter: (any MateListPresentable)? = nil,
        requestMateListUseCase: any RequestMateListUseCase,
        requestProfileImageUseCase: any RequestProfileImageUseCase

    ) {
        self.presenter = presenter
        self.requestMateListUseCase = requestMateListUseCase
        self.requestProfileImageUseCase = requestProfileImageUseCase
    }

    func requestMateList(page: Int, pageSize: Int) async throws -> [Mate] {
        let mateList = try await requestMateListUseCase.execute(
            page: page,
            pageSize: pageSize
        )
        return mateList
    }

    func requestProfileImages(mates: [Mate]) async -> [(mateID: UUID, imageData: Data)] {
        var result: [(UUID, Data)] = []

        await withTaskGroup(of: (UUID, Data?).self) { [weak self] group in
            for mate in mates {
                guard let profileImageURLString = mate.profileImageURLString else { continue }
                group.addTask {
                    let imageData = try? await self?.requestProfileImageUseCase.execute(
                        fileName: profileImageURLString
                    )
                    return (mate.userID, imageData)
                }
            }
            for await (mateID, profileImageData) in group {
                guard let profileImageData else { continue }
                result.append((mateID, profileImageData))
            }
        }
        return result
    }
}
