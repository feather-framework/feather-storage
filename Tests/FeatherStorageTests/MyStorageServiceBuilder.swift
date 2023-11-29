//
//  MyStorageServiceBuilder.swift
//  FeatherStorageTests
//
//  Created by Tibor Bödecs on 29/11/2023.
//

import FeatherService

struct MyStorageServiceBuilder: ServiceBuilder {

    func build(using config: ServiceConfig) throws -> Service {
        MyStorageService(config: config, availableSpace: 0)
    }

}
