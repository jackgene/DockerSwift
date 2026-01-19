@preconcurrency import DockerSwift
import Logging

var logger = Logger(label: "docker-client")
logger.logLevel = .warning
let docker = DockerClient(logger: logger)
let containerSpec = ContainerSpec(
    config: .init(image: "ghcr.io/jamesward/easyracer:latest", exposedPorts: [.tcp(8080)]),
    hostConfig: .init(portBindings: [.tcp(8080): [.publishTo(hostIp: "0.0.0.0", hostPort: 0)]])
)
let newContainer = try await docker.containers.create(spec: containerSpec)
try await docker.containers.start(newContainer.id)
let runningContainer = try await docker.containers.get(newContainer.id)
print("WTF: \(runningContainer.networkSettings.ports["8080/tcp"]??.first?.hostPort ?? "ops")")
try await Task.sleep(nanoseconds: 3 * 1_000_000_000)
try await docker.containers.stop(newContainer.id)
try await docker.containers.remove(newContainer.id)
try await docker.shutdown()
print("Hello, world!")
