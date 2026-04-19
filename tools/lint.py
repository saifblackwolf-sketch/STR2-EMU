#!/usr/bin/env python3
import os
import subprocess
import sys
import argparse

def check_command(command):
    try:
        subprocess.run([command, "--version"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except FileNotFoundError:
        return False

def get_files(directory, extensions):
    matched_files = []
    for root, dirs, files in os.walk(directory):
        if "3rdparty" in root or "build" in root:
            continue
        for file in files:
            if any(file.endswith(ext) for ext in extensions):
                matched_files.append(os.path.join(root, file))
    return matched_files

def get_modified_files(extensions):
    try:
        output = subprocess.check_output(["git", "diff", "--name-only", "HEAD"], encoding="utf-8")
        files = output.splitlines()
        return [f for f in files if any(f.endswith(ext) for ext in extensions) and os.path.exists(f)]
    except Exception:
        return []

def run_clang_tidy(files):
    if not files:
        return
    print(f"--- Running clang-tidy on {len(files)} C++ files ---")
    
    # Process files in batches to avoid command line length limits and crashes
    batch_size = 20
    for i in range(0, len(files), batch_size):
        batch = files[i:i + batch_size]
        print(f"Processing batch {i//batch_size + 1}/{(len(files) + batch_size - 1)//batch_size}...")
        cmd = ["clang-tidy"] + batch + ["--", "-Icpp", "-Icpp/common", "-Icpp/pcsx2"]
        subprocess.run(cmd)

def run_swiftlint(directory):
    # Try swiftlint first (it has experimental Windows support now)
    if check_command("swiftlint"):
        print(f"--- Running swiftlint on {directory} ---")
        config_arg = ["--config", ".swiftlint.yml"] if os.path.exists(".swiftlint.yml") else []
        subprocess.run(["swiftlint", "lint", directory] + config_arg)
    # Fallback to 'swift format' which is bundled with Swift 6.0+ toolchain
    elif check_command("swift"):
        print(f"--- Running 'swift format' on {directory} ---")
        # 'swift format lint' checks for issues without fixing them
        subprocess.run(["swift", "format", "lint", "--recursive", "--ignore-unparsable-files", directory])
    else:
        print("Warning: Neither 'swiftlint' nor 'swift format' found. Swift linting skipped.")

def main():
    parser = argparse.ArgumentParser(description="iPSX2 Linting Tool")
    parser.add_argument("--diff", action="store_true", help="Lint only modified files")
    parser.add_argument("--all", action="store_true", help="Lint all files (default)")
    args = parser.parse_args()

    has_clang_tidy = check_command("clang-tidy")
    
    # We check for either swiftlint or the 'swift' tool (for 'swift format')
    has_swift_tool = check_command("swiftlint") or check_command("swift")

    if not has_clang_tidy:
        print("Warning: clang-tidy not found in PATH. C++ linting skipped.")
    if not has_swift_tool:
        print("Warning: No Swift linting tool found (swiftlint or swift format). Swift linting skipped.")

    if not has_clang_tidy and not has_swift_tool:
        print("Error: No linting tools found. Please install LLVM (for clang-tidy) or the Swift Toolchain.")
        sys.exit(1)

    cpp_extensions = [".cpp", ".h", ".mm", ".h"]
    
    if args.diff:
        cpp_files = get_modified_files(cpp_extensions)
    elif args.all:
        cpp_files = get_files("cpp", cpp_extensions)
    else:
        cpp_files = []
        print("Tip: Run with --diff to lint modified files or --all to lint everything (not recommended for C++ due to output volume).")

    if has_clang_tidy and cpp_files:
        if not os.path.exists(".clang-tidy"):
            print("Warning: .clang-tidy file not found. Using default settings.")
        run_clang_tidy(cpp_files)

    if has_swift_tool:
        run_swiftlint("swift")

if __name__ == "__main__":
    main()
