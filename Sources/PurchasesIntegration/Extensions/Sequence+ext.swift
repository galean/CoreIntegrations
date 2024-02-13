//
//  File.swift
//  
//
//  Created by Anatolii Kanarskyi on 13/2/24.
//

import Foundation

extension Sequence {
    func asyncForEach(
        _ operation: (Element) async throws -> Void
    ) async rethrows {
        for element in self {
            try await operation(element)
        }
    }
}
