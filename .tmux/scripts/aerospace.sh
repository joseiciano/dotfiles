#!/bin/bash
# Get visible workspaces and join them with a separator
aerospace list-workspaces --monitor all --visible | tr '\n' ' ' | sed 's/ $//'
