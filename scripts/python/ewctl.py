#!/usr/bin/env python3
"""
The Sacred Kernel of EasyWay Control (Python Edition).
Implements the same contract as ewctl.ps1 but for Python modules.
"""

import argparse
import json
import importlib 
import pkgutil
import sys
import os
from io import StringIO
import contextlib

# --- 1. Helper: Output Capture ("The Silencer") ---
@contextlib.contextmanager
def capture_output(json_mode=False):
    if not json_mode:
        yield sys.stdout
        return

    # In JSON mode, capture everything to prevent pollution
    capture_out, capture_err = StringIO(), StringIO()
    original_out, original_err = sys.stdout, sys.stderr
    try:
        sys.stdout, sys.stderr = capture_out, capture_err
        yield sys.stdout
    except Exception as e:
        # If kernel crashes, ensure we restore stdout to print error json
        sys.stdout, sys.stderr = original_out, original_err
        raise e
    finally:
        sys.stdout, sys.stderr = original_out, original_err

# --- 2. Module Discovery ---
def discover_modules():
    modules = []
    # Dynamic path based on script location
    script_dir = os.path.dirname(os.path.abspath(__file__))
    modules_dir = os.path.join(script_dir, "modules", "ewctl")
    
    # Ensure modules dir is in path to import
    if script_dir not in sys.path:
        sys.path.insert(0, script_dir)

    # Walk modules
    for finder, name, ispkg in pkgutil.iter_modules([modules_dir]):
        try:
            full_name = f"modules.ewctl.{name}"
            mod = importlib.import_module(full_name)
            
            # Duck Typing Capabilities
            capabilities = {
                "Name": name,
                "CanCheck": hasattr(mod, "get_diagnosis"),
                "CanPlan": hasattr(mod, "get_prescription"),
                "CanFix": hasattr(mod, "invoke_treatment"),
                "ModuleObj": mod
            }
            modules.append(capabilities)
        except Exception as e:
            # We might log this to stderr if in human mode, or ignore
            pass
            
    return modules

# --- 3. Execution Engine ---
def main():
    parser = argparse.ArgumentParser(description="ewctl Python Kernel")
    parser.add_argument("command", choices=["check", "fix", "plan", "describe"])
    parser.add_argument("--json", action="store_true", help="Output pure JSON")
    args = parser.parse_args()

    results = []
    modules = discover_modules()

    # Safety Wrapper
    try:
        with capture_output(args.json):
            if args.command == "check":
                for m in modules:
                    if m["CanCheck"]:
                        # call get_diagnosis
                        diag = m["ModuleObj"].get_diagnosis()
                        # Tag with module name
                        for d in diag:
                            d["Module"] = m["Name"]
                        results.extend(diag)

            elif args.command == "plan":
                for m in modules:
                    if m["CanPlan"]:
                        plans = m["ModuleObj"].get_prescription()
                        for p in plans:
                            p["Module"] = m["Name"]
                        results.extend(plans)
            
            elif args.command == "fix":
                # In fix, normally we ask confirmation unless forced. 
                # For PoC, we skip confirmation logic logic implementation details for brevity
                for m in modules:
                    if m["CanFix"]:
                        res = m["ModuleObj"].invoke_treatment()
                        results.append({
                            "Module": m["Name"],
                            "Action": "Fix",
                            "Result": res
                        })

    except Exception as e:
        # Kernel level crash
        results.append({
            "Status": "Error",
            "Message": f"Kernel Crash: {str(e)}",
            "Context": "Kernel"
        })

    # --- 4. Render ---
    if args.command == "describe":
        # Describe is meta, just dump module capabilities
        clean_mods = [{k:v for k,v in m.items() if k != "ModuleObj"} for m in modules]
        print(json.dumps(clean_mods, indent=2))
        return

    if args.json:
        print(json.dumps(results, separators=(',', ':'))) # Compact JSON
    else:
        # Simple Human Render
        print(f"--- ewctl (python) {args.command.upper()} ---")
        for r in results:
            status = r.get("Status", "INFO")
            mod = r.get("Module", "?")
            msg = r.get("Message", "")
            print(f"[{status}]\t[{mod}]\t{msg}")

if __name__ == "__main__":
    main()
