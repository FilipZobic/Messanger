//
//  ProfileModel.swift
//  Messanger
//
//  Created by Filip Zobic on 5.5.22..
//

import Foundation


enum ProfileViewModelType {
    case info, logout
}

struct ProfileViewModel {
    let viewModelType: ProfileViewModelType
    let title: String
    let handler: (() -> Void)?
}
