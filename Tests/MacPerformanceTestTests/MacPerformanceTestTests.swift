import XCTest
@testable import MacPerformanceTest


extension Array {
  init(reserveCapacity: Int) {
    self = Array<Element>()
    self.reserveCapacity(reserveCapacity)
  }

  var slice: ArraySlice<Element> {
    self[self.startIndex ..< self.endIndex]
  }
}

extension Array where Element == UInt8 {
  public init(hex: String) {
    self.init(reserveCapacity: hex.unicodeScalars.lazy.underestimatedCount)
    var buffer: UInt8?
    var skip = hex.hasPrefix("0x") ? 2 : 0
    for char in hex.unicodeScalars.lazy {
      guard skip == 0 else {
        skip -= 1
        continue
      }
      guard char.value >= 48 && char.value <= 102 else {
        removeAll()
        return
      }
      let v: UInt8
      let c: UInt8 = UInt8(char.value)
      switch c {
        case let c where c <= 57:
          v = c - 48
        case let c where c >= 65 && c <= 70:
          v = c - 55
        case let c where c >= 97:
          v = c - 87
        default:
          removeAll()
          return
      }
      if let b = buffer {
        append(b << 4 | v)
        buffer = nil
      } else {
        buffer = v
      }
    }
    if let b = buffer {
      append(b)
    }
  }
}
extension Data {
    public init(hex: String) {
        self.init(Array<UInt8>(hex: hex))
    }
}

extension Data: ExpressibleByStringLiteral {
    /// Data from hex string
    public init(stringLiteral hexString: String) {
        var hexString = hexString
        if hexString.starts(with: "0x") {
            hexString = String(hexString.dropLast(2))
        }
        self.init(hex: hexString)
    }
}

extension Data {
    static func unsafeGenerateRandom(byteCount: Int = 32) -> Data {
        Data(
            (0..<byteCount).map { _ in UInt8.random(in: 0...UInt8.max) }
        )
    }
}

final class POWTests: XCTestCase {
    func omitted_test_pow() {
        func doTest(seed: Data = .unsafeGenerateRandom(), zeros: UInt8 = 32) { // }, expectedNonce expectedNonceHex: String) {
            Swift.print(".", terminator: "")
            let targetNumberOfZeros: ProofOfWork.NumberOfLeadingZeros = .init(integerLiteral: zeros)
            POW.doWork(seed: seed, targetNumberOfLeadingZeros: targetNumberOfZeros) { result in
                do {
                    
                    _ = try result.get()
                    
//                    print(pow)
//                    XCTAssertEqual(pow.nonceAsString, expectedNonceHex)
                } catch {
                    XCTFail("Unexpected error: \(error)")
                }
            }
        }
        
//        doTest(seed: .unsafeGenerateRandom(), expectedNonce: "deadbeef")
        for _ in 0..<3 {
            doTest()
        }
    }
    
    private func doTest(seed: Data, expectedNonce: Int64, zeros: UInt8 = 16) {
        let targetNumberOfZeros: ProofOfWork.NumberOfLeadingZeros = .init(integerLiteral: zeros)
    
        POW.doWork(seed: seed, targetNumberOfLeadingZeros: targetNumberOfZeros) { result in
            do {
                
                let pow = try result.get()
                XCTAssertEqual(pow.nonce.value, expectedNonce)
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
    
    func omitted_test___662_213() {
        doTest(
            seed: "d92e9d175a5ebe22c5330ab3435078f65a9eb9c85a475fdd7c335d180e497375",
            expectedNonce: 662213
        )
    }
    
    func omitted_test____90_700_851() {
        doTest(
            seed: "de7da3d8aa1c0a952fe3cee785fc2e2cbee7e5c8748ab8ea6dc9a813c59ba0d6",
            expectedNonce: 90700851,
            zeros: 28
        )
    }
    
    func test____4_964_844() { // MBP 17sec DEBUG, 12s OPTIMIZED
        doTest(
            seed: "3fcf66bc249828c5155ea69336670e0e8ce9efef3286603d35770afc7877bccc",
            expectedNonce: 4_964_844,
            zeros: 22
        )
    }
    
    
}

//🙋🏻‍♀️ POW high nonce: 90 700 851
//Seed: de7da3d8aa1c0a952fe3cee785fc2e2cbee7e5c8748ab8ea6dc9a813c59ba0d6
//#Zeros: 28
//🙋🏻‍♀️ POW high nonce: 180 566 960
//Seed: f798ebd7d3b644a759a6598f091027b3f9cf310b06937d528bd9d2f7b0c53e6f
//#Zeros: 28

//🙋🏻‍♀️ POW high nonce: 13 787 147
//Seed: 75a80964784b8f99003325a0f8e816b466043e9533df0058e3a50911c67edcf6
//#Zeros: 24
//🙋🏻‍♀️ POW high nonce: 9 478 649
//Seed: 5de483e375731ba9772b8f435f80f18c45bb752e80941667f405ac2130c668d6
//#Zeros: 24
//🙋🏻‍♀️ POW high nonce: 4 964 844
//Seed: 3fcf66bc249828c5155ea69336670e0e8ce9efef3286603d35770afc7877bccc
//#Zeros: 22
//
//🙋🏻‍♀️ POW high nonce: 6 842 395
//Seed: 8922ff555706836f20756299320b5507e14f3ca6a75c19e9efd6c1e377ea4345
//#Zeros: 22
//
//🙋🏻‍♀️ POW high nonce: 8111005
//Seed: 6cbbce3792fe7c023bb1f713a06e1aab686b7f56820fdc1d4e126e20663c83d1
//#Zeros: 22

//🙋🏻‍♀️ POW high nonce: 1823870
//Seed: 356182ed4674667084edf6656415c4d28f39f29aaa85841749478713303c9456
//#Zeros: 20



//
//🙋🏻‍♀️ POW high nonce: 662213
//    Seed: d92e9d175a5ebe22c5330ab3435078f65a9eb9c85a475fdd7c335d180e497375
//    #Zeros: 16
//
//🙋🏻‍♀️ POW high nonce: 585613
//    Seed: a0c8dfb5b349558ce81b9b958e8eecb177b26cf0fd40b59dba22211e5c6b2e2b
//    #Zeros: 16

//    🙋🏻‍♀️ POW high nonce: 346279
//    Seed: 94015dcf64a16f167e1daa12cffc6ba6cfcc008eb0aa3eb882b4bbd67e686336
//    #Zeros: 16

//🙋🏻‍♀️ POW high nonce: 497145
//    Seed: 35461593a9e194ef4a264418ae02d0f3b23543eca40e0ad8ddf1c29de8541abc
//    #Zeros: 16
//🙋🏻‍♀️ POW high nonce: 459456
//    Seed: ee461a9447914f4fd3ef80c10fc82b27bf36844f2be15037f6a334b6b6571468
//    #Zeros: 16
//🙋🏻‍♀️ POW high nonce: 455474
//    Seed: 1c2dee59e0064cede057d43a2debec3878fefe77414daea6f9c10e054329494d
//    #Zeros: 16
//🙋🏻‍♀️ POW high nonce: 418746
//    Seed: ead403a4eeccf2d3498db33a6d844d01d11243c92e1b3cb0b1f53b1882614ef6
//    #Zeros: 16
