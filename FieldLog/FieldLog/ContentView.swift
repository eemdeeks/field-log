
//  ContentView.swift
//  FieldLog

import SwiftUI

struct ContentView: View {
    let addRecordViewModel: AddRecordViewModel

    var body: some View {
        MapView(addRecordViewModel: addRecordViewModel)
    }
}
