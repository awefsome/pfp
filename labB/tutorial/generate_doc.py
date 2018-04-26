import os
import setuptools
from sphinx.setup_command import BuildDoc
SCRIPT_DIR = os.path.dirname(os.path.realpath(os.path.abspath(__file__)))

def run_setuptools_for_docs():
    setup_config = {
        "name": "PFP Tutorial",
        "version": "1.0",
        "cmdclass": {'build_sphinx': BuildDoc}
    }

    setup_config["script_args"] = ["build_sphinx",
                                   "--source-dir", os.path.join(SCRIPT_DIR, "source"),
                                   "--build-dir", os.path.join(SCRIPT_DIR, "build"),
                                   "--builder", ["singlehtml", "pdf"]]
    setuptools.setup(**setup_config)

if __name__ == "__main__":
    run_setuptools_for_docs()
