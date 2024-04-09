//
//  MyStorageComponentFactory.swift
//  FeatherStorageTests
//
//  Created by Tibor Bödecs on 29/11/2023.
//

import FeatherComponent

struct MyStorageComponentFactory: ComponentFactory {

    func build(using config: ComponentConfig) throws -> Component {
        MyStorageComponent(config: config, availableSpace: 0)
    }
}
