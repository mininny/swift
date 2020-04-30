// RUN: %empty-directory(%t)
// RUN: %clang -c -v %target-cc-options -g -O0 -isysroot %sdk %S/Inputs/extraDataFields.cpp -o %t/extraDataFields.o -I %clang-include-dir -I %swift_src_root/include/ -I %swift_src_root/../llvm-project/llvm/include -I %clang-include-dir/../../llvm-macosx-x86_64/include -L %clang-include-dir/../lib/swift/macosx

// RUN: %target-build-swift -c %S/Inputs/enum-extra-data-fields.swift -emit-library -emit-module -enable-library-evolution -module-name ExtraDataFieldsNoTrailingFlags -target %module-target-future -Xfrontend -disable-generic-metadata-prespecialization -emit-module-path %t/ExtraDataFieldsNoTrailingFlags.swiftmodule -o %t/libExtraDataFieldsNoTrailingFlags.dylib
// RUN: %target-build-swift -c %S/Inputs/enum-extra-data-fields.swift -emit-library -emit-module -enable-library-evolution -module-name ExtraDataFieldsTrailingFlags -target %module-target-future -Xfrontend -prespecialize-generic-metadata -emit-module-path %t/ExtraDataFieldsTrailingFlags.swiftmodule -o %t/libExtraDataFieldsTrailingFlags.dylib
// RUN: %target-build-swift -v %mcp_opt %s %t/extraDataFields.o -import-objc-header %S/Inputs/extraDataFields.h -Xfrontend -disable-generic-metadata-prespecialization -target %module-target-future -lc++ -L %clang-include-dir/../lib/swift/macosx -sdk %sdk -o %t/main -I %t -L %t -lExtraDataFieldsTrailingFlags -lExtraDataFieldsNoTrailingFlags -module-name main

// RUN: %target-codesign %t/main
// RUN: %target-run %t/main | %FileCheck %s

// REQUIRES: OS=macosx
// REQUIRES: executable_test
// UNSUPPORTED: use_os_stdlib

func ptr<T>(to ty: T.Type) -> UnsafeMutableRawPointer {
    UnsafeMutableRawPointer(mutating: unsafePointerToMetadata(of: ty))!
}

func unsafePointerToMetadata<T>(of ty: T.Type) -> UnsafePointer<T.Type> {
  unsafeBitCast(ty, to: UnsafePointer<T.Type>.self)
}

import ExtraDataFieldsNoTrailingFlags


let one = completeMetadata(
  ptr(
    to: ExtraDataFieldsNoTrailingFlags.FixedPayloadSize<Void>.self
  )
)

// CHECK: nil
print(
  trailingFlagsForEnumMetadata(
    one
  )
)

let onePayloadSize = payloadSizeForEnumMetadata(one)

// CHECK-NEXT: 8
print(onePayloadSize!.pointee)

let two = completeMetadata(
  ptr(
    to: ExtraDataFieldsNoTrailingFlags.DynamicPayloadSize<Int32>.self
  )
)

// CHECK-NEXT: nil
print(
  trailingFlagsForEnumMetadata(
    two
  )
)

let twoPayloadSize = payloadSizeForEnumMetadata(two)

// CHECK-NEXT: nil
print(twoPayloadSize)


import ExtraDataFieldsTrailingFlags


let three = completeMetadata(
  ptr(
    to: ExtraDataFieldsTrailingFlags.FixedPayloadSize<Void>.self
  )
)

// CHECK-NEXT: 0
print(
  trailingFlagsForEnumMetadata(
    three
  )!.pointee
)

let threePayloadSize = payloadSizeForEnumMetadata(three)

// CHECK-NEXT: 8
print(threePayloadSize!.pointee)

let four = completeMetadata(
  ptr(
    to: ExtraDataFieldsTrailingFlags.DynamicPayloadSize<Int32>.self
  )
)

// CHECK-NEXT: 0
print(
  trailingFlagsForEnumMetadata(
    four
  )!.pointee
)

let fourPayloadSize = payloadSizeForEnumMetadata(four)

// CHECK-NEXT: nil
print(fourPayloadSize)

