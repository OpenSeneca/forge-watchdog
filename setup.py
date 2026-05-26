#!/usr/bin/env python3
"""
Forge Watchdog - Monitors Forge connectivity and auto-deploys Squad Dashboard
"""

from setuptools import setup, find_packages

setup(
    name="forge-watchdog",
    version="1.0.0",
    description="Monitors Forge connectivity and auto-deploys Squad Dashboard on recovery",
    long_description=open("README.md").read(),
    long_description_content_type="text/markdown",
    author="Archimedes",
    author_email="archimedes@openseneca.org",
    url="https://github.com/OpenSeneca/forge-watchdog",
    license="MIT",
    py_modules=["main"],
    entry_points={
        "console_scripts": [
            "forge-watchdog=main:main",
        ],
    },
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
    ],
    python_requires=">=3.6",
)