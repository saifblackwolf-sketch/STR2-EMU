// SPDX-FileCopyrightText: 2022-2026 PCSX2 Dev Team
// SPDX-License-Identifier: GPL-3.0+

#include "common/Console.h"
#include <string>
#include <fstream>
#include <mutex>

#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
typedef int socklen_t;
#else
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <netdb.h>
#define SOCKET int
#define INVALID_SOCKET (-1)
#define SOCKET_ERROR (-1)
#define closesocket close
#endif

// Simple TCP log server client for demonstration. In production, use async and error handling.
namespace LogServer {
    static std::mutex log_mutex;
    static SOCKET log_socket = INVALID_SOCKET;
    static bool initialized = false;
    static std::string last_host;
    static uint16_t last_port = 0;

    bool Init(const char* host, uint16_t port) {
        std::lock_guard<std::mutex> lock(log_mutex);
        if (initialized && log_socket != INVALID_SOCKET) return true;
#ifdef _WIN32
        WSADATA wsaData;
        if (WSAStartup(MAKEWORD(2,2), &wsaData) != 0) return false;
#endif
        log_socket = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
        if (log_socket == INVALID_SOCKET) return false;
        sockaddr_in server_addr = {};
        server_addr.sin_family = AF_INET;
        server_addr.sin_port = htons(port);
        inet_pton(AF_INET, host, &server_addr.sin_addr);
        if (connect(log_socket, (sockaddr*)&server_addr, sizeof(server_addr)) == SOCKET_ERROR) {
            closesocket(log_socket);
            log_socket = INVALID_SOCKET;
            initialized = false;
            return false;
        }
        initialized = true;
        last_host = host;
        last_port = port;
        return true;
    }

    void Send(const std::string& msg) {
        std::lock_guard<std::mutex> lock(log_mutex);
        if (log_socket == INVALID_SOCKET && initialized && !last_host.empty()) {
            // Try to reconnect
            Init(last_host.c_str(), last_port);
        }
        if (log_socket != INVALID_SOCKET) {
            int sent = send(log_socket, msg.c_str(), (int)msg.size(), 0);
            if (sent == SOCKET_ERROR) {
                closesocket(log_socket);
                log_socket = INVALID_SOCKET;
                initialized = false;
            }
        }
    }

    void Shutdown() {
        std::lock_guard<std::mutex> lock(log_mutex);
        if (log_socket != INVALID_SOCKET) {
            closesocket(log_socket);
            log_socket = INVALID_SOCKET;
#ifdef _WIN32
            WSACleanup();
#endif
            initialized = false;
        }
    }
}
