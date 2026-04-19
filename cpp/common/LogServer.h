// SPDX-FileCopyrightText: 2022-2026 PCSX2 Dev Team
// SPDX-License-Identifier: GPL-3.0+

#pragma once
#include <string>
#include <cstdint>

namespace LogServer {
    bool Init(const char* host, uint16_t port);
    void Send(const std::string& msg);
    void Shutdown();
}
