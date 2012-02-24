#!/bin/sh


logw "Begin to test memory..."
infow 0 MEM "Testing, please wait.."

memtester 4M 1
RESULT=$?

infow 0 MEM "result $RESULT"
logw "Memory test result: $RESULT"







