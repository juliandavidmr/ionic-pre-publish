#!/bin/bash

# ----------------------------------------------------------
# Creado por Julian David <https://github.com/juliandavidmr>
# Año 2018
# Licencia MIT
# Generada:
# - Certificados con keytool
# - Instalador apk para produccion
# - Procesa apk con jarsigner
# ----------------------------------------------------------

arg1="$1"

VERSION="0.0.2"
NAME_KEYSTORE="my-release-key.keystore"
ALIAS_NAME="alias_app"

function validate_apk {
    APK_RELEASED=$(find . -name '*release-unsigned.apk' | head -n 1)
    if [ $APK_RELEASED ]; then
        echo -e "  APK released encontrado en: \n\t'\e[1m$APK_RELEASED.\e[21m'"
    else
        echo "ERROR: APK released no encontrado, por favor cree uno y repita la operación actual."
        exit
    fi
}

function process_keytool {
    echo "[2/4] Procesando keytool"
    # APK released
    echo -e "- Buscando apk released..."
    
    validate_apk
    
    # Keystore
    if [ -e $NAME_KEYSTORE ]; then
        echo "- Se encontró '$NAME_KEYSTORE'. Será tomado para la compilacion de esta app."
    else
        echo -e "\n* Advertencia: El archivo '$NAME_KEYSTORE' NO existe. Se procederá a crearlo."
        local ARGUMENTS_KS="-genkey -v -keystore $NAME_KEYSTORE -alias $ALIAS_NAME -keyalg RSA -keysize 2048 -validity 10000"
        local KEYTOOL="\"$JAVA_HOME\bin\keytool.exe\" $ARGUMENTS_KS"
        eval $KEYTOOL
        
        if [ -e $NAME_KEYSTORE ]; then
            echo "- El archivo '$NAME_KEYSTORE' fue generado exitosamente."
        else
            echo "* ERROR: No se ha encontrado el archivo $NAME_KEYSTORE"
            exit
        fi
    fi
}

function process_jarsigned {
    echo "[3/4] Procesando jarsigned"
    validate_apk
    
    rm "$ALIAS_NAME.apk"
    
    local ARGUMENTS_JS="-verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore $NAME_KEYSTORE $APK_RELEASED $ALIAS_NAME"
    local JARSIGNED="\"$JAVA_HOME\bin\jarsigner.exe\" $ARGUMENTS_JS"
    # echo "$JARSIGNED"
    eval $JARSIGNED
}

function process_zipalign {
    echo "[4/4] Procesando zipalign"
    validate_apk
    local ARGUMENTS="-v 4 $APK_RELEASED $ALIAS_NAME.apk"
    if [ ! $ANDROID_HOME ]; then
        echo "* Advertencia: Variable de entorno ANDROID_HOME no está configurada. Se intentará crear una temporalmente."
        local search_into="$HOME\AppData\Local\Android\sdk\build-tools"
        ZIPA=$(find $search_into -name 'zipalign.exe' | head -n 1)
        echo "- Zipalign encontrado"
        ZIPA="\"$ZIPA\" $ARGUMENTS"
    else
        echo "- Variable de entorno ANDROID_HOME encontrada."
        ZIPA="\"$ANDROID_HOME\build-tools\VERSION\zipalign.exe\" $ARGUMENTS"
    fi
    # echo "$ZIPA"
    sleep 0.8
    eval $ZIPA
}

function process_build {
    echo "[1/4] Generando proyecto"
    ionic cordova build android --prod --aot --release
}

# 1
if [ "$arg1" = "-g" ]; then
    process_build
fi

# 2
if [ "$arg1" = "-k" ]; then
    process_keytool
fi

# 3
if [ "$arg1" = "-j" ]; then
    process_jarsigned
fi

# 4
if [ "$arg1" = "-z" ]; then
    process_zipalign
fi

# 4
if [ "$arg1" = "-a" ]; then
    echo "| Proceso completo |"
    process_build
    process_keytool
    process_jarsigned
    process_zipalign
fi

# help
if [ "$arg1" = "-h" ]; then
    echo ""
    echo "Usa y crea certificados con keytool"
    echo "Genera instalador apk para producción"
    echo "Procesa apk con jarsigner"
    echo "Version $VERSION"
    echo "__________________________________________________"
    echo ""
    echo "Comando"
    echo "	./apk.sh [argumento]"
    echo "Argumentos"
    echo "	-g Generar proyecto. Versión release para android"
    echo "	-k Procesa el apk (released) con keytool"
    echo "	-j Procesa el apk (released) con jarsigned"
    echo "	-z Procesa el apk (released) con zipalign"
    echo "	-a Realiza todas operaciones ordenadamente"
    echo "	   Genera apk release"
    echo "	   Ejecuta keytool, jarsigned y zipalign"
    echo "	-h Muestra este menú"
    echo ""
    echo "Licencia MIT"
    echo "Julian David <https://github.com/juliandavidmr>"
fi