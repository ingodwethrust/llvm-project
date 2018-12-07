//===- SymbolRecordHelpers.cpp ----------------------------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "llvm/DebugInfo/CodeView/SymbolRecordHelpers.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/DebugInfo/CodeView/SymbolDeserializer.h"

using namespace llvm;
using namespace llvm::codeview;

template <typename RecordT> RecordT createRecord(const CVSymbol &sym) {
  RecordT record(static_cast<SymbolRecordKind>(sym.kind()));
  cantFail(SymbolDeserializer::deserializeAs<RecordT>(sym, record));
  return record;
}

uint32_t
llvm::codeview::getScopeEndOffset(const llvm::codeview::CVSymbol &Sym) {
  assert(symbolOpensScope(Sym.kind()));
  switch (Sym.kind()) {
  case SymbolKind::S_GPROC32:
  case SymbolKind::S_LPROC32:
  case SymbolKind::S_GPROC32_ID:
  case SymbolKind::S_LPROC32_ID:
  case SymbolKind::S_LPROC32_DPC:
  case SymbolKind::S_LPROC32_DPC_ID: {
    ProcSym Proc = createRecord<ProcSym>(Sym);
    return Proc.End;
  }
  case SymbolKind::S_BLOCK32: {
    BlockSym Block = createRecord<BlockSym>(Sym);
    return Block.End;
  }
  case SymbolKind::S_THUNK32: {
    Thunk32Sym Thunk = createRecord<Thunk32Sym>(Sym);
    return Thunk.End;
  }
  case SymbolKind::S_INLINESITE: {
    InlineSiteSym Site = createRecord<InlineSiteSym>(Sym);
    return Site.End;
  }
  default:
    assert(false && "Unknown record type");
    return 0;
  }
}