#!/usr/bin/env python3
"""
Bump the `newTag` of every entry in k8s/base/kustomization.yml's `images:`
transformer list. This is the only file CI needs to touch — kustomize
applies the tag override to every manifest that references a matching
image name, so nextapp.yml / fastapi.yml / jobs.yml never change.

Usage: bump_kustomize_image_tags.py <tag> [path/to/kustomization.yml]

Requires: pip install ruamel.yaml
"""
import sys
from pathlib import Path

from ruamel.yaml import YAML


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: bump_kustomize_image_tags.py <tag> [kustomization.yml]", file=sys.stderr)
        return 2

    new_tag = sys.argv[1]
    root_dir = Path(__file__).resolve().parent.parent
    kustomization_path = (
        Path(sys.argv[2]) if len(sys.argv) > 2 else root_dir / "k8s" / "base" / "kustomization.yml"
    )

    if not kustomization_path.is_file():
        print(f"{kustomization_path} not found", file=sys.stderr)
        return 1

    yaml = YAML()
    yaml.preserve_quotes = True
    yaml.width = 4096
    yaml.indent(mapping=2, sequence=4, offset=2)

    with kustomization_path.open("r", encoding="utf-8") as f:
        doc = yaml.load(f)

    images = doc.get("images")
    if not images:
        print(f"No `images:` section found in {kustomization_path}", file=sys.stderr)
        return 1

    changed = []
    for entry in images:
        old_tag = entry.get("newTag")
        if old_tag != new_tag:
            changed.append((entry.get("name"), old_tag, new_tag))
        entry["newTag"] = new_tag

    if not changed:
        print(f"All images already at tag '{new_tag}', nothing to do")
        return 0

    with kustomization_path.open("w", encoding="utf-8") as f:
        yaml.dump(doc, f)

    print(f"Updated {kustomization_path}:")
    for name, old_tag, tag in changed:
        print(f"  {name}: {old_tag} -> {tag}")

    return 0


if __name__ == "__main__":
    sys.exit(main())