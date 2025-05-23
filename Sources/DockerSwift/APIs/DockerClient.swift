import Foundation
import NIO
import NIOHTTP1
import NIOSSL
import AsyncHTTPClient
import Logging

/// The entry point for Docker client commands.
public final class DockerClient: Sendable {
    internal let apiVersion = "v1.41"
    private let headers = HTTPHeaders([
        ("Host", "localhost"), // Required by Docker
        ("Accept", "application/json;charset=utf-8"),
        ("Content-Type", "application/json")
    ])
    private let decoder: JSONDecoder
    
    internal let daemonURL: URL
    internal let tlsConfig: TLSConfiguration?
    internal let client: HTTPClient
    private let logger: Logger
    
    
    /// Initialize the `DockerClient`.
    /// - Parameters:
    ///   - daemonURL: The URL where the Docker API is listening on. Default is `http+unix:///var/run/docker.sock`.
    ///   - tlsConfig: `TLSConfiguration` for a Docker daemon requiring TLS authentication. Default is `nil`.
    ///   - logger: `Logger` for the `DockerClient`. Default is `.init(label: "docker-client")`.
    ///   - clientThreads: Number of threads to use for the HTTP client EventLoopGroup. Defaults to 2.
    ///   - timeout: Pass custom connect and read timeouts via a `HTTPClient.Configuration.Timeout` instance
    ///   - proxy: Proxy settings, defaults to `nil`.
    public init(
        daemonURL: URL = URL(httpURLWithSocketPath: "/var/run/docker.sock")!,
        tlsConfig: TLSConfiguration? = nil,
        logger: Logger = .init(label: "docker-client"),
        clientThreads: Int = 2,
        timeout: HTTPClient.Configuration.Timeout = .init(),
        proxy: HTTPClient.Configuration.Proxy? = nil
    ) {
            
            self.daemonURL = daemonURL
            self.tlsConfig = tlsConfig
            let clientConfig = HTTPClient.Configuration(
                tlsConfiguration: tlsConfig,
                timeout: timeout,
                proxy: proxy,
                ignoreUncleanSSLShutdown: true
            )
            let httpClient = HTTPClient(
                eventLoopGroupProvider: .shared(MultiThreadedEventLoopGroup(numberOfThreads: clientThreads)),
                configuration: clientConfig
            )
            self.client = httpClient
            self.logger = logger
            
            // Docker uses a slightly custom format for returning dates
            let format = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSS'Z'"
            let formatter = DateFormatter()
            formatter.dateFormat = format

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(formatter)
            self.decoder = decoder
        }
    
    /// The client needs to be shutdown otherwise it can crash on exit.
    /// - Throws: Throws an error if the `DockerClient` can not be shutdown.
    public func syncShutdown() throws {
        try client.syncShutdown()
    }
    
    /// The client needs to be shutdown otherwise it can crash on exit.
    /// - Throws: Throws an error if the `DockerClient` can not be shutdown.
    public func shutdown() async throws {
        try await client.shutdown()
    }
    
    /// Executes a request to a specific endpoint. The `Endpoint` struct provides all necessary data and parameters for the request.
    /// - Parameter endpoint: `Endpoint` instance with all necessary data and parameters.
    /// - Throws: It can throw an error when encoding the body of the `Endpoint` request to JSON.
    /// - Returns: Returns the expected result definied by the `Endpoint`.
    @discardableResult
    internal func run<T: Endpoint>(_ endpoint: T) async throws -> T.Response {
        logger.debug("\(Self.self) execute Endpoint: \(endpoint.method) \(endpoint.path)")
        var finalHeaders: HTTPHeaders = self.headers
        if let additionalHeaders = endpoint.headers {
            finalHeaders.add(contentsOf: additionalHeaders)
        }
        return try await client.execute(
            endpoint.method,
            daemonURL: self.daemonURL,
            urlPath: "/\(apiVersion)/\(endpoint.path)",
            body: endpoint.body.map {HTTPClient.Body.data( try! $0.encode())},
            logger: logger,
            headers: finalHeaders
        )
        .logResponseBody(logger)
        .decode(as: T.Response.self, decoder: self.decoder)
        .get()
    }
    
    /// Executes a request to a specific endpoint. The `PipelineEndpoint` struct provides all necessary data and parameters for the request.
    /// The difference for between `Endpoint` and `EndpointPipeline` is that the second one needs to provide a function that transforms the response as a `String` to the expected result.
    /// - Parameter endpoint: `PipelineEndpoint` instance with all necessary data and parameters.
    /// - Throws: It can throw an error when encoding the body of the `PipelineEndpoint` request to JSON.
    /// - Returns: Returns the expected result definied and transformed by the `PipelineEndpoint`.
    @discardableResult
    internal func run<T: PipelineEndpoint>(_ endpoint: T) async throws -> T.Response {
        logger.debug("\(Self.self) execute PipelineEndpoint: \(endpoint.method) \(endpoint.path)")
        return try await client.execute(
            endpoint.method,
            daemonURL: self.daemonURL,
            urlPath: "/\(apiVersion)/\(endpoint.path)",
            body: endpoint.body.map {HTTPClient.Body.data( try! $0.encode())},
            logger: logger,
            headers: self.headers
        )
        .logResponseBody(logger)
        .mapString(map: endpoint.map(data: ))
        .get()
    }
    
    @discardableResult
    internal func run<T: StreamingEndpoint>(_ endpoint: T, timeout: TimeAmount, hasLengthHeader: Bool, separators: [UInt8]) async throws -> T.Response {
        logger.debug("\(Self.self) execute StreamingEndpoint: \(endpoint.method) \(endpoint.path)")
        let stream = try await client.executeStream(
            endpoint.method,
            daemonURL: self.daemonURL,
            urlPath: "/\(apiVersion)/\(endpoint.path)",
            body: endpoint.body.map {
                HTTPClientRequest.Body.bytes( try! $0.encode())
            },
            timeout: timeout,
            logger: logger,
            headers: self.headers,
            hasLengthHeader: hasLengthHeader,
            separators: separators
        )
        return stream as! T.Response
    }
    
    @discardableResult
    internal func run<T: UploadEndpoint>(_ endpoint: T, timeout: TimeAmount, separators: [UInt8]) async throws -> T.Response {
        logger.debug("\(Self.self) execute \(T.self): \(endpoint.path)")
        let stream = try await client.executeStream(
            endpoint.method,
            daemonURL: self.daemonURL,
            urlPath: "/\(apiVersion)/\(endpoint.path)",
            body: endpoint.body == nil ? nil : .bytes(endpoint.body!),
            timeout: timeout,
            logger: logger,
            headers: self.headers,
            separators: separators
        )
        return stream as! T.Response
    }
}
