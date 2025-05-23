import Foundation

public struct ContainerConfig: Codable, Sendable {
    public var attachStdin: Bool = false
    
    public var attachStdout: Bool = true
    
    public var attachStderr: Bool = true
    
    /// Custom command to run, overrides the value of the Image if any
    public var command: [String]? = nil
    
    public var domainname: String?
    
    /// Custom entrypoint to run, overrides the value of the Image if any
    public var entrypoint: [String]? = nil
    
    /// A list of environment variables to set inside the container in the form `["VAR=value", ...].`
    /// A variable without `=` is removed from the environment, rather than to have an empty value.
    public var environmentVars: [String]? = nil
    
    /// An object mapping ports to an empty object in the form:
    /// `{"<port>/<tcp|udp|sctp>": {}}`
    //public var exposedPorts: [String:EmptyObject]? = [:]
    @ExposedPortCoding
    public var exposedPorts: [ExposedPortSpec]? = []
    
    /// A test to perform to periodically check that the container is healthy.
    public var healthcheck: HealthCheckConfig? = nil
    
    /// The hostname to use for the container, as a valid RFC 1123 hostname.
    public var hostname: String = ""
    
    /// The name (or reference) of the image to use
    public var image: String
    
    public var labels: [String:String]? = [:]
    
    public var macAddress: String?
    
    /// Whether networking is disabled for the container.
    public var networkDisabled: Bool?
    
    /// `ONBUILD` metadata that were defined in the image's `Dockerfile`
    public var onBuild: [String]? = nil
    
    public var openStdin: Bool = false
    
    /// Shell for when `RUN`, `CMD`, and `ENTRYPOINT` uses a shell.
    public var shell: [String]? = nil
    
    /// Close stdin after one attached client disconnects
    public var stdinOnce: Bool = false
    
    /// Unix signal to stop a container as a string or unsigned integer.
    public var stopSignal: UnixSignal? = nil
    
    /// Timeout to stop a container, in seconds.
    /// After that, the container will be forcibly killed.
    public var stopTimeout: UInt? = 10
    
    /// Attach standard streams to a TTY, including stdin if it is not closed.
    public var tty: Bool = false
    
    /// The user that commands are run as inside the container.
    public var user: String? = nil
    
    /// An object mapping mount point paths inside the container to empty objects.
    public var volumes: [String:EmptyObject]? = [:]
    
    /// The working directory for commands to run in.
    public var workingDir: String? = nil
    
    public init(image: String, attachStdin: Bool = false, attachStdout: Bool = true, attachStderr: Bool = true, command: [String]? = nil, domainname: String? = nil, entrypoint: [String]? = nil, environmentVars: [String]? = nil, exposedPorts: [ExposedPortSpec]? = [], healthcheck: ContainerConfig.HealthCheckConfig? = nil, hostname: String = "", labels: [String : String]? = [:], macAddress: String? = nil, networkDisabled: Bool? = nil, onBuild: [String]? = nil, openStdin: Bool = false, shell: [String]? = nil, stdinOnce: Bool = false, stopSignal: UnixSignal? = nil, stopTimeout: UInt? = 10, tty: Bool = false, user: String? = nil, volumes: [String : ContainerConfig.EmptyObject]? = [:], workingDir: String? = nil) {
        self.attachStdin = attachStdin
        self.attachStdout = attachStdout
        self.attachStderr = attachStderr
        self.command = command
        self.domainname = domainname
        self.entrypoint = entrypoint
        self.environmentVars = environmentVars
        self.exposedPorts = exposedPorts
        self.healthcheck = healthcheck
        self.hostname = hostname
        self.image = image
        self.labels = labels
        self.macAddress = macAddress
        self.networkDisabled = networkDisabled
        self.onBuild = onBuild
        self.openStdin = openStdin
        self.shell = shell
        self.stdinOnce = stdinOnce
        self.stopSignal = stopSignal
        self.stopTimeout = stopTimeout
        self.tty = tty
        self.user = user
        self.volumes = volumes
        self.workingDir = workingDir
    }
    
    enum CodingKeys: String, CodingKey {
        case attachStderr = "AttachStderr"
        case attachStdout = "AttachStdout"
        case attachStdin = "AttachStdin"
        case command = "Cmd"
        case domainname = "Domainname"
        case entrypoint = "Entrypoint"
        case environmentVars = "Env"
        case exposedPorts = "ExposedPorts"
        case healthcheck = "Healthcheck"
        case hostname = "Hostname"
        case image = "Image"
        case labels = "Labels"
        case macAddress = "MacAddress"
        case networkDisabled = "NetworkDisabled"
        case onBuild = "OnBuild"
        case openStdin = "OpenStdin"
        case shell = "Shell"
        case stdinOnce = "StdinOnce"
        case stopSignal = "StopSignal"
        case stopTimeout = "StopTimeout"
        case tty = "Tty"
        case user = "User"
        case volumes = "Volumes"
        case workingDir = "WorkingDir"
    }
    
    public struct HealthCheckConfig: Codable, Sendable {
        public init(interval: UInt64, retries: UInt, startPeriod: UInt64, test: [String], timeout: UInt64) {
            self.interval = interval
            self.retries = retries
            self.startPeriod = startPeriod
            self.test = test
            self.timeout = timeout
        }
        
        /// The time to wait between checks, in nanoseconds.
        /// It should be 0 or at least 1000000 (1 ms). 0 means inherit.
        public var interval: UInt64
        
        /// The number of consecutive failures needed to consider a container as unhealthy. 0 means inherit.
        public var retries: UInt
        
        /// Start period for the container to initialize before starting health-retries countdown in nanoseconds.
        /// It should be 0 or at least 1000000 (1 ms). 0 means inherit.
        public var startPeriod: UInt64
        
        /// The test to perform. Possible values are
        /// - `[]` : inherit healthcheck from image or parent image)
        /// - `["NONE"]` : disable healthcheck
        /// - `["CMD", args...]` exec arguments directly
        /// - ["CMD-SHELL", command]` run command with system's default shell
        public var test: [String]
        
        /// The time to wait before considering the check to have hung. It should be 0 or at least 1000000 (1 ms). 0 means inherit.
        public var timeout: UInt64
        
        enum CodingKeys: String, CodingKey {
            case interval = "Interval"
            case retries = "Retries"
            case startPeriod = "StartPeriod"
            case test = "Test"
            case timeout = "Timeout"
        }
    }
    
    public struct EmptyObject: Codable, Sendable {}
}
