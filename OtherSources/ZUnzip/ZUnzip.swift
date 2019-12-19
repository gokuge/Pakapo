//
//  ZUnzip.swift
//  ZUnzip
//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Electricwoods LLC, Kaz Yoshikawa.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy 
//  of this software and associated documentation files (the "Software"), to deal 
//  in the Software without restriction, including without limitation the rights 
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
//  copies of the Software, and to permit persons to whom the Software is 
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in 
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//


import Foundation
import fmemopen
import libzip


public enum ZUnzipError: Error, CustomStringConvertible {
	case status(Int32)
	case inMemoryFileAllocation
	
	public var description: String {
		switch self {
		case .status(let code):
			switch code {
			case ZIP_ER_OK: return "No error"
			case ZIP_ER_MULTIDISK: return "Multi-disk zip archives not supported"
			case ZIP_ER_RENAME: return "Renaming temporary file failed"
			case ZIP_ER_CLOSE: return "Closing zip archive failed"
			case ZIP_ER_SEEK: return "Seek error"
			case ZIP_ER_READ: return "Read error"
			case ZIP_ER_WRITE: return "Write error"
			case ZIP_ER_CRC: return "CRC error"
			case ZIP_ER_ZIPCLOSED: return "Containing zip archive was closed"
			case ZIP_ER_NOENT: return "No such file"
			case ZIP_ER_EXISTS: return "File already exists"
			case ZIP_ER_OPEN: return "Can't open file"
			case ZIP_ER_TMPOPEN: return "Failure to create temporary file"
			case ZIP_ER_ZLIB: return "Zlib error"
			case ZIP_ER_MEMORY: return "Malloc failure"
			case ZIP_ER_CHANGED: return "Entry has been changed"
			case ZIP_ER_COMPNOTSUPP: return "Compression method not supported"
			case ZIP_ER_EOF: return "Premature EOF"
			case ZIP_ER_INVAL: return "Invalid argument"
			case ZIP_ER_NOZIP: return "Not a zip archive"
			case ZIP_ER_INTERNAL: return "Internal error"
			case ZIP_ER_INCONS: return "Zip archive inconsistent"
			case ZIP_ER_REMOVE: return "Can't remove file"
			case ZIP_ER_DELETED: return "Entry has been deleted"
			case ZIP_ER_ENCRNOTSUPP: return "Encryption method not supported"
			case ZIP_ER_RDONLY: return "Read-only archive"
			case ZIP_ER_NOPASSWD: return "No password provided"
			case ZIP_ER_WRONGPASSWD: return "Wrong password provided"
			default: return "Unknown error"
			}
		case .inMemoryFileAllocation: return "Can't allocate In-memory file"
		}
	}
}



public class ZUnzip {

	var _zip: UnsafeMutablePointer<zip>?
	var _file: UnsafeMutablePointer<FILE>?

	public init(path: String) throws {
		var error: Int32 = 0
		let systemPath = FileManager.default.fileSystemRepresentation(withPath: path)
		
		_zip = zip_open(systemPath, 0, &error)
		if error != ZIP_ER_OK {
			throw ZUnzipError.status(error)
		}
	}

	public init(data: NSData) throws {
		var error: Int32 = 0
		_file = _fmemopen(UnsafeMutableRawPointer(mutating: data.bytes), data.length, "rb")
		if _file == nil { throw ZUnzipError.inMemoryFileAllocation }
		_zip = _zip_open(nil, _file, 0, &error)
		if error != ZIP_ER_OK { throw ZUnzipError.status(error) }
	}

	lazy var fileToIndexDictionary: [String: Int] = {
		var dictionary = [String: Int]()
		if let zip = self._zip {
			let count = zip_get_num_entries(zip, 0)
			for index in 0..<count {
				var stat = zip_stat()
				zip_stat_init(&stat)
				zip_stat_index(zip, zip_uint64_t(index), 0, &stat)
				if let file = String(utf8String: stat.name) {
					dictionary[file] = Int(index)
				}
			}
		}
		return dictionary
	}()

	public var files: [String] {
		return Array(self.fileToIndexDictionary.keys)
	}

	public func data(forFile file: String) -> NSData? {
		var data: NSData? = nil
		if let zip = self._zip, let index = self.fileToIndexDictionary[file] {
			var stat = zip_stat()
			zip_stat_init(&stat)
			zip_stat_index(zip, zip_uint64_t(index), 0, &stat)
			var buffer = [UInt8](repeating: 0, count: Int(stat.size))
			let zipFile = zip_fopen_index(zip, zip_uint64_t(index), 0)
			zip_fread(zipFile, &buffer, stat.size);
			data = NSData(bytes: buffer, length: Int(stat.size))
			zip_fclose(zipFile)
		}
		return data
	}

	public subscript(file: String) -> NSData? {
		return self.data(forFile: file)
	}

	deinit {
		if let zip = self._zip {
			zip_close(zip)
		}
		if let file = self._file {
			fclose(file)
		}
	}

}

