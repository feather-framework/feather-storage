//
//  MyStorageComponentContext.swift
//  FeatherStorageTests
//
//  Created by Tibor Bödecs on 29/11/2023.
//

import FeatherComponent

struct MyStorageComponentContext: ComponentContext {

    func make() throws -> ComponentFactory {
        MyStorageComponentFactory()
    }
}
