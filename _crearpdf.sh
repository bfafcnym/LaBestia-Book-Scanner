#!/bin/bash

# Biblioteca Florentino Ameghino – www.bfa.fcnym.unlp.edu.ar
# https://github.com/bfafcnym
#
# Creador de PDF con OCR a partir de imágenes JPG
# Versión mejorada: orden seguro y manejo robusto de nombres con espacios.
#
# Software requerido:
# sudo apt update
# sudo apt install imagemagick img2pdf ocrmypdf tesseract-ocr \
#   tesseract-ocr-spa tesseract-ocr-eng tesseract-ocr-fra \
#   tesseract-ocr-por tesseract-ocr-deu xdg-utils
#
# Uso:
# ./_crearpdf.sh "/ruta/al/directorio" "Nombre del PDF"
# Ejemplo:
# ./_crearpdf.sh "/home/maquina-01/Imágenes/labestia/2025-05-08_1056_fotos" "RMLP 1(21) 1999"
#
# El script renombra la carpeta de las fotos con el nombre del PDF y genera <nombre>.pdf
# No incluir la extensión .pdf al invocar el script.


# ───────────────────────────────────────────────────────────────
# ✅ Verificación de argumentos
# ───────────────────────────────────────────────────────────────

if [ -z "$1" ]; then
  echo '❌ Error: Debes proporcionar la ruta al directorio donde están las fotos.'
  echo 'Uso: ./_crearpdf.sh "/directorio/con/fotos" "nombre del pdf"'
  exit 1
fi

if [ -z "$2" ]; then
  echo '❌ Error: Debes proporcionar un nombre para el archivo PDF (entre comillas si tiene espacios).'
  echo 'Uso: ./_crearpdf.sh "/directorio/con/fotos" "nombre del pdf"'
  exit 1
fi

Directorio="$1"
NombrePdf="$2"

# ───────────────────────────────────────────────────────────────
# 🗂️ Verifica existencia del directorio
# ───────────────────────────────────────────────────────────────
if [ ! -d "$Directorio" ]; then
  echo "❌ Error: El directorio \"$Directorio\" no existe."
  exit 1
fi

# ───────────────────────────────────────────────────────────────
# 🧰 Preparación de carpetas
# ───────────────────────────────────────────────────────────────
cd "$Directorio" || exit 1
output_folder="$Directorio/procesadas"
mkdir -p "$output_folder"

echo "🔧 Procesando imágenes JPG en: $Directorio"
echo

# ───────────────────────────────────────────────────────────────
# 🖼️ Procesamiento de imágenes (ajuste de densidad y nitidez)
# ───────────────────────────────────────────────────────────────
shopt -s nullglob
jpg_files=(*.jpg *.JPG)

if [ ${#jpg_files[@]} -eq 0 ]; then
  echo "⚠️ No se encontraron archivos JPG en el directorio."
  exit 1
fi

# 🔁 Procesar en orden natural (0038_a < 0038_ab < 0038_abc)
for img in $(ls -1 | grep -E '\.jpe?g$' | sort -V); do
  echo "   → Procesando: $img"
  convert "$img" -density 600 -sharpen 1x1.5 "$output_folder/$img"
done

echo
echo "✅ Procesamiento completado."
echo

# ───────────────────────────────────────────────────────────────
# 📄 Creación del PDF ordenado
# ───────────────────────────────────────────────────────────────
echo "📄 Creando PDF ordenado: $NombrePdf.pdf"

# Ordena naturalmente (a < aa < ab < abc < abcd)
find "$output_folder" -maxdepth 1 -type f -iname '*.jpg' | sort -V | while IFS= read -r file; do
  printf '%s\0' "$file"
done | xargs -0 img2pdf -o "$NombrePdf.pdf"

if [ ! -f "$NombrePdf.pdf" ]; then
  echo "❌ Error: no se pudo generar el PDF."
  exit 1
fi

echo "✅ PDF creado exitosamente."
echo

# ───────────────────────────────────────────────────────────────
# 🧠 Aplicar OCR al PDF
# ───────────────────────────────────────────────────────────────
echo "🔍 Aplicando OCR (spa+eng+fra+por+deu)..."
ocrmypdf -l spa+eng+fra+por+deu --force-ocr --output-type pdf "$NombrePdf.pdf" "$NombrePdf.pdf"

if [ $? -eq 0 ]; then
  echo "✅ OCR aplicado correctamente."
else
  echo "⚠️ Hubo un problema al aplicar OCR, el PDF sin OCR sigue disponible."
fi
echo

# ───────────────────────────────────────────────────────────────
# 🧹 Limpieza
# ───────────────────────────────────────────────────────────────
echo "🗑️ Eliminando archivos temporales..."
rm -rf "$output_folder"
echo "✅ Limpieza completada."
echo

# ───────────────────────────────────────────────────────────────
# 📁 Renombrar carpeta original
# ───────────────────────────────────────────────────────────────
echo "🔄 Renombrando carpeta original..."
RutaActual=$(pwd)
NombreCarpeta=$(basename "$RutaActual")
RutaPadre=$(dirname "$RutaActual")

cd "$RutaPadre" || exit 1
mv "$NombreCarpeta" "$NombrePdf"

cd "$NombrePdf" || exit 1
echo "📂 Carpeta renombrada exitosamente a: $NombrePdf"
echo

# ───────────────────────────────────────────────────────────────
# 📖 Abrir PDF automáticamente
# ───────────────────────────────────────────────────────────────
echo "📘 Abriendo PDF..."
xdg-open "$NombrePdf.pdf" >/dev/null 2>&1 &
echo "✅ Proceso finalizado con éxito."

