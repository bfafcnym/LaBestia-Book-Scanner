#!/bin/bash

# Biblioteca Florentino Ameghino – www.bfa.fcnym.unlp.edu.ar
# https://github.com/bfafcnym
#
# Creador de PDF con OCR a partir de imágenes
# Soporta: JPG / JPEG / PNG / TIFF / TIF / WEBP / BMP
#
# Software requerido:
# sudo apt update
# sudo apt install imagemagick img2pdf ocrmypdf tesseract-ocr \
#   tesseract-ocr-spa tesseract-ocr-eng tesseract-ocr-fra \
#   tesseract-ocr-por tesseract-ocr-deu xdg-utils
#
# Convertir en ejecutable
# chmod +x _crearpdf.sh
# Uso:
# ./_crearpdf.sh "/ruta/al/directorio" "Nombre del PDF"
#
# No incluir la extensión .pdf


# ───────────────────────────────────────────────────────────────
# ✅ Verificación de argumentos
# ───────────────────────────────────────────────────────────────

if [ -z "$1" ]; then
  echo '❌ Error: Debes proporcionar la ruta al directorio donde están las imágenes.'
  echo 'Uso: ./_crearpdf.sh "/directorio/con/imagenes" "nombre del pdf"'
  exit 1
fi

if [ -z "$2" ]; then
  echo '❌ Error: Debes proporcionar un nombre para el archivo PDF.'
  echo 'Uso: ./_crearpdf.sh "/directorio/con/imagenes" "nombre del pdf"'
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
# 🧰 Preparación
# ───────────────────────────────────────────────────────────────

cd "$Directorio" || exit 1
output_folder="$Directorio/procesadas"
mkdir -p "$output_folder"

echo "🔍 Buscando imágenes compatibles..."
echo

# ───────────────────────────────────────────────────────────────
# 🖼️ Detección de imágenes soportadas
# ───────────────────────────────────────────────────────────────

mapfile -t imagenes < <(
  find . -maxdepth 1 -type f \( \
    -iname '*.jpg'  -o -iname '*.jpeg' \
    -o -iname '*.png' \
    -o -iname '*.tif'  -o -iname '*.tiff' \
    -o -iname '*.webp' \
    -o -iname '*.bmp' \
  \) | sort -V
)

if [ ${#imagenes[@]} -eq 0 ]; then
  echo "⚠️ No se encontraron archivos de imagen compatibles."
  exit 1
fi

echo "🧠 Procesando ${#imagenes[@]} imágenes..."
echo

# ───────────────────────────────────────────────────────────────
# 🖼️ Procesamiento y normalización
# ───────────────────────────────────────────────────────────────

for img in "${imagenes[@]}"; do
  echo "   → Procesando: $img"

  base=$(basename "$img")
  nombre="${base%.*}"

  convert "$img" \
    -density 600 \
    -auto-level \
    -unsharp 0x1 \
    "$output_folder/$nombre.jpg"
done

echo
echo "✅ Procesamiento de imágenes completado."
echo

# ───────────────────────────────────────────────────────────────
# 📄 Creación del PDF
# ───────────────────────────────────────────────────────────────

echo "📄 Creando PDF: $NombrePdf.pdf"

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
# 🧠 Aplicar OCR
# ───────────────────────────────────────────────────────────────

echo "🔍 Aplicando OCR (spa+eng+fra+por+deu)..."
ocrmypdf -l spa+eng+fra+por+deu --force-ocr --output-type pdf \
  "$NombrePdf.pdf" "$NombrePdf.pdf"

if [ $? -eq 0 ]; then
  echo "✅ OCR aplicado correctamente."
else
  echo "⚠️ Hubo un problema al aplicar OCR."
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
echo "📂 Carpeta renombrada a: $NombrePdf"
echo

# ───────────────────────────────────────────────────────────────
# 📖 Abrir PDF
# ───────────────────────────────────────────────────────────────

echo "📘 Abriendo PDF..."
xdg-open "$NombrePdf.pdf" >/dev/null 2>&1 &

echo "✅ Proceso finalizado con éxito."
