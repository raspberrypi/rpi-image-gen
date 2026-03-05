import sys

def log_error(message: str) -> None:
    print(f"Error: {message}", file=sys.stderr)


def log_warning(message: str) -> None:
    print(f"Warning: {message}", file=sys.stderr)


def log_success(message: str) -> None:
    print(f"✓ {message}")


def log_failure(message: str) -> None:
    print(f"✗ {message}")


def log_info(message: str) -> None:
    print(message)


class LogConfig:
    quiet = False
    verbose = False

    @classmethod
    def set_quiet(cls, quiet: bool = True):
        cls.quiet = quiet

    @classmethod
    def set_verbose(cls, verbose: bool = True):
        cls.verbose = verbose
