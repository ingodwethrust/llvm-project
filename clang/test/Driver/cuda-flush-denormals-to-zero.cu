// Checks that cuda compilation does the right thing when passed
// -fcuda-flush-denormals-to-zero. This should be translated to
// -fdenormal-fp-math-f32=preserve-sign

// RUN: %clang -no-canonical-prefixes -### -target x86_64-linux-gnu -c -march=haswell --cuda-gpu-arch=sm_20 -fcuda-flush-denormals-to-zero -nocudainc -nocudalib %s 2>&1 | FileCheck -check-prefix=FTZ %s
// RUN: %clang -no-canonical-prefixes -### -target x86_64-linux-gnu -c -march=haswell --cuda-gpu-arch=sm_20 -fno-cuda-flush-denormals-to-zero -nocudainc -nocudalib %s 2>&1 | FileCheck -check-prefix=NOFTZ %s
// RUN: %clang -no-canonical-prefixes -### -target x86_64-linux-gnu -c -march=haswell --cuda-gpu-arch=sm_70 -fcuda-flush-denormals-to-zero -nocudainc -nocudalib %s 2>&1 | FileCheck -check-prefix=FTZ %s
// RUN: %clang -no-canonical-prefixes -### -target x86_64-linux-gnu -c -march=haswell --cuda-gpu-arch=sm_70 -fno-cuda-flush-denormals-to-zero -nocudainc -nocudalib %s 2>&1 | FileCheck -check-prefix=NOFTZ %s

// Test explicit argument, with CUDA offload kind
// RUN: %clang -no-canonical-prefixes -### -target x86_64-linux-gnu -c -march=haswell --cuda-gpu-arch=gfx803 -fcuda-flush-denormals-to-zero -nocudainc -nogpulib %s 2>&1 | FileCheck -check-prefix=FTZ %s
// RUN: %clang -no-canonical-prefixes -### -target x86_64-linux-gnu -c -march=haswell --cuda-gpu-arch=gfx803 -fno-cuda-flush-denormals-to-zero -nocudainc -nogpulib %s 2>&1 | FileCheck -check-prefix=NOFTZ %s

// Test explicit argument, with HIP offload kind
// RUN: %clang -x hip -no-canonical-prefixes -### -target x86_64-linux-gnu -c -march=haswell --cuda-gpu-arch=gfx803 -fcuda-flush-denormals-to-zero -nocudainc -nogpulib %s 2>&1 | FileCheck -check-prefix=FTZ %s
// RUN: %clang -x hip -no-canonical-prefixes -### -target x86_64-linux-gnu -c -march=haswell --cuda-gpu-arch=gfx803 -fno-cuda-flush-denormals-to-zero -nocudainc -nogpulib %s 2>&1 | FileCheck -check-prefix=NOFTZ %s

// RUN: %clang -x hip -no-canonical-prefixes -### -target x86_64-linux-gnu -c -march=haswell --cuda-gpu-arch=gfx900 -fcuda-flush-denormals-to-zero -nocudainc -nogpulib %s 2>&1 | FileCheck -check-prefix=FTZ %s
// RUN: %clang -x hip -no-canonical-prefixes -### -target x86_64-linux-gnu -c -march=haswell --cuda-gpu-arch=gfx900 -fno-cuda-flush-denormals-to-zero -nocudainc -nogpulib %s 2>&1 | FileCheck -check-prefix=NOFTZ %s

// Test the default changing with no argument based on the subtarget in HIP mode
// RUN: %clang -x hip -no-canonical-prefixes -### -target x86_64-linux-gnu -c -march=haswell --cuda-gpu-arch=gfx803 -nocudainc -nogpulib %s 2>&1 | FileCheck -check-prefix=FTZ %s
// RUN: %clang -x hip -no-canonical-prefixes -### -target x86_64-linux-gnu -c -march=haswell --cuda-gpu-arch=gfx900 -nocudainc -nogpulib %s 2>&1 | FileCheck -check-prefix=NOFTZ %s


// Test multiple offload archs with different defaults.
// RUN: %clang -x hip -no-canonical-prefixes -### -target x86_64-linux-gnu -c -march=haswell --cuda-gpu-arch=gfx803 --cuda-gpu-arch=gfx900 -nocudainc -nogpulib %s 2>&1 | FileCheck -check-prefix=MIXED-DEFAULT-MODE %s
// RUN: %clang -x hip -no-canonical-prefixes -### -target x86_64-linux-gnu -c -march=haswell -fcuda-flush-denormals-to-zero --cuda-gpu-arch=gfx803 --cuda-gpu-arch=gfx900 -nocudainc -nogpulib %s 2>&1 | FileCheck -check-prefix=FTZX2 %s
// RUN: %clang -x hip -no-canonical-prefixes -### -target x86_64-linux-gnu -c -march=haswell -fno-cuda-flush-denormals-to-zero --cuda-gpu-arch=gfx803 --cuda-gpu-arch=gfx900 -nocudainc -nogpulib %s 2>&1 | FileCheck -check-prefix=NOFTZ %s


// CPUFTZ-NOT: -fdenormal-fp-math

// FTZ-NOT: -fdenormal-fp-math-f32=
// FTZ: "-fdenormal-fp-math-f32=preserve-sign,preserve-sign"

// The default of ieee is omitted
// NOFTZ-NOT: "-fdenormal-fp-math"
// NOFTZ-NOT: "-fdenormal-fp-math-f32"

// MIXED-DEFAULT-MODE-NOT: -denormal-fp-math
// MIXED-DEFAULT-MODE: "-fdenormal-fp-math-f32=preserve-sign,preserve-sign"
// MIXED-DEFAULT-MODE-SAME: "-target-cpu" "gfx803"
// MIXED-DEFAULT-MODE-NOT: -denormal-fp-math

// FTZX2: "-fdenormal-fp-math-f32=preserve-sign,preserve-sign"
// FTZX2-SAME: "-target-cpu" "gfx803"
// FTZX2: "-fdenormal-fp-math-f32=preserve-sign,preserve-sign"
// FTZX2-SAME: "-target-cpu" "gfx900"
