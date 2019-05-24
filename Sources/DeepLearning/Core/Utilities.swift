//===-- Utilities.swift ---------------------------------------*- swift -*-===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
//
// This file defines utility functions and common type aliases.
//
//===----------------------------------------------------------------------===//

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#else
import Glibc
#endif
import CTensorFlow

//===----------------------------------------------------------------------===//
// Runtime checkers
//===----------------------------------------------------------------------===//

/// These checks run in both debug and release modes (while assert() only runs
/// in debug mode), to help shake out more bugs and facilitate debugging in the
/// early project phases. It can be replaced with plain assert() later, when we
/// have a more mature code base.
@usableFromInline
func internalConsistencyCheck(
  _ predicate: Bool,
  _ errMessage: String = "TF runtime assertion failure",
  file: StaticString = #file,
  line: UInt = #line
) {
  guard predicate else {
    fatalError(errMessage, file: file, line: line)
  }
}

@usableFromInline
func checkOk(_ s: CTFStatus?, file: StaticString = #file, line: UInt = #line) {
  internalConsistencyCheck(TF_GetCode(s) == TF_OK,
                           String(cString: TF_Message(s)),
                           file: file, line: line)
}

//===----------------------------------------------------------------------===//
// Type aliases
//===----------------------------------------------------------------------===//

// Before assigning a C pointer to one of the pointer type aliases below, caller
// should check that the pointer is not NULL.

/// The `TF_Session *` type.
@usableFromInline typealias CTFSession = OpaquePointer

/// The `TF_Status *` type.
@usableFromInline typealias CTFStatus = OpaquePointer

/// The `TF_Graph*` type.
@usableFromInline typealias CTFGraph = OpaquePointer

/// The `TF_Function*` type.
@usableFromInline typealias CTFFunction = OpaquePointer

/// The `TF_Tensor *` type.
@usableFromInline typealias CTensor = OpaquePointer

/// The `TF_TensorHandle *` type.
///
/// - Note: This is public so that compiler generated code can read/write tensor
/// handles when calling runtime APIs.
public typealias CTensorHandle = OpaquePointer

/// The `TFE_Context *` type.
public typealias CTFEContext = OpaquePointer

/// The `TFE_Op *` type.
@usableFromInline typealias CTFEOp = OpaquePointer

/// The `TF_OperationDescription *` type.
@usableFromInline typealias CTFOperationDescription = OpaquePointer

/// The `TFE_TraceContext *` type.
@usableFromInline typealias CTFETraceContext = OpaquePointer

//===----------------------------------------------------------------------===//
// Logging
//===----------------------------------------------------------------------===//

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
let stderr = __stderrp
let stdout = __stdoutp
#endif

/// Log to standard error.
func logToStderr(_ message: StaticString) {
  message.utf8Start
    .withMemoryRebound(to: Int8.self, capacity: message.utf8CodeUnitCount) {
  _ = fputs($0, stderr)
  }
}

/// Log to standard error.
func logToStderr(_ message: String) {
  _ = fputs(message, stderr)
}

@usableFromInline
func debugLog(_ message: @autoclosure () -> String,
              file: StaticString = #file,
              line: UInt = #line) {
  if _RuntimeConfig.printsDebugLog {
    print("[\(file):\(line)] \(message())")
    // This helps dump more log before a crash.
    fflush(stdout)
  }
}

//===----------------------------------------------------------------------===//
// File writing
//===----------------------------------------------------------------------===//

/// Given the address of a `TF_Buffer` and a file path, write the buffer's
/// contents to the file.
func writeContents(of buffer: UnsafePointer<TF_Buffer>,
                   toFile path: String) {
  let fp = fopen(path, "w+")
  fwrite(buffer.pointee.data, /*size*/ 1, /*count*/ buffer.pointee.length, fp)
  fclose(fp)
}

//===----------------------------------------------------------------------===//
// Unit test utilities
//===----------------------------------------------------------------------===//

// TODO: Consider revising the call sites where this is necessary to only need
// UnsafeMutablePointer to optional when it is the actual c-api call site.
extension UnsafeMutablePointer where Pointee == CTensorHandle? {
  @usableFromInline
  init(_ other: UnsafeMutablePointer<CTensorHandle>) {
    self.init(other._rawValue)
  }
  @usableFromInline
  init?(_ other: UnsafeMutablePointer<CTensorHandle>?) {
    guard let unwrapped = other else { return nil }
    self.init(unwrapped)
  }
}
