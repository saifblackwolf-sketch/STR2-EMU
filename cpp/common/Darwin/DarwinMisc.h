// SPDX-FileCopyrightText: 2002-2025 PCSX2 Dev Team
// SPDX-License-Identifier: GPL-3.0+

#pragma once
#ifdef __APPLE__

#include <string>
#include <vector>

#include "common/Pcsx2Types.h"

namespace DarwinMisc {
    extern int iPSX2_CRASH_DIAG;
    extern int iPSX2_REC_DIAG;
    extern int iPSX2_FORCE_EE_INTERP;
    extern int iPSX2_FORCE_JIT_VERIFY;
    extern int iPSX2_CALL_TGT_X9;
    extern int iPSX2_CRASH_PACK;
    extern int iPSX2_WX_TRACE;
    extern int iPSX2_CALLPROBE;
    extern int iPSX2_JIT_HLE;        // [P11] JIT modeの HLE enabled/disabled (default=1=enabled, 0=disabled)
    extern int iPSX2_FORCE_JIT;      // [P11] JIT modeforce (1=force, 0=configに従う; SAFE_ONLY not needed)
    extern int iPSX2_IOP_CORE_TYPE;  // [P11] IOP CPU select (-1=EEfollow, 0=psxRecforce, 1=psxIntforce)
    extern int iPSX2_TRACE_EXEC;     // [iPSX2] Instruction Trace (EE/IOP Interpreters)
    
    // [iPSX2] Indirect Branch Probe
    // extern volatile u64 g_last_indirect_target; // Deprecated
    // extern volatile u64 g_last_indirect_site;   // Deprecated
    
    struct IndirectEvent {
        u64 site;
        u64 target;
        u32 insn;
        u32 kind; // 1=BLR, 2=BR, 3=RET
        u64 pad;  // Pad to 32 bytes (stride used by ASM)
    };
    extern volatile IndirectEvent g_ie[8];
    extern volatile u32 g_ie_idx;

    // [iPSX2] W^X Trace Event
    struct WXTraceEvent {
        u64 tid;
        u64 caller;
        int write; // 0=RX, 1=RW
        int depth;
    };
    extern volatile WXTraceEvent g_wx_events[16];
    extern volatile u32 g_wx_idx;

    // [iPSX2] JIT Call Emit Probe
    struct EmitEvent {
        u64 pc;      // Guest PC or nearby tag
        u64 ptr;     // Target address
        u64 sym;     // Symbol address if resolved (or 0)
        u64 tid;     // Thread ID
        u64 caller;  // Caller of armEmitCall
    };
    extern volatile EmitEvent g_emit_events[32];
    extern volatile u32 g_emit_idx;

    // [iPSX2] W^X State Tracker (0=RX, 1=RW)
    extern volatile int g_jit_write_state;
    // [iPSX2] Recompiler Stage Tracker
    extern volatile int g_rec_stage;

    void SetCrashLogFD(int fd);

struct CPUClass {
	std::string name;
	u32 num_physical;
	u32 num_logical;
};


	// JIT Context for Signal Handler
	void SetJitRange(void* base, size_t size);
	void SetLastGuestPC(u32 pc);
	void SetLastRecPtr(void* ptr);

    // JIT Context Getters
    uintptr_t GetJitBase();
    uintptr_t GetJitEnd();
    u32 GetLastGuestPC();
    uintptr_t GetLastRecPtr();

	std::vector<CPUClass> GetCPUClasses();

    // [iPSX2] DYLD Main Base Getter
    void LogDyldMain();

    // [iPSX2] JIT Block Mapping Service
    void RecordJitBlock(u32 guest_pc, void* recptr, u32 size);
    bool FindJitBlock(uintptr_t site, u32* out_guest_pc, void** out_recptr);

    // [P42] JIT availability detection for real iOS devices
    bool IsJITAvailable();

    // [P43] iOS 26 Dual-Mapping JIT
    enum class JitMode {
        Simulator,    // MAP_JIT + pthread_jit_write_protect_np
        LuckTXM,      // brk #0x69 + vm_remap dual-mapping (iOS 26, A15+)
        LuckNoTXM,    // vm_remap dual-mapping (iOS 26, non-TXM)
        Legacy,        // mprotect toggle (iOS 18 and earlier)
    };

    JitMode DetectJitMode();
    JitMode GetJitMode();

    // RW offset for dual-mapping: write to (rx_ptr + offset), execute at rx_ptr
    // Simulator: 0 (same address for both)
    // Real device dual-mapping: rw_base - rx_base
    extern ptrdiff_t g_code_rw_offset;
    extern uintptr_t g_code_rw_base; // RW region start (0 if no dual-mapping)
    extern size_t    g_code_rw_size; // RW region size

    // Allocate executable memory with dual-mapping support
    // Returns RX pointer. For writing, use (rx_ptr + g_code_rw_offset).
    void* MmapCodeDualMap(size_t size);

    // Free dual-mapped code memory
    void MunmapCodeDualMap(void* rx_ptr, size_t size);

    // [P49] Legacy lazy toggle: flip RW→RX + icache flush before JIT dispatch.
    // Call this once before entering JIT code (e.g., in recExecute dispatcher).
    // No-op on non-Legacy modes.
    void LegacyEnsureExecutable();

}

#else

#include <cstddef>
#include <cstdint>
#include <string>
#include <vector>

namespace DarwinMisc {
    inline int iPSX2_CRASH_DIAG = 0;
    inline int iPSX2_REC_DIAG = 0;
    inline int iPSX2_FORCE_EE_INTERP = 0;
    inline int iPSX2_FORCE_JIT_VERIFY = 0;
    inline int iPSX2_CALL_TGT_X9 = 0;
    inline int iPSX2_CRASH_PACK = 0;
    inline int iPSX2_WX_TRACE = 0;
    inline int iPSX2_CALLPROBE = 0;
    inline int iPSX2_JIT_HLE = 0;
    inline int iPSX2_FORCE_JIT = 0;
    inline int iPSX2_IOP_CORE_TYPE = -1;
    inline int iPSX2_TRACE_EXEC = 0;

    struct IndirectEvent {
        std::uint64_t site = 0;
        std::uint64_t target = 0;
        std::uint32_t insn = 0;
        std::uint32_t kind = 0;
        std::uint64_t pad = 0;
    };
    inline volatile IndirectEvent g_ie[8] = {};
    inline volatile std::uint32_t g_ie_idx = 0;

    struct WXTraceEvent {
        std::uint64_t tid = 0;
        std::uint64_t caller = 0;
        int write = 0;
        int depth = 0;
    };
    inline volatile WXTraceEvent g_wx_events[16] = {};
    inline volatile std::uint32_t g_wx_idx = 0;

    struct EmitEvent {
        std::uint64_t pc = 0;
        std::uint64_t ptr = 0;
        std::uint64_t sym = 0;
        std::uint64_t tid = 0;
        std::uint64_t caller = 0;
    };
    inline volatile EmitEvent g_emit_events[32] = {};
    inline volatile std::uint32_t g_emit_idx = 0;

    inline volatile int g_jit_write_state = 0;
    inline volatile int g_rec_stage = 0;

    inline void SetCrashLogFD(int) {}

    struct CPUClass {
        std::string name;
        u32 num_physical = 0;
        u32 num_logical = 0;
    };

    inline void SetJitRange(void*, size_t) {}
    inline void SetLastGuestPC(u32) {}
    inline void SetLastRecPtr(void*) {}

    inline uintptr_t GetJitBase() { return 0; }
    inline uintptr_t GetJitEnd() { return 0; }
    inline u32 GetLastGuestPC() { return 0; }
    inline uintptr_t GetLastRecPtr() { return 0; }

    inline std::vector<CPUClass> GetCPUClasses() { return {}; }

    inline void LogDyldMain() {}

    inline void RecordJitBlock(u32, void*, u32) {}
    inline bool FindJitBlock(uintptr_t, u32*, void**) { return false; }

    inline bool IsJITAvailable() { return false; }

    enum class JitMode {
        Simulator,
        LuckTXM,
        LuckNoTXM,
        Legacy,
    };

    inline JitMode DetectJitMode() { return JitMode::Legacy; }
    inline JitMode GetJitMode() { return JitMode::Legacy; }

    inline ptrdiff_t g_code_rw_offset = 0;
    inline uintptr_t g_code_rw_base = 0;
    inline size_t g_code_rw_size = 0;

    inline void* MmapCodeDualMap(size_t) { return nullptr; }
    inline void MunmapCodeDualMap(void*, size_t) {}
    inline void LegacyEnsureExecutable() {}
}

#endif
