#!/usr/bin/env bash
exec xvfb-run -a godot --audio-driver Dummy "$@"
