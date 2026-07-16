from pathlib import Path
import shutil


ROOT_DIR = Path(__file__).resolve().parents[1]
FUNCTIONS_DIR = ROOT_DIR / "app" / "functions"
DIST_DIR = FUNCTIONS_DIR / ".dist"
SHARED_DIR = FUNCTIONS_DIR / "shared"

FUNCTION_NAMES = [
    "list_requests",
    "create_request",
    "get_request_detail",
    "update_request_status",
    "pre_token_generation",
]


def reset_directory(path: Path) -> None:
    if path.exists():
        shutil.rmtree(path)
    path.mkdir(parents=True, exist_ok=True)


def copy_file(source: Path, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, destination)


def build_function_package(function_name: str) -> None:
    source_dir = FUNCTIONS_DIR / function_name
    package_dir = DIST_DIR / function_name

    if not source_dir.exists():
        raise FileNotFoundError(f"Function directory was not found: {source_dir}")

    reset_directory(package_dir)

    handler_file = source_dir / "handler.py"
    requirements_file = source_dir / "requirements.txt"

    if not handler_file.exists():
        raise FileNotFoundError(f"Handler file was not found: {handler_file}")

    copy_file(handler_file, package_dir / "handler.py")

    if requirements_file.exists():
        copy_file(requirements_file, package_dir / "requirements.txt")

    if SHARED_DIR.exists():
        shutil.copytree(SHARED_DIR, package_dir / "shared", dirs_exist_ok=True)

    print(f"Built package directory: {package_dir}")


def main() -> None:
    DIST_DIR.mkdir(parents=True, exist_ok=True)

    for function_name in FUNCTION_NAMES:
        build_function_package(function_name)

    print("Lambda packaging scaffold completed.")


if __name__ == "__main__":
    main()
