import Foundation

public enum Architecture: String, Codable {
    case ppc64
    case ppc64le
    case x86 = "386"
    case amd64
    case arm
    case arm64
    case wasm
    case loong64
    case mips
    case mipsle
    case mips64
    case mips64le
    case riscv64
    case s390x
}
