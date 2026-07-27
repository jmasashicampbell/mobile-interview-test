//
//  LoadingState.swift
//  ResortPassAssignment
//

import Foundation

enum LoadingState {
    case idle
    case loading
    case loaded
    case failed(Error)
}
