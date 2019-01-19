//===-- IRExecutionUnit.h ---------------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef liblldb_IRExecutionUnit_h_
#define liblldb_IRExecutionUnit_h_

#include <atomic>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

#include "llvm/ExecutionEngine/SectionMemoryManager.h"
#include "llvm/IR/Module.h"

#include "lldb/Expression/IRMemoryMap.h"
#include "lldb/Symbol/ObjectFile.h"
#include "lldb/Symbol/SymbolContext.h"
#include "lldb/Utility/DataBufferHeap.h"
#include "lldb/lldb-forward.h"
#include "lldb/lldb-private.h"

namespace llvm {

class Module;
class ExecutionEngine;
class ObjectCache;

} // namespace llvm

namespace lldb_private {

class Status;

//----------------------------------------------------------------------
/// @class IRExecutionUnit IRExecutionUnit.h
/// "lldb/Expression/IRExecutionUnit.h" Contains the IR and, optionally, JIT-
/// compiled code for a module.
///
/// This class encapsulates the compiled version of an expression, in IR form
/// (for interpretation purposes) and in raw machine code form (for execution
/// in the target).
///
/// This object wraps an IR module that comes from the expression parser, and
/// knows how to use the JIT to make it into executable code.  It can then be
/// used as input to the IR interpreter, or the address of the executable code
/// can be passed to a thread plan to run in the target.
///
/// This class creates a subclass of LLVM's SectionMemoryManager, because that
/// is how the JIT emits code.  Because LLDB needs to move JIT-compiled code
/// into the target process, the IRExecutionUnit knows how to copy the emitted
/// code into the target process.
//----------------------------------------------------------------------
class IRExecutionUnit : public std::enable_shared_from_this<IRExecutionUnit>,
                        public IRMemoryMap,
                        public ObjectFileJITDelegate {
public:
  //------------------------------------------------------------------
  /// Constructor
  //------------------------------------------------------------------
  IRExecutionUnit(std::unique_ptr<llvm::LLVMContext> &context_ap,
                  std::unique_ptr<llvm::Module> &module_ap, ConstString &name,
                  const lldb::TargetSP &target_sp, const SymbolContext &sym_ctx,
                  std::vector<std::string> &cpu_features);

  //------------------------------------------------------------------
  /// Destructor
  //------------------------------------------------------------------
  ~IRExecutionUnit() override;

  ConstString GetFunctionName() { return m_name; }

  llvm::Module *GetModule() { return m_module; }

  llvm::Function *GetFunction() {
    return ((m_module != nullptr) ? m_module->getFunction(m_name.AsCString())
                                  : nullptr);
  }

  void GetRunnableInfo(Status &error, lldb::addr_t &func_addr,
                       lldb::addr_t &func_end);

  //------------------------------------------------------------------
  /// Accessors for IRForTarget and other clients that may want binary data
  /// placed on their behalf.  The binary data is owned by the IRExecutionUnit
  /// unless the client explicitly chooses to free it.
  //------------------------------------------------------------------

  lldb::addr_t WriteNow(const uint8_t *bytes, size_t size, Status &error);

  void FreeNow(lldb::addr_t allocation);

  //------------------------------------------------------------------
  /// ObjectFileJITDelegate overrides
  //------------------------------------------------------------------
  lldb::ByteOrder GetByteOrder() const override;

  uint32_t GetAddressByteSize() const override;

  void PopulateSymtab(lldb_private::ObjectFile *obj_file,
                      lldb_private::Symtab &symtab) override;

  void PopulateSectionList(lldb_private::ObjectFile *obj_file,
                           lldb_private::SectionList &section_list) override;

  ArchSpec GetArchitecture() override;

  lldb::ModuleSP GetJITModule();

  lldb::ModuleSP CreateJITModule(const char *name,
                                 const FileSpec *limit_file_ptr = NULL,
                                 uint32_t limit_start_line = 0,
                                 uint32_t limit_end_line = 0);

  //------------------------------------------------------------------
  /// Accessor for the mutex that guards LLVM::getGlobalContext()
  //------------------------------------------------------------------
  static std::recursive_mutex &GetLLVMGlobalContextMutex();

  lldb::addr_t FindSymbol(const ConstString &name);

  void GetStaticInitializers(std::vector<lldb::addr_t> &static_initializers);

  //----------------------------------------------------------------------
  /// @class JittedFunction IRExecutionUnit.h
  /// "lldb/Expression/IRExecutionUnit.h"
  /// Encapsulates a single function that has been generated by the JIT.
  ///
  /// Functions that have been generated by the JIT are first resident in the
  /// local process, and then placed in the target process.  JittedFunction
  /// represents a function possibly resident in both.
  //----------------------------------------------------------------------
  struct JittedEntity {
    ConstString m_name;        ///< The function's name
    lldb::addr_t m_local_addr; ///< The address of the function in LLDB's memory
    lldb::addr_t
        m_remote_addr; ///< The address of the function in the target's memory

    //------------------------------------------------------------------
    /// Constructor
    ///
    /// Initializes class variabes.
    ///
    /// @param[in] name
    ///     The name of the function.
    ///
    /// @param[in] local_addr
    ///     The address of the function in LLDB, or LLDB_INVALID_ADDRESS if
    ///     it is not present in LLDB's memory.
    ///
    /// @param[in] remote_addr
    ///     The address of the function in the target, or LLDB_INVALID_ADDRESS
    ///     if it is not present in the target's memory.
    //------------------------------------------------------------------
    JittedEntity(const char *name,
                 lldb::addr_t local_addr = LLDB_INVALID_ADDRESS,
                 lldb::addr_t remote_addr = LLDB_INVALID_ADDRESS)
        : m_name(name), m_local_addr(local_addr), m_remote_addr(remote_addr) {}
  };

  struct JittedFunction : JittedEntity {
    bool m_external;
    JittedFunction(const char *name, bool external,
                   lldb::addr_t local_addr = LLDB_INVALID_ADDRESS,
                   lldb::addr_t remote_addr = LLDB_INVALID_ADDRESS)
        : JittedEntity(name, local_addr, remote_addr), m_external(external) {}
  };

  struct JittedGlobalVariable : JittedEntity {
    JittedGlobalVariable(const char *name,
                         lldb::addr_t local_addr = LLDB_INVALID_ADDRESS,
                         lldb::addr_t remote_addr = LLDB_INVALID_ADDRESS)
        : JittedEntity(name, local_addr, remote_addr) {}
  };

  const std::vector<JittedFunction> &GetJittedFunctions() {
    return m_jitted_functions;
  }

  const std::vector<JittedGlobalVariable> &GetJittedGlobalVariables() {
    return m_jitted_global_variables;
  }

private:
  //------------------------------------------------------------------
  /// Look up the object in m_address_map that contains a given address, find
  /// where it was copied to, and return the remote address at the same offset
  /// into the copied entity
  ///
  /// @param[in] local_address
  ///     The address in the debugger.
  ///
  /// @return
  ///     The address in the target process.
  //------------------------------------------------------------------
  lldb::addr_t GetRemoteAddressForLocal(lldb::addr_t local_address);

  //------------------------------------------------------------------
  /// Look up the object in m_address_map that contains a given address, find
  /// where it was copied to, and return its address range in the target
  /// process
  ///
  /// @param[in] local_address
  ///     The address in the debugger.
  ///
  /// @return
  ///     The range of the containing object in the target process.
  //------------------------------------------------------------------
  typedef std::pair<lldb::addr_t, uintptr_t> AddrRange;
  AddrRange GetRemoteRangeForLocal(lldb::addr_t local_address);

  //------------------------------------------------------------------
  /// Commit all allocations to the process and record where they were stored.
  ///
  /// @param[in] process
  ///     The process to allocate memory in.
  ///
  /// @return
  ///     True <=> all allocations were performed successfully.
  ///     This method will attempt to free allocated memory if the
  ///     operation fails.
  //------------------------------------------------------------------
  bool CommitAllocations(lldb::ProcessSP &process_sp);

  //------------------------------------------------------------------
  /// Report all committed allocations to the execution engine.
  ///
  /// @param[in] engine
  ///     The execution engine to notify.
  //------------------------------------------------------------------
  void ReportAllocations(llvm::ExecutionEngine &engine);

  //------------------------------------------------------------------
  /// Write the contents of all allocations to the process.
  ///
  /// @param[in] local_address
  ///     The process containing the allocations.
  ///
  /// @return
  ///     True <=> all allocations were performed successfully.
  //------------------------------------------------------------------
  bool WriteData(lldb::ProcessSP &process_sp);

  Status DisassembleFunction(Stream &stream, lldb::ProcessSP &process_sp);

  struct SearchSpec;

  void CollectCandidateCNames(std::vector<SearchSpec> &C_specs,
                              const ConstString &name);

  void CollectCandidateCPlusPlusNames(std::vector<SearchSpec> &CPP_specs,
                                      const std::vector<SearchSpec> &C_specs,
                                      const SymbolContext &sc);

  void CollectFallbackNames(std::vector<SearchSpec> &fallback_specs,
                            const std::vector<SearchSpec> &C_specs);

  lldb::addr_t FindInSymbols(const std::vector<SearchSpec> &specs,
                             const lldb_private::SymbolContext &sc);

  lldb::addr_t FindInRuntimes(const std::vector<SearchSpec> &specs,
                              const lldb_private::SymbolContext &sc);

  lldb::addr_t FindInUserDefinedSymbols(const std::vector<SearchSpec> &specs,
                                        const lldb_private::SymbolContext &sc);

  void ReportSymbolLookupError(const ConstString &name);

  class MemoryManager : public llvm::SectionMemoryManager {
  public:
    MemoryManager(IRExecutionUnit &parent);

    ~MemoryManager() override;

    //------------------------------------------------------------------
    /// Allocate space for executable code, and add it to the m_spaceBlocks
    /// map
    ///
    /// @param[in] Size
    ///     The size of the area.
    ///
    /// @param[in] Alignment
    ///     The required alignment of the area.
    ///
    /// @param[in] SectionID
    ///     A unique identifier for the section.
    ///
    /// @return
    ///     Allocated space.
    //------------------------------------------------------------------
    uint8_t *allocateCodeSection(uintptr_t Size, unsigned Alignment,
                                 unsigned SectionID,
                                 llvm::StringRef SectionName) override;

    //------------------------------------------------------------------
    /// Allocate space for data, and add it to the m_spaceBlocks map
    ///
    /// @param[in] Size
    ///     The size of the area.
    ///
    /// @param[in] Alignment
    ///     The required alignment of the area.
    ///
    /// @param[in] SectionID
    ///     A unique identifier for the section.
    ///
    /// @param[in] IsReadOnly
    ///     Flag indicating the section is read-only.
    ///
    /// @return
    ///     Allocated space.
    //------------------------------------------------------------------
    uint8_t *allocateDataSection(uintptr_t Size, unsigned Alignment,
                                 unsigned SectionID,
                                 llvm::StringRef SectionName,
                                 bool IsReadOnly) override;

    //------------------------------------------------------------------
    /// Called when object loading is complete and section page permissions
    /// can be applied. Currently unimplemented for LLDB.
    ///
    /// @param[out] ErrMsg
    ///     The error that prevented the page protection from succeeding.
    ///
    /// @return
    ///     True in case of failure, false in case of success.
    //------------------------------------------------------------------
    bool finalizeMemory(std::string *ErrMsg) override {
      // TODO: Ensure that the instruction cache is flushed because
      // relocations are updated by dy-load.  See:
      //   sys::Memory::InvalidateInstructionCache
      //   llvm::SectionMemoryManager
      return false;
    }

    void registerEHFrames(uint8_t *Addr, uint64_t LoadAddr,
                          size_t Size) override {}

    virtual void deregisterEHFrames() override {
      return;
    }

    uint64_t getSymbolAddress(const std::string &Name) override;

    void *getPointerToNamedFunction(const std::string &Name,
                                    bool AbortOnFailure = true) override;

  private:
    std::unique_ptr<SectionMemoryManager> m_default_mm_ap; ///< The memory
                                                           ///allocator to use
                                                           ///in actually
                                                           ///creating space.
                                                           ///All calls are
                                                           ///passed through to
                                                           ///it.
    IRExecutionUnit &m_parent; ///< The execution unit this is a proxy for.
  };

  static const unsigned eSectionIDInvalid = (unsigned)-1;

  //----------------------------------------------------------------------
  /// @class AllocationRecord IRExecutionUnit.h
  /// "lldb/Expression/IRExecutionUnit.h" Encapsulates a single allocation
  /// request made by the JIT.
  ///
  /// Allocations made by the JIT are first queued up and then applied in bulk
  /// to the underlying process.
  //----------------------------------------------------------------------
  enum class AllocationKind { Stub, Code, Data, Global, Bytes };

  static lldb::SectionType
  GetSectionTypeFromSectionName(const llvm::StringRef &name,
                                AllocationKind alloc_kind);

  struct AllocationRecord {
    std::string m_name;
    lldb::addr_t m_process_address;
    uintptr_t m_host_address;
    uint32_t m_permissions;
    lldb::SectionType m_sect_type;
    size_t m_size;
    unsigned m_alignment;
    unsigned m_section_id;

    AllocationRecord(uintptr_t host_address, uint32_t permissions,
                     lldb::SectionType sect_type, size_t size,
                     unsigned alignment, unsigned section_id, const char *name)
        : m_name(), m_process_address(LLDB_INVALID_ADDRESS),
          m_host_address(host_address), m_permissions(permissions),
          m_sect_type(sect_type), m_size(size), m_alignment(alignment),
          m_section_id(section_id) {
      if (name && name[0])
        m_name = name;
    }

    void dump(Log *log);
  };

  bool CommitOneAllocation(lldb::ProcessSP &process_sp, Status &error,
                           AllocationRecord &record);

  typedef std::vector<AllocationRecord> RecordVector;
  RecordVector m_records;

  std::unique_ptr<llvm::LLVMContext> m_context_ap;
  std::unique_ptr<llvm::ExecutionEngine> m_execution_engine_ap;
  std::unique_ptr<llvm::ObjectCache> m_object_cache_ap;
  std::unique_ptr<llvm::Module>
      m_module_ap; ///< Holder for the module until it's been handed off
  lldb::ModuleWP m_jit_module_wp;
  llvm::Module *m_module; ///< Owned by the execution engine
  std::vector<std::string> m_cpu_features;
  std::vector<JittedFunction> m_jitted_functions; ///< A vector of all functions
                                                  ///that have been JITted into
                                                  ///machine code
  std::vector<JittedGlobalVariable> m_jitted_global_variables; ///< A vector of
                                                               ///all functions
                                                               ///that have been
                                                               ///JITted into
                                                               ///machine code
  const ConstString m_name;
  SymbolContext m_sym_ctx; ///< Used for symbol lookups
  std::vector<ConstString> m_failed_lookups;

  std::atomic<bool> m_did_jit;

  lldb::addr_t m_function_load_addr;
  lldb::addr_t m_function_end_load_addr;

  bool m_strip_underscore = true; ///< True for platforms where global symbols
                                  ///  have a _ prefix
  bool m_reported_allocations; ///< True after allocations have been reported.
                               ///It is possible that
  ///< sections will be allocated when this is true, in which case they weren't
  ///< depended on by any function.  (Top-level code defining a variable, but
  ///< defining no functions using that variable, would do this.)  If this
  ///< is true, any allocations need to be committed immediately -- no
  ///< opportunity for relocation.
};

} // namespace lldb_private

#endif // liblldb_IRExecutionUnit_h_
