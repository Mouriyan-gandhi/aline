"""Adds any Swift file under Aline/ that the Xcode project doesn't reference yet to the app
target (file reference, main group entry, Sources build phase). The project uses explicit file
references — see generate_project.py — so new files must be registered here to compile."""
import hashlib
import os
import re

ROOT = os.path.dirname(os.path.abspath(__file__))
PBX = os.path.join(ROOT, "Aline.xcodeproj", "project.pbxproj")
MAIN_GROUP = "21DF6D99A1414587916B3DBF"
SOURCES_PHASE = "BE5BBB570FCD470AB9ACCA55"


def object_id(seed: str) -> str:
    return hashlib.md5(seed.encode()).hexdigest()[:24].upper()


def main() -> None:
    text = open(PBX).read()
    added = []
    for folder, _, files in os.walk(os.path.join(ROOT, "Aline")):
        for name in sorted(files):
            if not name.endswith(".swift"):
                continue
            rel = os.path.relpath(os.path.join(folder, name), ROOT)
            if f"path = {rel};" in text or f'path = "{rel}";' in text:
                continue
            path_value = f'"{rel}"' if re.search(r"[^A-Za-z0-9_./]", rel) else rel
            file_ref, build_file = object_id("ref:" + rel), object_id("build:" + rel)
            text = text.replace(
                "/* End PBXBuildFile section */",
                f"\t\t{build_file} /* {rel} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref} /* {rel} */; }};\n"
                "/* End PBXBuildFile section */",
            )
            text = text.replace(
                "/* End PBXFileReference section */",
                f"\t\t{file_ref} /* {rel} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; "
                f"path = {path_value}; sourceTree = \"<group>\"; }};\n/* End PBXFileReference section */",
            )
            text = re.sub(
                rf"({MAIN_GROUP} = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = \(\n)",
                lambda m: m.group(1) + f"\t\t\t\t{file_ref} /* {rel} */,\n",
                text,
            )
            text = re.sub(
                rf"({SOURCES_PHASE} /\* Sources \*/ = {{\n\t\t\tisa = PBXSourcesBuildPhase;\n\t\t\tbuildActionMask = \d+;\n\t\t\tfiles = \(\n)",
                lambda m: m.group(1) + f"\t\t\t\t{build_file} /* {rel} in Sources */,\n",
                text,
            )
            added.append(rel)
    open(PBX, "w").write(text)
    print("\n".join(added) or "nothing to add")


if __name__ == "__main__":
    main()
