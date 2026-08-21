#!/bin/bash

# This is a formatting script to fix some errors that aren't automatically resolved by swiftlint's autocorrect.

if [[ "$(uname -m)" == arm64 ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
fi

status=0

if command -v swift-format &> /dev/null; then
    # Run swift-format with the committed .swift-format configuration
    if swift-format format -i --recursive --configuration .swift-format ./; then
        echo "Swift files have been formatted successfully!"
    else
        echo "error: swift-format failed"
        status=1
    fi
else
    echo "warning: swift-format not installed, install it using: brew install swift-format"
fi

exit $status
