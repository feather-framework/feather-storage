# Feather Storage

Abstract storage component, providing a shared API surface for file storage drivers written in Swift.

[
    ![Release: 1.0.0-beta.2](https://img.shields.io/badge/Release-1%2E0%2E0--beta%2E2-F05138)
](
    https://github.com/feather-framework/feather-storage/releases/tag/1.0.0-beta.2
)

## Features

- Storage-agnostic abstraction layer
- Designed for modern Swift concurrency
- DocC-based API Documentation
- Unit tests and code coverage

## Requirements

![Swift 6.1+](https://img.shields.io/badge/Swift-6%2E1%2B-F05138)
![Platforms: Linux, macOS, iOS, tvOS, watchOS, visionOS](https://img.shields.io/badge/Platforms-Linux_%7C_macOS_%7C_iOS_%7C_tvOS_%7C_watchOS_%7C_visionOS-F05138)

- Swift 6.1+

- Platforms:
  - Linux
  - macOS 15+
  - iOS 18+
  - tvOS 18+
  - watchOS 11+
  - visionOS 2+

## Installation

Use Swift Package Manager; add the dependency to your `Package.swift` file:

```swift
.package(url: "https://github.com/feather-framework/feather-storage", exact: "1.0.0-beta.2"),
```

Then add `FeatherStorage` to your target dependencies:

```swift
.product(name: "FeatherStorage", package: "feather-storage"),
```

## Usage

[
    ![DocC API documentation](https://img.shields.io/badge/DocC-API_documentation-F05138)
](
    https://feather-framework.github.io/feather-storage/
)

API documentation is available at the following link. Refer to the mock objects in the Tests directory if you want to build a custom storage driver implementation.

> [!WARNING]  
> This repository is a work in progress, things can break until it reaches v1.0.0.

## Storage drivers

The following storage driver implementations are available for use:

- [FS](https://github.com/feather-framework/feather-storage-fs)
- [S3](https://github.com/feather-framework/feather-storage-s3)
- [Ephemeral](https://github.com/feather-framework/feather-storage-ephemeral)

## Development

- Build: `swift build`
- Test:
  - local: `swift test`
  - using Docker: `make docker-test`
- Format: `make format`
- Check: `make check`

## Contributing

[Pull requests](https://github.com/feather-framework/feather-storage/pulls) are welcome. Please keep changes focused and include tests for new logic.
