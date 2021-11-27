# Pong
Pong game in x86 Assembler

![Screenshot](https://github.com/James-P-D/Pong/blob/main/screenshot.gif)

## Introduction

[Pong](https://en.wikipedia.org/wiki/Pong) is a simple 2-player game whereby each person controls a small paddle which can be used to bounce a ball around the screen. Each time a player successfully returns the ball, the speed of the game increases slightly. If a player fails to return the ball, they lose and the game is reset.

## Building

This program was built with [MASM32](https://www.masm32.com/). It should be possible to compile it with the following:

```
c:\masm32\bin\ml.exe /c /coff pong.asm
c:\masm32\bin\polink.exe /SUBSYSTEM:console pong.obj
```

Once complete, simply run the `pong.exe` file.

Player 1 can move up and down using <kbd>Q</kbd> and <kbd>A</kbd>, whilst player 2 can use <kbd>P</kbd> and <kbd>L</kbd>. To exit the game, press <kbd>ESC</kbd>.