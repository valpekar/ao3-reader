#!/bin/bash
find Build ".dSYM" | xargs -I \{\} /Applications/Fabric.app/Contents/MacOS/upload-symbols -a f3d6aa0aca6194181dd40e788db0d0f1b676ca2b -p ios \{\}
