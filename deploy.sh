#!/bin/bash

killall IPAInputMethod
killall IPAInputMethod

rm -rf '/Library/Input Methods/IPAInputMethod.app' &&
cp -pRv 'build/Debug/IPAInputMethod.app' '/Library/Input Methods/'
