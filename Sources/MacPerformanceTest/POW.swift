//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2020-07-28.
//

import Foundation
import CryptoKit
import OSLog

public final class SHA256TwiceHasher {
    public init() {}
}

public extension SHA256TwiceHasher {
    
    @inline(__always)
    func sha256Twice(of data: Data) -> Data {
        var hasher1 = SHA256()
        data.withUnsafeBytes { (bufferPointer: UnsafeRawBufferPointer) in
            hasher1.update(bufferPointer: bufferPointer)
        }
        let digest1 = hasher1.finalize()
        
        var hasher2 = SHA256()
        digest1.withUnsafeBytes { (bufferPointer: UnsafeRawBufferPointer) in
            hasher2.update(bufferPointer: bufferPointer)
        }
        return Data(hasher2.finalize())
    }
}


/// A random value between [Int.min...Int.max]
public struct Nonce:
    CustomStringConvertible,
    Equatable,
    ExpressibleByIntegerLiteral
{
    
    public typealias Value = Int64
    public private(set) var value: Value
    
    public init() {
        value = Int64.random(in: Value.min...Value.max)
    }
}

public extension Nonce {
    static func += (nonce: inout Nonce, increment: Value) {
        nonce.value += increment
    }
}

// MARK: - CustomStringConvertible
public extension Nonce {
    var description: String {
        return value.description
    }
}
// MARK: - ExpressibleByIntegerLiteral
public extension Nonce {
    init(integerLiteral value: Value) {
        self.value = value
    }
}

//private let logger = Logger(subsystem: "MacPerformanceTest", category: "ProofOfWork")
public struct ProofOfWork: CustomStringConvertible, CustomDebugStringConvertible {
    
    private let seed: Data
    public let nonce: Nonce
    public let targetNumberOfLeadingZeros: NumberOfLeadingZeros
    
    internal init(seed: Data, targetNumberOfLeadingZeros: NumberOfLeadingZeros, nonce: Nonce) {
        self.seed = seed
        self.targetNumberOfLeadingZeros = targetNumberOfLeadingZeros
        self.nonce = nonce

        func logIfNonceExceedsThreshold(_ threshold: Nonce = 500_000) {
            guard nonce.value > threshold.value else { return }
            
            let messageToLog = """
                🙋🏻‍♀️ POW high nonce: \(nonce.value)
                Seed: \(seed.toHexString())
                #Zeros: \(targetNumberOfLeadingZeros)
            """
            
//            logger.info(messageToLog)
            Swift.print(messageToLog)
        }
        logIfNonceExceedsThreshold()
    }
}
public extension ProofOfWork {
    struct NumberOfLeadingZeros: ExpressibleByIntegerLiteral, CustomStringConvertible {
        
        public let numberOfLeadingZeros: Value
        
        init(_ numberOfLeadingZeros: Value) throws {
            
            guard numberOfLeadingZeros >= NumberOfLeadingZeros.minimumNumberOfLeadingZeros else {
                throw Error.tooFewLeadingZeros(
                    expectedAtLeast: NumberOfLeadingZeros.minimumNumberOfLeadingZeros,
                    butGot: numberOfLeadingZeros
                )
            }
            
            self.numberOfLeadingZeros = numberOfLeadingZeros
        }
    }
}

// MARK: - Presets
public extension ProofOfWork.NumberOfLeadingZeros {
    static let minimumNumberOfLeadingZeros: Value = 1

    static let `default`: ProofOfWork.NumberOfLeadingZeros = 16
}

// MARK: - CustomStringConvertible
public extension ProofOfWork.NumberOfLeadingZeros {
    var description: String {
        return numberOfLeadingZeros.description
    }
}

// MARK: - Errors
public extension ProofOfWork.NumberOfLeadingZeros {
    typealias Value = UInt8
    
    enum Error: Swift.Error {
        case tooFewLeadingZeros(expectedAtLeast: Value, butGot: Value)
    }
}

// MARK: - ExpressibleByIntegerLiteral
public extension ProofOfWork.NumberOfLeadingZeros {
    init(integerLiteral value: Value) {
        do {
            try self.init(value)
        } catch {
            fatalError("Bad value, error: \(error)")
        }
    }
}

// MARK: Data + NumberOfLeadingZeroBits
internal extension Data {
    @inline(__always) func countNumberOfLeadingZeroBits() -> Int {
        let bitsPerByte = 8
        guard let index = self.firstIndex(where: { $0 != 0 }) else {
            return self.count * bitsPerByte
        }
        
        // count zero bits in byte at index `index`
        return index * bitsPerByte + self[index].leadingZeroBitCount
    }
}

internal extension ProofOfWork.NumberOfLeadingZeros {
    static func < (lhs: Int, rhs: ProofOfWork.NumberOfLeadingZeros) -> Bool {
        return lhs < rhs.numberOfLeadingZeros
    }
    
    static func >= (lhs: Int, rhs: ProofOfWork.NumberOfLeadingZeros) -> Bool {
        return lhs >= rhs.numberOfLeadingZeros
    }
}

// MARK: - Prove
public extension ProofOfWork {
    @discardableResult
    func prove() throws -> ProofOfWork {
        let hashed = hash()
        let numberOfLeadingZeros = hashed.countNumberOfLeadingZeroBits()
        if numberOfLeadingZeros < targetNumberOfLeadingZeros {
            throw Error.tooFewLeadingZeros(
                expectedAtLeast: targetNumberOfLeadingZeros.numberOfLeadingZeros,
                butGot: UInt8(numberOfLeadingZeros)
            )
        }
        return self
    }
}

// MARK: - Public
public extension ProofOfWork {
    var nonceAsString: String {
        return nonce.description
    }
}

// MARK: CustomStringConvertible
public extension ProofOfWork {
    var description: String {
        return nonceAsString
    }
}

// MARK: CustomDebugStringConvertible
public extension ProofOfWork {
    var debugDescription: String {
        return """
            nonce: \(nonceAsString),
            hashHex: \(hash().toHexString())
        """
    }
}

// MARK: - Error
public extension ProofOfWork {
    enum Error: Swift.Error, Equatable {
        case workInputIncorrectLengthOfSeed(expectedByteCountOf: Int, butGot: Int)
        case tooFewLeadingZeros(expectedAtLeast: UInt8, butGot: UInt8)
    }
}

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func toHexString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return map { String(format: format, $0) }.joined()
    }
}

// MARK: - Private
private extension ProofOfWork {
    func hash() -> Data {
        let unhashed: Data = seed + nonce.data
        
        return SHA256TwiceHasher().sha256Twice(of: unhashed)
    }
}

extension UInt64 {
    var data: Data {
        var int = self
        return Data(bytes: &int, count: MemoryLayout<Self>.size)
    }
}
extension Int64 {
    var data: Data {
        var int = self
        return Data(bytes: &int, count: MemoryLayout<Self>.size)
    }
}
extension Nonce {
    var data: Data {
        value.data
    }
}



public enum POW {}
public extension POW {
    
    static let expectedByteCountOfSeed = 32

    static func doWork(
        seed: Data,
        targetNumberOfLeadingZeros: ProofOfWork.NumberOfLeadingZeros,
        done: ((Result<ProofOfWork, ProofOfWork.Error>) -> Void)
    ) {
        guard seed.count == Self.expectedByteCountOfSeed else {
            
            let error = ProofOfWork.Error.workInputIncorrectLengthOfSeed(
                expectedByteCountOf: Self.expectedByteCountOfSeed,
                butGot: seed.count
            )
            
            done(.failure(error))
            return
        }
        
        var nonce: Nonce = 0

        var hash256 = Data(capacity: 32)
        
        var unhashed = Data(capacity: seed.count + 8)
        repeat {
            nonce += 1
            unhashed = seed + nonce.data
            hash256 = SHA256TwiceHasher().sha256Twice(of: unhashed)
        } while hash256.countNumberOfLeadingZeroBits() < targetNumberOfLeadingZeros.numberOfLeadingZeros
        
        let pow = ProofOfWork(
            seed: seed,
            targetNumberOfLeadingZeros: targetNumberOfLeadingZeros,
            nonce: nonce
        )
        
        done(.success(pow))
    }
}
