# Script para inicializar el repositorio Git y hacer el primer commit
# Ejecutar desde la raíz del proyecto: .\init-repo.ps1

Write-Host "=== Inicializando repositorio JS-Framework ===" -ForegroundColor Cyan

# Verificar si git está instalado
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Git no está instalado o no está en el PATH" -ForegroundColor Red
    exit 1
}

# Verificar si ya es un repositorio git
if (Test-Path ".git") {
    Write-Host "AVISO: Ya existe un repositorio git en este directorio" -ForegroundColor Yellow
    $response = Read-Host "¿Deseas continuar de todas formas? (s/N)"
    if ($response -ne "s" -and $response -ne "S") {
        Write-Host "Operación cancelada" -ForegroundColor Yellow
        exit 0
    }
} else {
    # Inicializar repositorio
    Write-Host "`n1. Inicializando repositorio..." -ForegroundColor Green
    git init
    git branch -M main
}

# Crear rama develop
Write-Host "`n2. Creando rama develop..." -ForegroundColor Green
git checkout -b develop 2>$null
if ($LASTEXITCODE -ne 0) {
    git checkout develop
}

# Añadir archivos
Write-Host "`n3. Añadiendo archivos al staging..." -ForegroundColor Green
git add .

# Mostrar estado
Write-Host "`n4. Estado del repositorio:" -ForegroundColor Green
git status --short

# Hacer primer commit
Write-Host "`n5. Creando commit inicial..." -ForegroundColor Green
git commit -m "feat: versión inicial del framework (v0.1.0-alpha)

Implementación inicial del framework con:
- Sistema base de entidades (TEntity)
- Control de estado y metadata
- Serialización JSON desacoplada
- Helpers TEntitySerializer/TEntityDeserializer
- Tests unitarios con FPCUnit
- Documentación completa (README, CONTRIBUTING, CHANGELOG)

Principios SOLID aplicados:
- SRP: Separación de responsabilidades
- OCP: Extensible vía hooks virtuales
- DIP: Dependencia de abstracciones

Esta es la primera versión alpha del proyecto."

# Crear tag
Write-Host "`n6. Creando tag v0.1.0-alpha..." -ForegroundColor Green
git tag -a v0.1.0-alpha -m "Versión 0.1.0-alpha - Primera versión pública"

# Instrucciones finales
Write-Host "`n=== Repositorio inicializado correctamente ===" -ForegroundColor Cyan
Write-Host "`nPróximos pasos:" -ForegroundColor Yellow
Write-Host "1. Crea un repositorio en GitHub"
Write-Host "2. Ejecuta los siguientes comandos:`n"
Write-Host "   git remote add origin https://github.com/TU_USUARIO/js-framework.git" -ForegroundColor White
Write-Host "   git push -u origin main" -ForegroundColor White
Write-Host "   git push -u origin develop" -ForegroundColor White
Write-Host "   git push --tags" -ForegroundColor White
Write-Host "`n3. Configura las ramas en GitHub:"
Write-Host "   - Rama por defecto: develop (desarrollo activo)"
Write-Host "   - Rama main: solo releases estables"
Write-Host "`nRepositorio listo para publicar! 🚀" -ForegroundColor Green
