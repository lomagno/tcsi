QT -= core gui
TEMPLATE = lib
CONFIG -= qt
CONFIG += plugin
CONFIG += no_plugin_name_prefix # avoid the "lib" prefix
QMAKE_EXTENSION_SHLIB = plugin

# Unix
unix:!macx {
    TARGET = tcsi_linux
    DEFINES += "SYSTEM=OPUNIX"
    LIBS += -lglpk
}

# Mac
unix:macx {
    TARGET = tcsi_mac
    DEFINES += "SYSTEM=APPLEMAC"
    LIBS += -lglpk
}

# Windows
win32 {
    TARGET = tcsi_windows
    LIBS += -l:libglpk.a
    QMAKE_LFLAGS += -static-libgcc
    QMAKE_LFLAGS += -static-libstdc++
}

CONFIG(debug, debug|release) {
    DEFINES += STATA_PLUGIN_DEBUG
    TEMPLATE -= lib
    TEMPLATE += app
    CONFIG -= shared
    CONFIG += console
}

HEADERS += \
    stplugin.h \
    statapluginutils.h

SOURCES += \
    stplugin.c \
    main.cpp \
    statapluginutils.cpp
