#!/usr/bin/env python3
import json
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
TERRAFORM_DIR = ROOT / "terraform" / "envs" / "dev"


def terraform_vms():
    try:
        result = subprocess.run(
            ["terraform", f"-chdir={TERRAFORM_DIR}", "output", "-json", "vms"],
            check=True,
            capture_output=True,
            text=True,
        )
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as exc:
        stderr = (exc.stderr or "").strip()
        raise RuntimeError(
            "terraform output failed. Ensure terraform backend is initialized and state exists. "
            f"Command error: {stderr}"
        ) from exc
    except json.JSONDecodeError as exc:
        raise RuntimeError("terraform output returned invalid JSON for 'vms'") from exc


def build_inventory():
    vms = terraform_vms()
    inventory = {
        "_meta": {"hostvars": {}},
        "all": {"children": ["k8s_cluster"]},
        "k8s_cluster": {"children": ["kube_control_plane", "kube_workers"]},
        "kube_control_plane": {"hosts": []},
        "kube_workers": {"hosts": []},
    }

    for name, vm in sorted(vms.items()):
        inventory["_meta"]["hostvars"][name] = {
            "ansible_host": vm["ip"],
            "ansible_user": "ubuntu",
            "ansible_python_interpreter": "/usr/bin/python3",
            "node_ip": vm["ip"],
            "node_role": vm["role"],
        }

        if vm["role"] == "control_plane":
            inventory["kube_control_plane"]["hosts"].append(name)
        else:
            inventory["kube_workers"]["hosts"].append(name)

    return inventory


def main():
    try:
        if len(sys.argv) == 2 and sys.argv[1] == "--list":
            print(json.dumps(build_inventory(), indent=2))
            return
        if len(sys.argv) == 3 and sys.argv[1] == "--host":
            print(json.dumps(build_inventory()["_meta"]["hostvars"].get(sys.argv[2], {})))
            return
        print(json.dumps({}))
    except RuntimeError as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
