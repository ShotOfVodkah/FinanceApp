//
//  SubsequenceSearch.swift
//  Finance
//
//  Created by Stepan Polyakov on 30.06.2025.
//

extension String {
    func isSubsequence(of other: String) -> Bool {
        guard !self.isEmpty else { return true }
        var strIndex = self.startIndex
        var matchIndex = other.startIndex
        while matchIndex < other.endIndex {
            if self[strIndex].lowercased() == other[matchIndex].lowercased() {
                self.formIndex(after: &strIndex)
                if strIndex == self.endIndex {
                    return true
                }
            }
            other.formIndex(after: &matchIndex)
        }
        return false
    }
}
