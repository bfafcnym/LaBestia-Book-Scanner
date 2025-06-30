#!/bin/bash

#Biblioteca Florentino Ameghino www.bfa.fcnym.unlp.edu.ar
#https://github.com/bfafcnym

#Software requerido:
#sudo apt update
#sudo apt install imagemagick img2pdf ocrmypdf tesseract-ocr tesseract-ocr-spa tesseract-ocr-eng tesseract-ocr-fra tesseract-ocr-por tesseract-ocr-deu xdg-utils
#chmod +x _crearpdf.sh

#Uso
#./_crearpdf.sh "</directorio/con/fotos>" "<nombre del pdf>"
#./_crearpdf.sh "/home/maquina-01/Imágenes/labestia/2025-05-08_1056_fotos" "RMLP 1(21) 1999"
#No se debe escribir la extensión pdf, se genera automáticamente
#El script toma el valor de  <nombre del pdf> y renombra la carpeta de las fotos y genera el pdf con  <nombre del pdf>.pdf

# Verifica si se proporcionó el nombre del PDF
if [ -z "$1" ]; then
  echo '❌ Error: Debes proporcionar la ruta al directorio donde están las fotos. Tiene que tener la ruta exacta a la carpeta donde están las fotos entre comillas'
  echo 'Uso: ./_crearpdf.sh "/directorio/con/fotos" "nombre del pdf"; ./_crearpdf.sh "/home/maquina-01/Imágenes/labestia/2025-05-08_1056_fotos" "RMLP 1(21) 1999"'
  exit 1
fi

# Verifica si se proporcionó el nombre del PDF
if [ -z "$2" ]; then
  echo '❌ Error: Debes proporcionar un nombre para el archivo PDF. Tiene que estar entre comillas y puede tener espacios en blanco'
  echo 'Uso: ./_crearpdf.sh "/directorio/con/fotos" "nombre del pdf"; ./_crearpdf.sh "/home/maquina-01/Imágenes/labestia/2025-05-08_1056_fotos" "RMLP 1(21) 1999"'
  exit 1
fi

# Asignar argumentos a variables
Directorio="$1"
NombrePdf="$2"

# Verifica que el directorio exista
if [ ! -d "$Directorio" ]; then
  echo "❌ Error: El directorio \"$Directorio\" no existe."
  exit 1
fi

# Cambia temporalmente al directorio con las fotos
cd "$Directorio" || exit

# Crear carpeta temporal para imágenes procesadas
output_folder="$Directorio/procesadas"
mkdir -p "$output_folder"

echo "🔧 Procesando imágenes..."

# Procesar todas las imágenes JPG
for img in *.jpg; do
  [ -e "$img" ] || continue
  echo "Procesando $img..."
  convert "$img" -density 600 -sharpen 1x1.5 "$output_folder/$img"
done

echo "✅ Procesamiento de imágenes completado."

# Crear el PDF desde las imágenes procesadas, ordenadas
img2pdf $(ls -v "$output_folder"/*.jpg) -o "$NombrePdf.pdf"

# Aplica OCR al mismo archivo
ocrmypdf -l spa+eng+fra+por+deu --force-ocr --output-type pdf "$NombrePdf.pdf" "$NombrePdf.pdf"

echo "🗑️ Eliminando archivos temporales..."
rm -r "$output_folder"

echo "✅ PDF generado y OCR aplicado exitosamente."



#Cambio de nombre del directorio con las fotos descargadas desde las camaras

        # 🔁 Renombrar el directorio después de generar el PDF
        echo "🔄 Cambiando el nombre de la carpeta..."

        # Guardar ruta y nombre actual
        RutaActual=$(pwd)
        NombreCarpeta=$(basename "$RutaActual")
        RutaPadre=$(dirname "$RutaActual")

        cd "$RutaPadre" || exit
        mv "$NombreCarpeta" "$NombrePdf"

        # Cambiar al nuevo nombre de carpeta
        cd "$NombrePdf" || exit

        echo "📂 Carpeta renombrada exitosamente."




# Abre el PDF automáticamente
xdg-open "$NombrePdf.pdf"
