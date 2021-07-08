//
//  String.swift
//  HTTPTransport
//
//  Created by incetro on 6/7/21.
//  Copyright © 2021 RedMadRobot LLC & Incetro Inc. All rights reserved.
//

// MARK: - String

extension String {

    // MARK: - TruncationPosition

    enum TruncationPosition {

        // MARK: - Cases

        case head
        case middle
        case tail
    }

    // MARK: - Useful

    func truncated(
        limit: Int = 10_000,
        position: TruncationPosition = .middle,
        leader: String = "..."
    ) -> String {
        guard self.count > limit else { return self }
        switch position {
        case .head:
            return leader + self.suffix(limit)
        case .middle:
            let headCharactersCount = Int(ceil(Float(limit - leader.count) / 2.0))
            let tailCharactersCount = Int(floor(Float(limit - leader.count) / 2.0))
            return "\(self.prefix(headCharactersCount))\(leader)\(self.suffix(tailCharactersCount))"
        case .tail:
            return self.prefix(limit) + leader
        }
    }
}
