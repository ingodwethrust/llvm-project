set(LLVM_LINK_COMPONENTS
  AsmParser
  BitReader
  BitWriter
  Core
  Support
  )

add_llvm_unittest(BitcodeTests
  BitReaderTest.cpp
  RecordLayout.cpp
  DataLayoutUpgradeTest.cpp
  )
