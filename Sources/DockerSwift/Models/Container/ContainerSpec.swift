import Foundation

/// The configuration to create a new Docker Container.
public struct ContainerSpec: Codable, Sendable {
    /// Configuration specific to the container, and independent from the host it is running on.
    public var config: ContainerConfig?
    
    /// Host specific configuration for the container.
    public var hostConfig: ContainerHostConfig
    
    enum CodingKeys: String, CodingKey {
        case hostConfig = "HostConfig"
    }
    
    public init(config: ContainerConfig, hostConfig: ContainerHostConfig = .init()) {
        self.config = config
        self.hostConfig = hostConfig
    }
    
    public func encode(to encoder: Encoder) throws {
        
        try config.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hostConfig, forKey: .hostConfig)
    }
}
