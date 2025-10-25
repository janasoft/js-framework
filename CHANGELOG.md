# Changelog - JS-Framework

Todos los cambios notables en este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/lang/es/).

## [Unreleased]

### Planificado
- Mapeo directo DB ↔ Entity (sin overhead JSON)
- Sistema de repositorios base
- Soporte para SQLite
- Soporte para Firebird
- Soporte para PostgreSQL

## [0.1.0-alpha] - 2025-10-25

### Añadido
- Implementación inicial de `TEntity` como clase base
- Sistema de estados: `TEntityState` (esNew, esUnchanged, esModified, esDeleted)
- Sistema de metadata: `TEntityMetadata` (CreatedAt, ModifiedAt, CreatedBy, ModifiedBy, Version)
- Sistema de validación: `TValidationMessage` y `TValidationMessages`
- Métodos `Validate`, `IsValid`, `MarkAsModified`, `MarkAsDeleted`
- `BeginLoad` / `EndLoad` para carga sin efectos secundarios
- Helpers de campo: `SetFieldString`, `SetFieldInteger`, `SetFieldBoolean`
- `TEntitySerializer`: Helper para serialización type-safe a JSON
- `TEntityDeserializer`: Helper para deserialización type-safe desde JSON
- Hooks virtuales `DoSerializeFields` / `DoDeserializeFields`
- Serialización JSON: `ToJSONString`, `FromJSONString`
- Implementación de ejemplo en `TCiudad`
- Tests unitarios con FPCUnit (separados por responsabilidad)
- Documentación completa (README, CONTRIBUTING, CHANGELOG)

### Decisiones de Diseño
- **Principios SOLID** aplicados estrictamente
- **SRP**: Separación de responsabilidades (Entity, Serializers, DataSources)
- **OCP**: Extensible vía hooks virtuales
- **DIP**: Dependencia de abstracciones (helpers), no implementaciones (fpjson)
- Version se incrementa en el repositorio (no en la entidad)
- BeginLoad/EndLoad usa contador para soportar anidamiento
- Metadata se actualiza explícitamente vía métodos dedicados
- Serialización opcional (no afecta acceso a BD tradicional)

---

## Categorías de Cambios

- `Añadido` para nuevas funcionalidades
- `Cambiado` para cambios en funcionalidad existente
- `Deprecado` para funcionalidades que serán eliminadas
- `Eliminado` para funcionalidades eliminadas
- `Corregido` para corrección de bugs
- `Seguridad` para vulnerabilidades corregidas
- `Mejorado` para mejoras de rendimiento o calidad
