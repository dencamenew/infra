#!/usr/bin/env python3
"""
Sanity-check that the dynamic Terraform inventory produced the expected
control-plane and worker hosts before Ansible tries to use it.

Usage: check_inventory.py <path-to-ansible-inventory-json>
"""
import json
import sys


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: check_inventory.py <inventory.json>", file=sys.stderr)
        return 2

    with open(sys.argv[1], "r", encoding="utf-8") as f:
        inv = json.load(f)

    control_plane = inv.get("kube_control_plane", {}).get("hosts", [])
    workers = inv.get("kube_workers", {}).get("hosts", [])

    if not control_plane or not workers:
        print(
            f"Inventory check failed. "
            f"kube_control_plane={control_plane}, kube_workers={workers}",
            file=sys.stderr,
        )
        return 1

    print(f"Inventory OK. control_plane={control_plane}, workers={workers}")
    return 0


if __name__ == "__main__":
    sys.exit(main())