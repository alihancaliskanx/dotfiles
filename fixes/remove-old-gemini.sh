#!/bin/bash
# Removes the old gemini-cli installed via mise

echo "Removing old gemini-cli via mise..."

if command -v mise &> /dev/null; then
    yes | mise uninstall gemini 2>/dev/null
    mise unuse -g gemini 2>/dev/null
    echo "Removed from mise."
fi

if [ -f ~/.local/bin/gemini ]; then
    rm -f ~/.local/bin/gemini
    echo "Removed wrapper script at ~/.local/bin/gemini"
fi

echo "Old gemini-cli removal complete."
