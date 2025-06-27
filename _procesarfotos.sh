#!/bin/bash


#Para que el script reconozca las camaras
pkill -f gvfs-gphoto2-volume-monitor


# Números de serie de las cámaras
#En Ubuntu para detectar las cámaras conectadas a la computadora
#gphoto2 --auto-detect
#Model                          Port                                            
#----------------------------------------------------------
#Canon EOS 700D                 usb:001,029    
#Canon EOS 700D                 usb:001,027
#
#gphoto2 --port usb:001,029 --get-config /main/status/serialnumber
#Label: Serial Number                                                          
#Readonly: 0
#Type: TEXT
#Current: XXXXXXXXXX1
#END
#
#

SERIAL_CAM1="XXXXXXXXXX1" #Cámara 1 cámara A Izquierda
SERIAL_CAM2="XXXXXXXXXX2" #Cámara 2 cámara B Derecha

# Obtener los puertos de las cámaras
echo "🕵️  Detectando cámaras..."
declare -A CAMERAS

for port in $(gphoto2 --auto-detect | awk '/usb:/ {print $NF}'); do
    SERIAL=$(gphoto2 --port $port --get-config /main/status/serialnumber 2>/dev/null | awk '/Current:/ {print $2}')

    if [[ "$SERIAL" == "$SERIAL_CAM1" ]]; then
        CAMERAS[$SERIAL_CAM1]=$port
    elif [[ "$SERIAL" == "$SERIAL_CAM2" ]]; then
        CAMERAS[$SERIAL_CAM2]=$port
    fi
done

# Verificar si se detectaron ambas cámaras
if [[ -z "${CAMERAS[$SERIAL_CAM1]}" && -z "${CAMERAS[$SERIAL_CAM2]}" ]]; then
    echo "❌ No se detectaron cámaras conectadas."
    exit 1
fi

# Función para verificar fotos en una cámara
verificar_fotos() {
    local serial=$1
    local port=${CAMERAS[$serial]}

    if [[ -n "$port" ]]; then
        echo "📷 Verificando fotos en la cámara con serial: $serial (Puerto: $port)"
        COUNT=$(gphoto2 --port $port --list-files 2>/dev/null | grep '#' | wc -l)

        if [[ "$COUNT" -gt 0 ]]; then
            echo "✅ La cámara tiene $COUNT fotos."
                #Si esta ok se pueden procesar las fotos
                paso1='ok'


        else
            echo "⚠️ La cámara no tiene fotos."
        fi
    else
        echo "⚠️ No se encontró la cámara con serial $serial."
        ambascamarasok='ko'
    fi
}

# Verificar fotos en ambas cámaras
verificar_fotos "$SERIAL_CAM1"
verificar_fotos "$SERIAL_CAM2"



#if [[ "$paso1" == "ok" ]]; then
if [[ "$ambascamarasok" != "ko" ]]; then
    echo "✅ Ambas cámaras detectadas, se procesan las fotos."



#Se descargas las fotos de las camaras



#Paso 1: Crear carpetas si no exiten para las camaras y descargas las fotos en esas carpetas

# Obtener la fecha y la hora en el formato YYYY-MM-DD_HHMM
timestamp=$(date +"%Y-%m-%d_%H%M")

# Nombre de la carpeta
folder_name=${timestamp}_fotos

# Crear la carpeta contenedora de las subcarpetas
mkdir -p $folder_name

mkdir -p $folder_name/camara1 $folder_name/camara2

# Obtener la lista de cámaras conectadas
CAM_LIST=$(gphoto2 --auto-detect | grep usb)

# Recorrer cada cámara conectada
while read -r LINE; do
    PORT=$(echo "$LINE" | awk '{print $NF}')  # Extraer el puerto USB
    SERIAL=$(gphoto2 --port "$PORT" --get-config /main/status/serialnumber | grep "Current:" | awk '{print $NF}')  # Obtener el número de serie




if [[ "$SERIAL" == "$SERIAL_CAM1" ]]; then
    echo "⬇️  Descargando fotos de Cámara 1 ($SERIAL) en $PORT..."
    gphoto2 --port "$PORT" --get-all-files --filename "$folder_name/camara1/%f" \
        | while read -r line; do
            if [[ "$line" == Saving* ]]; then
                echo "          📥 Descargando archivo como ${line#Saving file as }"
            fi
        done

elif [[ "$SERIAL" == "$SERIAL_CAM2" ]]; then
    echo "⬇️  Descargando fotos de Cámara 2 ($SERIAL) en $PORT..."
    gphoto2 --port "$PORT" --get-all-files --filename "$folder_name/camara2/%f" \
        | while read -r line; do
            if [[ "$line" == Saving* ]]; then
                echo "          📥 Descargando archivo como ${line#Saving file as }"
            fi
        done
else
    echo "❌ Cámara con número de serie desconocido: $SERIAL en $PORT"
fi


done <<< "$CAM_LIST"

echo "✅ Descarga completada."

# Parte 2: Renobrar las fotos



# Ruta de la carpeta camara1
folder_camara1=$folder_name/camara1

# Verificar si la carpeta existe
if [ -d "$folder_camara1" ]; then



    # Renombrar los archivos secuencialmente desde el 0001
  # Obtener todos los archivos que comienzan con "IMG_", ordenados numéricamente
    files=($(ls "$folder_camara1"/IMG_* 2>/dev/null | sort -V))


    # Contador para la numeración secuencial
    count=1


    # Recorrer todos los archivos que empiezan con "IMG_"
    for file in "$folder_camara1"/IMG_*; do
        # Verificar que el archivo existe (por si no hay archivos que coincidan)
        [ -e "$file" ] || continue

        # Obtener el nombre sin la ruta y sin el prefijo "IMG_"
        filename=$(basename "$file" )  # Ejemplo: IMG_0030 → IMG_0030
# original        newname="${filename#IMG_}_a"   # Quita "IMG_" y añade "_a"

        # Generar el nuevo nombre con número secuencial de 4 dígitos


        newname=$(printf "%04d_a.jpg" "$count")

        # Renombrar el archivo
        mv "$file" "$folder_camara1/$newname"


        #Girar la imagen a la izquierda (90° CCW)
        mogrify -rotate -90 "$folder_camara1/$newname"


        # Mensaje de confirmación
        echo "          ✍️  Renombrado: $file → $folder_camara1/$newname"

        # Incrementar el contador
                ((count++))

    done
else
    echo "❌ La carpeta $folder_camara1 no existe."
fi


#FIN renombrar camara 1


#INICIO renombrar camara 2 = derecha / _b

# Ruta de la carpeta camara2
folder_camara2=$folder_name/camara2

# Verificar si la carpeta existe
if [ -d "$folder_camara2" ]; then


   # Renombrar los archivos secuencialmente desde el 0001

  # Obtener todos los archivos que comienzan con "IMG_", ordenados numéricamente
    files=($(ls "$folder_camara2"/IMG_* 2>/dev/null | sort -V))

    # Contador para la numeración secuencial
    count=1


    # Recorrer todos los archivos que empiezan con "IMG_"
    for file in "$folder_camara2"/IMG_*; do
        # Verificar que el archivo existe (por si no hay archivos que coincidan)
        [ -e "$file" ] || continue

        # Obtener el nombre sin la ruta y sin el prefijo "IMG_"

        filename=$(basename "$file" )  # Ejemplo: IMG_0030 → IMG_0030
#original        newname="${filename#IMG_}_b"   # Quita "IMG_" y añade "_a"

        # Generar el nuevo nombre con número secuencial de 4 dígitos
        newname=$(printf "%04d_b.jpg" "$count")

        # Renombrar el archivo
        mv "$file" "$folder_camara2/$newname"


        #Girar la imagen a la derecha (90° CCW)
        mogrify -rotate 90 "$folder_camara2/$newname"


        # Mensaje de confirmación
        echo "          ✍️  Renombrado: $file → $folder_camara2/$newname"

        # Incrementar el contador
                ((count++))
    done
else
    echo "❌ La carpeta $folder_camara2 no existe."
fi


# Paso 2: Mover los archivos renombrados a la carpeta destino "datos/nombrefotos"


# Crear la carpeta de destino si no existe
destination=$folder_name
#mkdir -p "$destination"

# Mover los archivos de camara1
if [ -d "$folder_camara1" ]; then
    mv "$folder_camara1"/* "$destination/"
    echo "          🚂 Archivos de camara1 movidos a $destination"
fi

# Mover los archivos de camara2
if [ -d "$folder_camara2" ]; then
    mv "$folder_camara2"/* "$destination/"
    echo "          🚂 Archivos de camara2 movidos a $destination"
fi

echo "✅ Proceso completo: Archivos renombrados y movidos."


# >  eliminar las carpetas de las fotos

# Eliminar las carpetas "camara1" y "camara2"
if [ -d "$folder_camara1" ]; then
    rm -rf "$folder_camara1"
    echo "          💨 Carpeta $folder_camara1 eliminada."
fi

if [ -d "$folder_camara2" ]; then
    rm -rf "$folder_camara2"
    echo "          💨 Carpeta $folder_camara2 eliminada."
fi

echo "✅ Proceso completo: Archivos renombrados, movidos y carpetas eliminadas."




#Paso 3: elimnar las fotos de las camaras

# Si no hay cámaras, salir del script
if [[ -z "$CAM_LIST" ]]; then
    echo "❌ No se detectaron cámaras conectadas. Conéctalas e inténtalo de nuevo."
    exit 1
fi

# Mostrar mensaje de advertencia antes de eliminar
echo "⚠️  ADVERTENCIA: Este script eliminará todas las imágenes de las cámaras Canon EOS 700D conectadas."
read -p "               👉 Presiona Enter para eliminar las fotos o Ctrl+C para cancelar..."

# Recorrer cada cámara conectada y eliminar sus fotos
while read -r LINE; do
    PORT=$(echo "$LINE" | awk '{print $NF}')  # Extraer el puerto USB
    SERIAL=$(gphoto2 --port "$PORT" --get-config /main/status/serialnumber | grep "Current:" | awk '{print $NF}')  # Obtener el número de serie

    if [[ "$SERIAL" == "$SERIAL_CAM1" || "$SERIAL" == "$SERIAL_CAM2" ]]; then
        echo "          🗑️  Eliminando fotos de la Cámara ($SERIAL) en $PORT..."

        # Intentar eliminar todas las fotos
        gphoto2 --port "$PORT" --delete-all-files

        # Verificar si aún quedan fotos
        REMAINING=$(gphoto2 --port "$PORT" --list-files 2>/dev/null | wc -l)
        if [[ "$REMAINING" -gt 0 ]]; then
#            echo "❌❌ No se pudieron eliminar todas las fotos. Intentando de nuevo..."
            gphoto2 --port "$PORT" --delete-all-files --recurse
        fi

        echo "          🗑️  Fotos eliminadas de la Cámara ($SERIAL)."
    else
        echo "❌ Cámara desconocida detectada: $SERIAL en $PORT. No se eliminarán fotos."
    fi

done <<< "$CAM_LIST"

echo "🚀 Eliminación de fotos completada en las cámaras detectadas."

# Abrir la carpeta donde se guardaron las fotos
xdg-open "$folder_name"


#Se descargan las fotos de las camaras fin


else
        echo "❌❌ Una o dos camaras no detectadas. Ejecute el comando: pkill -f gvfs-gphoto2-volume-monitor apague el HUB USB de cada camara, vuelva a conectar las camaras en el HUB y repita el proceso."
fi
