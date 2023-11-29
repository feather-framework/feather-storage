//
//  MyStorageServiceContext.swift
//  FeatherStorageTests
//
//  Created by Tibor Bödecs on 29/11/2023.
//

import FeatherService

struct MyStorageServiceContext: ServiceContext {

    func make() throws -> ServiceBuilder {
        MyStorageServiceBuilder()
    }
}
