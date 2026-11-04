"""Проверка структуры проекта перед отправкой в репозиторий.

Запуск: python scripts/check.py
"""

import json
import plistlib
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
problems: list[str] = []


def check_json(path: Path) -> None:
    try:
        json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:  # noqa: BLE001
        problems.append(f"JSON: {path.relative_to(ROOT)}: {exc}")


def check_plist(path: Path) -> None:
    try:
        with path.open("rb") as fh:
            data = plistlib.load(fh)
        for key in ("CFBundleIdentifier", "CFBundleVersion", "UILaunchScreen"):
            if key not in data:
                problems.append(f"plist: нет ключа {key} в {path.relative_to(ROOT)}")
    except Exception as exc:  # noqa: BLE001
        problems.append(f"plist: {path.relative_to(ROOT)}: {exc}")


def check_yaml(path: Path) -> None:
    try:
        import yaml  # type: ignore
    except ImportError:
        return
    try:
        list(yaml.safe_load_all(path.read_text(encoding="utf-8")))
    except Exception as exc:  # noqa: BLE001
        problems.append(f"YAML: {path.relative_to(ROOT)}: {exc}")


def check_swift_balance(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    stripped = re.sub(r"//[^\n]*", "", text)
    stripped = re.sub(r'"(?:[^"\\\n]|\\.)*"', '""', stripped)
    pairs = {"{": "}", "(": ")", "[": "]"}
    stack: list[str] = []
    for ch in stripped:
        if ch in pairs:
            stack.append(ch)
        elif ch in pairs.values():
            if not stack or pairs[stack.pop()] != ch:
                problems.append(f"Swift: несбалансированные скобки в {path.relative_to(ROOT)}")
                return
    if stack:
        problems.append(f"Swift: несбалансированные скобки в {path.relative_to(ROOT)}")


def main() -> int:
    swift_files = sorted(ROOT.glob("Sources/**/*.swift"))
    if not swift_files:
        problems.append("не найдены .swift файлы")

    for path in ROOT.rglob("*.json"):
        check_json(path)
    for path in ROOT.rglob("*.plist"):
        check_plist(path)
    for path in ROOT.rglob("*.yml"):
        check_yaml(path)
    for path in swift_files:
        check_swift_balance(path)

    icon = ROOT / "Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
    if not icon.exists():
        problems.append("нет иконки AppIcon-1024.png")
    else:
        from PIL import Image

        with Image.open(icon) as img:
            if img.size != (1024, 1024):
                problems.append(f"иконка не 1024x1024, а {img.size}")
            if img.mode != "RGB":
                problems.append(f"иконка должна быть RGB без альфы, сейчас {img.mode}")

    print(f"Swift-файлов: {len(swift_files)}")
    for path in swift_files:
        print(f"  - {path.relative_to(ROOT)}  ({len(path.read_text(encoding='utf-8').splitlines())} строк)")

    if problems:
        print("\nПРОБЛЕМЫ:")
        for item in problems:
            print(f"  ! {item}")
        return 1

    print("\nВсе проверки пройдены.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
